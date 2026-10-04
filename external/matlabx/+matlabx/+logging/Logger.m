% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2026 William Dean
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation; either version 2 of the License, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, see <https://www.gnu.org/licenses/>.

classdef Logger < handle
%LOGGER Simple structured logger with optional sinks (Command Window, UI, file).
%
%   L = Logger();
%   L.info("Calibration started", "Source","UICalibration");
%   L.warn("Something looks off", "Tag","ui");
%   L.error("Failed to load file", "Data",struct("file",fn));
%
% Features
% --------
% - In-memory structured entries (datetime, level, message, etc.)
% - Ring buffer (keeps last N entries) OR keep-all mode
% - Optional sinks:
%     * Command Window (fprintf)
%     * UI sink (function handle, e.g., append to uitextarea)
%     * File sink (append lines)
% - Throttled UI/file flushing to avoid lag while spamming messages

    properties
        % Memory behavior
        KeepAll (1,1) logical = false
        MaxEntries (1,1) double {mustBePositive, mustBeInteger} = 5000

        % Output formatting
        TimestampFormat (1,:) char = 'yyyy-MM-dd HH:mm:ss.SSS'
        IncludeLevel (1,1) logical = true
        IncludeSource (1,1) logical = true
        IncludeTag (1,1) logical = false
        AutoDetectSource (1,1) logical = true
        SourceDetail (1,1) string {mustBeMember(SourceDetail,["short","full"])} = "short"

        % Logging policy. Sink-specific values inherit Level/Detail when empty.
        Level (1,1) string = "INFO"
        Detail (1,1) string = "normal"
        CommandWindowLevel (1,1) string = ""
        CommandWindowDetail (1,1) string = ""
        UILevel (1,1) string = ""
        UIDetail (1,1) string = ""
        FileLevel (1,1) string = ""
        FileDetail (1,1) string = ""

        % Sinks toggles
        PrintToCommandWindow (1,1) logical = true
        EnableUISink (1,1) logical = false
        EnableFileSink (1,1) logical = false

        % Throttling / batching
        FlushEveryN (1,1) double {mustBePositive, mustBeInteger} = 1
        FlushMinIntervalSec (1,1) double {mustBeNonnegative} = 0.05
    end

    properties (SetAccess=private)
        % Struct array of entries
        Entries struct = struct( ...
            't', datetime.empty(0,1), ...
            'level', strings(0,1), ...
            'msg', strings(0,1), ...
            'source', strings(0,1), ...
            'tag', strings(0,1), ...
            'data', cell(0,1))


        % Stats
        TotalCount (1,1) double = 0
        StartTime (1,1) datetime = datetime('now')
    end

    properties (Access=private)
        UISinkFcn (1,1) function_handle = @(lines) []
        FilePath (1,:) char = ''
        FileFID (1,1) double = -1

        PendingUILines (:,1) string = ""   % batched UI lines waiting to flush
        PendingFileLines (:,1) string = "" % batched file lines waiting to flush

        PendingUICount (1,1) double = 0
        PendingFileCount (1,1) double = 0
        LastFlushTic (1,1) uint64 = uint64(0)
    end

    methods
        function self = Logger(opts)
            arguments
                opts.KeepAll (1,1) logical = false
                opts.MaxEntries (1,1) double {mustBePositive, mustBeInteger} = 5000
                opts.PrintToCommandWindow (1,1) logical = true
                opts.FlushEveryN (1,1) double {mustBePositive, mustBeInteger} = 1
                opts.FlushMinIntervalSec (1,1) double {mustBeNonnegative} = 0.05
                opts.AutoDetectSource (1,1) logical = true
                opts.SourceDetail (1,1) string {mustBeMember(opts.SourceDetail,["short","full"])} = "short"
                opts.Level = "INFO"
                opts.Detail = "normal"
                opts.CommandWindowLevel = ""
                opts.CommandWindowDetail = ""
                opts.UILevel = ""
                opts.UIDetail = ""
                opts.FileLevel = ""
                opts.FileDetail = ""
            end

            self.KeepAll = opts.KeepAll;
            self.MaxEntries = opts.MaxEntries;
            self.PrintToCommandWindow = opts.PrintToCommandWindow;
            self.FlushEveryN = opts.FlushEveryN;
            self.FlushMinIntervalSec = opts.FlushMinIntervalSec;
            self.AutoDetectSource = opts.AutoDetectSource;
            self.SourceDetail = opts.SourceDetail;
            self.Level = opts.Level;
            self.Detail = opts.Detail;
            self.CommandWindowLevel = opts.CommandWindowLevel;
            self.CommandWindowDetail = opts.CommandWindowDetail;
            self.UILevel = opts.UILevel;
            self.UIDetail = opts.UIDetail;
            self.FileLevel = opts.FileLevel;
            self.FileDetail = opts.FileDetail;

            self.StartTime = datetime('now');
            self.LastFlushTic = tic;
        end

        function delete(self)
            % Ensure file is closed
            self.closeFile();
        end

        % ---- Convenience levels ----
        function info(self, msg, varargin),  self.log("INFO",  msg, varargin{:}); end
        function debug(self, msg, varargin), self.log("DEBUG", msg, varargin{:}); end
        function warn(self, msg, varargin),  self.log("WARN",  msg, varargin{:}); end
        function error(self, msg, varargin), self.log("ERROR", msg, varargin{:}); end

        % ---- Policy configuration ----
        function configure(self, config)
        %CONFIGURE Apply a matlabx.config.Logging policy.
            arguments
                self (1,1) matlabx.logging.Logger
                config = []
            end

            if isempty(config)
                return
            end

            if isa(config, 'matlabx.config.Logging')
                self.applyConfig_(config);
            else
                error('matlabx:logging:Logger:InvalidConfig', ...
                    'Logger.configure expects a matlabx.config.Logging object.');
            end
        end

        % ---- Main log entry point ----
        function log(self, level, msg, opts)
            arguments
                self (1,1) matlabx.logging.Logger
                level (1,1) string
                msg             % string, char, MException
                opts.Source (1,1) string = ""
                opts.Tag (1,1) string = ""
                opts.Data = []
                opts.Timestamp datetime = datetime('now')
                opts.AlsoPrint (1,1) logical = false  % force print even if PrintToCommandWindow=false
            end

            level = matlabx.logging.Logger.normalizeLevel(level);

            % --- normalize msg to string ---
            if isa(msg,'MException')
                ME = msg;
                msg = string(ME.message);
            
                % if isempty(opts.Source)
                %     opts.Source = string(ME.stack(1).name);
                % end

                if strlength(opts.Source) == 0 && ~isempty(ME.stack)
                    opts.Source = matlabx.logging.formatCallerName( ...
                        ME.stack(1).name, Detail=self.SourceDetail);
                end

                if isempty(opts.Data)
                    opts.Data = struct( ...
                        "identifier", ME.identifier, ...
                        "stack", ME.stack);
                end
            elseif isa(msg,'char')
                msg = string(msg);
            end

            if ~isa(msg,'string')
                error('Logger:incorrectType','msg must be a string, char, or MException, not a %s',class(msg))
            end

            % --- auto-detect Source if not provided ---
            if self.AutoDetectSource && strlength(opts.Source) == 0
                opts.Source = self.detectSource_();
            end

            e = struct( ...
                't', opts.Timestamp, ...
                'level', level, ...
                'msg', msg, ...
                'source', opts.Source, ...
                'tag', opts.Tag, ...
                'data', {opts.Data} );

            self.appendEntry_(e);

            % Immediate command window output (optionally)
            if opts.AlsoPrint || (self.PrintToCommandWindow && self.shouldEmit_("CommandWindow", e.level))
                line = self.formatEntry_(e, self.effectiveDetail_("CommandWindow"));
                % Use fprintf to preserve formatting and avoid string display quirks
                fprintf('%s\n', line);
            end

            % Batch for UI/file sinks
            queued = false;
            if self.EnableUISink && self.shouldEmit_("UI", e.level)
                self.queueUILine_(self.formatEntry_(e, self.effectiveDetail_("UI")));
                queued = true;
            end

            if self.EnableFileSink && self.shouldEmit_("File", e.level)
                self.queueFileLine_(self.formatEntry_(e, self.effectiveDetail_("File")));
                queued = true;
            end

            if queued
                self.maybeFlush_();
            end
        end

        function set.Level(self, value), self.Level = matlabx.logging.Logger.normalizeLevel(value); end
        function set.Detail(self, value), self.Detail = matlabx.logging.Logger.normalizeDetail(value); end
        function set.CommandWindowLevel(self, value), self.CommandWindowLevel = matlabx.logging.Logger.normalizeOptionalLevel(value); end
        function set.UILevel(self, value), self.UILevel = matlabx.logging.Logger.normalizeOptionalLevel(value); end
        function set.FileLevel(self, value), self.FileLevel = matlabx.logging.Logger.normalizeOptionalLevel(value); end
        function set.CommandWindowDetail(self, value), self.CommandWindowDetail = matlabx.logging.Logger.normalizeOptionalDetail(value); end
        function set.UIDetail(self, value), self.UIDetail = matlabx.logging.Logger.normalizeOptionalDetail(value); end
        function set.FileDetail(self, value), self.FileDetail = matlabx.logging.Logger.normalizeOptionalDetail(value); end

        % ---- Sinks configuration ----
        function setUISink(self, fcn, enable)
            arguments
                self (1,1) matlabx.logging.Logger
                fcn (1,1) function_handle
                enable (1,1) logical = true
            end
            self.UISinkFcn = fcn;
            self.EnableUISink = enable;
        end

        function setFileSink(self, filePath, enable)
            arguments
                self (1,1) matlabx.logging.Logger
                filePath (1,:) char
                enable (1,1) logical = true
            end
            self.openFile_(filePath);
            self.EnableFileSink = enable;
        end

        function closeFile(self)
            if self.FileFID > 0
                try fclose(self.FileFID); catch, end
            end
            self.FileFID = -1;
            self.FilePath = '';
            self.EnableFileSink = false;
        end

        % ---- Retrieval / export ----
        function T = asTable(self)
            %ASTABLE Convert log to a table (easy filtering/sorting).
            n = numel(self.Entries);
            if n == 0
                T = table( ...
                    datetime.empty(0,1), ...
                    strings(0,1), ...
                    strings(0,1), ...
                    strings(0,1), ...
                    strings(0,1), ...
                    cell(0,1), ...
                    'VariableNames', {'t','level','msg','source','tag','data'});
                return
            end

            t      = vertcat(self.Entries.t);
            level  = vertcat(self.Entries.level);
            msg    = vertcat(self.Entries.msg);
            source = vertcat(self.Entries.source);
            tag    = vertcat(self.Entries.tag);
            data   = {self.Entries.data}.';
            T = table(t, level, msg, source, tag, data, ...
                'VariableNames', {'t','level','msg','source','tag','data'});
        end

        function lines = exportText(self)
            %EXPORTTEXT Render all stored entries as lines.
            n = numel(self.Entries);
            lines = strings(n,1);
            for i = 1:n
                lines(i) = self.formatEntry_(self.Entries(i));
            end
        end

        function clear(self)
            self.Entries = struct( ...
            't', datetime.empty(0,1), ...
            'level', strings(0,1), ...
            'msg', strings(0,1), ...
            'source', strings(0,1), ...
            'tag', strings(0,1), ...
            'data', cell(0,1));

            self.TotalCount = 0;
            self.PendingUILines = "";
            self.PendingFileLines = "";
            self.PendingUICount = 0;
            self.PendingFileCount = 0;
            self.LastFlushTic = tic;
        end

        function flush(self)
            %FLUSH Force flushing batched lines to UI/file.
            self.flush_();
        end
    end

    methods (Access=private)
        function applyConfig_(self, config)
            self.Level = config.Level;
            self.Detail = config.Detail;
            self.SourceDetail = config.SourceDetail;
            self.CommandWindowLevel = config.CommandWindowLevel;
            self.CommandWindowDetail = config.CommandWindowDetail;
            self.UILevel = config.UILevel;
            self.UIDetail = config.UIDetail;
            self.FileLevel = config.FileLevel;
            self.FileDetail = config.FileDetail;
        end

        function source = detectSource_(self)
            %DETECTSOURCE_ Infer the first non-logging caller from the stack.
            %
            % Facade calls add matlabx.Log.* and Logger.* frames between the
            % user's code and Logger.log(). Skip those so SourceDetail remains a
            % logger/policy concern without the facade hardcoding formatting.

            st = dbstack(1, '-completenames');

            for k = 1:numel(st)
                name = string(st(k).name);
                if self.isLoggingFrame_(name)
                    continue
                end

                source = matlabx.logging.formatCallerName( ...
                    name, "Detail", self.SourceDetail);
                return
            end

            source = "unknown";
        end

        function tf = isLoggingFrame_(~, name)
            name = string(name);
            tf = startsWith(name, "matlabx.logging.Logger.") || ...
                name == "matlabx.logging.Logger" || ...
                startsWith(name, "matlabx.Log.") || ...
                name == "matlabx.Log" || ...
                startsWith(name, "Logger.") || ...
                name == "Logger" || ...
                startsWith(name, "Log.") || ...
                name == "Log";
        end

        function appendEntry_(self, e)
            self.TotalCount = self.TotalCount + 1;

            self.Entries(end+1) = e;

            if ~self.KeepAll
                n = numel(self.Entries);
                if n > self.MaxEntries
                    self.Entries = self.Entries(end-self.MaxEntries+1:end);
                end
            end
        end

        function s = formatEntry_(self, e, detail)
            % Build: [timestamp] [LEVEL] [Source] message  (configurable)
            if nargin < 3
                detail = self.Detail;
            end

            parts = strings(0,1);

            ts = string(datetime(e.t, 'Format', self.TimestampFormat));
            parts(end+1,1) = "[" + ts + "]";

            if self.IncludeLevel
                parts(end+1,1) = "[" + upper(e.level) + "]";
            end

            includeSource = self.IncludeSource && strlength(e.source) > 0 && detail ~= "normal";
            includeTag = self.IncludeTag && strlength(e.tag) > 0 && detail ~= "normal";

            if includeSource
                parts(end+1,1) = "[" + e.source + "]";
            end

            if includeTag
                parts(end+1,1) = "[" + e.tag + "]";
            end

            parts(end+1,1) = e.msg;

            s = strjoin(parts, " ");

            if detail == "debug"
                s = self.appendDebugDetails_(s, e);
            end
        end

        function s = appendDebugDetails_(~, s, e)
            if ~isstruct(e.data)
                return
            end

            details = strings(0,1);

            if isfield(e.data, 'identifier') && strlength(string(e.data.identifier)) > 0
                details(end+1,1) = "identifier: " + string(e.data.identifier);
            end

            if isfield(e.data, 'stack') && ~isempty(e.data.stack)
                details(end+1,1) = "stack:";
                for k = 1:numel(e.data.stack)
                    frame = e.data.stack(k);
                    details(end+1,1) = sprintf("  %s (%s:%d)", ...
                        string(frame.name), string(frame.file), frame.line);
                end
            end

            if ~isempty(details)
                s = s + newline + strjoin(details, newline);
            end
        end

        function queueUILine_(self, line)
            if self.PendingUICount == 0
                self.PendingUILines = line;
            else
                self.PendingUILines(end+1,1) = line;
            end
            self.PendingUICount = self.PendingUICount + 1;
        end

        function queueFileLine_(self, line)
            if self.PendingFileCount == 0
                self.PendingFileLines = line;
            else
                self.PendingFileLines(end+1,1) = line;
            end
            self.PendingFileCount = self.PendingFileCount + 1;
        end

        function maybeFlush_(self)
            if max(self.PendingUICount, self.PendingFileCount) < self.FlushEveryN
                return
            end
        
            % If timer handle isn't initialized yet, initialize it
            if self.LastFlushTic == uint64(0)
                self.LastFlushTic = tic;
                return
            end
        
            if toc(self.LastFlushTic) < self.FlushMinIntervalSec
                return
            end
        
            self.flush_();
        end

        function flush_(self)
            if self.PendingUICount == 0 && self.PendingFileCount == 0
                return
            end

            uiLines = self.PendingUILines;
            fileLines = self.PendingFileLines;
            uiCount = self.PendingUICount;
            fileCount = self.PendingFileCount;
            self.PendingUILines = "";
            self.PendingFileLines = "";
            self.PendingUICount = 0;
            self.PendingFileCount = 0;
            self.LastFlushTic = tic;

            % UI sink
            if self.EnableUISink && uiCount > 0
                try
                    self.UISinkFcn(uiLines);
                catch ME
                    % If UI sink fails, disable it but keep running
                    self.EnableUISink = false;
                    fprintf('[Logger] UI sink disabled due to error: %s\n', ME.message);
                end
            end

            % File sink
            if self.EnableFileSink && self.FileFID > 0 && fileCount > 0
                try
                    for i = 1:numel(fileLines)
                        fprintf(self.FileFID, '%s\n', fileLines(i));
                    end
                    % optional flush to disk; can be expensive on network drives
                    % fflush(self.FileFID);
                catch ME
                    self.EnableFileSink = false;
                    fprintf('[Logger] File sink disabled due to error: %s\n', ME.message);
                end
            end
        end

        function tf = shouldEmit_(self, sinkName, level)
            tf = matlabx.logging.Logger.levelRank(level) >= ...
                matlabx.logging.Logger.levelRank(self.effectiveLevel_(sinkName));
        end

        function level = effectiveLevel_(self, sinkName)
            switch sinkName
                case "CommandWindow"
                    level = self.CommandWindowLevel;
                case "UI"
                    level = self.UILevel;
                case "File"
                    level = self.FileLevel;
            end

            if strlength(level) == 0
                level = self.Level;
            end
        end

        function detail = effectiveDetail_(self, sinkName)
            switch sinkName
                case "CommandWindow"
                    detail = self.CommandWindowDetail;
                case "UI"
                    detail = self.UIDetail;
                case "File"
                    detail = self.FileDetail;
            end

            if strlength(detail) == 0
                detail = self.Detail;
            end
        end

        function openFile_(self, filePath)
            % Ensure any previous file is closed
            self.closeFile();

            % Create folder if needed
            [folder,~,~] = fileparts(filePath);
            if ~isempty(folder) && ~exist(folder,'dir')
                mkdir(folder);
            end

            % Open in append mode
            fid = fopen(filePath, 'a');
            if fid < 0
                error("Logger:FileOpenFailed", "Could not open log file: %s", filePath);
            end
            self.FileFID = fid;
            self.FilePath = filePath;
        end
    end

    methods (Static)
        function value = normalizeLevel(value)
            value = matlabx.config.Logging.normalizeLevel(value);
        end

        function value = normalizeOptionalLevel(value)
            value = matlabx.config.Logging.normalizeOptionalLevel(value);
        end

        function value = normalizeDetail(value)
            value = matlabx.config.Logging.normalizeDetail(value);
        end

        function value = normalizeOptionalDetail(value)
            value = matlabx.config.Logging.normalizeOptionalDetail(value);
        end

        function rank = levelRank(level)
            level = matlabx.logging.Logger.normalizeLevel(level);
            levels = ["DEBUG", "INFO", "WARN", "ERROR"];
            rank = find(levels == level, 1, "first");
        end
    end
end
