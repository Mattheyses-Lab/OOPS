% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Log
%OOPS.LOG Static facade and singleton accessor for the oops session logger.
%
%
%   oops.Log.INFO("Input loaded")
%   oops.Log.EXCEPTION(ME)
%   [log, path] = oops.Log.startSession()
%
% Lazy creation prints to the command window. Explicit startSession() also
% opens a file sink. The underlying matlabx logger can accept a UI sink when
% the controller exists. close() flushes and closes the owned logger; clear()
% only releases the facade reference, matching DesmoSTORM's convention.

    methods (Static)

        function log = get()
        %GET Return the active logger, creating it if needed.

            % Session logger, created on demand if no valid instance is stored.
            log = oops.Log.peek_();

            if isempty(log) || ~isvalid(log)
                log = matlabx.logging.Logger();
                log.configure(oops.Log.defaultConfig());
                log.FlushMinIntervalSec = 0;
                oops.Log.store_(log);
            end

        end

        function set(log)
        %SET Replace the active logger.

            arguments
                log (1,1) matlabx.logging.Logger
            end
            oops.Log.store_(log);
        end

        function [log, logPath] = startSession(opts)
        %STARTSESSION Start command-window logging with an optional file sink.
        %
        %   [LOG, PATH] = oops.Log.startSession() creates a timestamped file
        %   under logs/. Use WriteFile=false for command-window-only output,
        %   or LogFile="path/to/session.log" to choose the output location.

            arguments
                opts.WriteFile (1,1) logical = true
                opts.LogFile (1,1) string = ""
                opts.LoggingConfig (1,1) matlabx.config.Logging = oops.Log.defaultConfig()
            end
            % Prepare the replacement first: a failed file open must leave
            % the existing logger available to report the exception.

            % Logger instance configured for a new application session.
            log = matlabx.logging.Logger();
            try
                log.configure(opts.LoggingConfig);
                log.FlushMinIntervalSec = 0;

                % Destination file for this session's persisted log messages.
                logPath = "";

                if opts.WriteFile
                    logPath = opts.LogFile;

                    if logPath == ""
                        logPath = string(oops.Paths.logFile());
                    end

                    log.setFileSink(char(logPath),true);
                end

            catch ME
                delete(log);
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end

            % Previously stored logger to release when replacing the session.
            oldLog = oops.Log.peek_();

            if ~isempty(oldLog) && isvalid(oldLog)
                oldLog.flush();
                delete(oldLog);
            end

            oops.Log.store_(log);
            oops.Log.INFO("Started OOPS logging session.");
        end

        function config = defaultConfig()
        %DEFAULTCONFIG Command-window INFO output and detailed DEBUG file output.
        % Logging policy is session-level, independent of project settings.

            % Logging configuration applied to the active session.
            config = oops.Log.configFromPreferences();
        end

        function config = configFromPreferences()
        %CONFIGFROMPREFERENCES Build logging policy from oops preferences.
        %
        %   Preferences are intentionally app/session-level rather than
        %   project settings. They can be changed from the command line using
        %   oops.Preferences.set(NAME, VALUE).

            % Persistent developer-mode switch selecting logging defaults.
            devMode = oops.Preferences.get("DeveloperMode", false);

            % Default logging configuration for the current runtime mode.
            defaults = oops.Log.preferenceDefaults(devMode);

            % Effective logging configuration after applying stored preferences.
            config = matlabx.config.Logging( ...
                "Level",               oops.Preferences.get("LoggingLevel", defaults.Level), ...
                "Detail",              oops.Preferences.get("LoggingDetail", defaults.Detail), ...
                "SourceDetail",        oops.Preferences.get("LoggingSourceDetail", defaults.SourceDetail), ...
                "CommandWindowLevel",  oops.Preferences.get("LoggingCommandWindowLevel", defaults.CommandWindowLevel), ...
                "CommandWindowDetail", oops.Preferences.get("LoggingCommandWindowDetail", defaults.CommandWindowDetail), ...
                "UILevel",             oops.Preferences.get("LoggingUILevel", defaults.UILevel), ...
                "UIDetail",            oops.Preferences.get("LoggingUIDetail", defaults.UIDetail), ...
                "FileLevel",           oops.Preferences.get("LoggingFileLevel", defaults.FileLevel), ...
                "FileDetail",          oops.Preferences.get("LoggingFileDetail", defaults.FileDetail));
        end

        function config = applyConfigFromPreferences()
        %APPLYCONFIGFROMPREFERENCES Reconfigure the active logger immediately.
        %
        %   CONFIG = APPLYCONFIGFROMPREFERENCES() rebuilds the logging
        %   policy from current preferences and applies it to the active
        %   logger. This is useful for runtime preference toggles.

            % Logging configuration applied to the active session.
            config = oops.Log.configFromPreferences();
            oops.Log.get().configure(config);
        end

        function defaults = preferenceDefaults(devMode)
        %PREFERENCEDEFAULTS Logging preference defaults for normal/developer sessions.
        %
        %   DEFAULTS = PREFERENCEDEFAULTS(DEVMODE) returns the logging
        %   default profile used when individual Logging* preferences have
        %   not been explicitly stored.

            arguments
                devMode (1,1) logical = oops.Preferences.get("DeveloperMode", false)
            end

            if devMode

                % Logging defaults exposed for the current application/runtime mode.
                defaults = struct( ...
                    "Level", "DEBUG", ...
                    "Detail", "debug", ...
                    "SourceDetail", "full", ...
                    "CommandWindowLevel", "DEBUG", ...
                    "CommandWindowDetail", "debug", ...
                    "UILevel", "DEBUG", ...
                    "UIDetail", "debug", ...
                    "FileLevel", "DEBUG", ...
                    "FileDetail", "debug");
            else
                defaults = struct( ...
                    "Level", "DEBUG", ...
                    "Detail", "normal", ...
                    "SourceDetail", "short", ...
                    "CommandWindowLevel", "INFO", ...
                    "CommandWindowDetail", "normal", ...
                    "UILevel", "INFO", ...
                    "UIDetail", "normal", ...
                    "FileLevel", "DEBUG", ...
                    "FileDetail", "debug");
            end

        end

        function configure(config)
        %CONFIGURE Apply a matlabx logging policy to the current session.

            oops.Log.get().configure(config);
        end

        function close()
        %CLOSE Flush and release the facade-owned logger and its file sink.

            % Logger instance used for this facade operation.
            log = oops.Log.peek_();

            if ~isempty(log) && isvalid(log)
                log.flush();
                delete(log);
            end

            oops.Log.store_([]);
        end

        function clear()
        %CLEAR Clear the stored logger handle from the facade.

            oops.Log.store_([]);
        end

        function tf = exists()
        %EXISTS True if a valid logger is currently stored.

            % Logger instance used for this facade operation.
            log = oops.Log.peek_();
            tf = ~isempty(log) && isvalid(log);
        end

        function INFO(msg, varargin)
        %INFO Log an INFO message.

            % Session logger and forwarded arguments including caller/source metadata.
            [log, args] = oops.Log.prepareArgs_(varargin{:});
            log.info(oops.Log.normalizeMsg_(msg), args{:});
        end

        function DEBUG(msg, varargin)
        %DEBUG Log a DEBUG message.

            % Session logger and forwarded arguments including caller/source metadata.
            [log, args] = oops.Log.prepareArgs_(varargin{:});
            log.debug(oops.Log.normalizeMsg_(msg), args{:});
        end

        function WARN(msg, varargin)
        %WARN Log a WARN message.

            % Session logger and forwarded arguments including caller/source metadata.
            [log, args] = oops.Log.prepareArgs_(varargin{:});
            log.warn(oops.Log.normalizeMsg_(msg), args{:});
        end

        function ERROR(msg, varargin)
        %ERROR Log an ERROR message.

            % Session logger and forwarded arguments including caller/source metadata.
            [log, args] = oops.Log.prepareArgs_(varargin{:});

            if isa(msg,'MException')
                log.error(msg, args{:});
            else
                log.error(oops.Log.normalizeMsg_(msg), args{:});
            end

        end

        function EXCEPTION(ME, varargin)
        %EXCEPTION Log an MException as an error.
            % Logging failure must never replace the original exception.

            try

                % Session logger and forwarded arguments including caller/source metadata.
                [log, args] = oops.Log.prepareArgs_(varargin{:});
                log.error(ME, args{:});
                log.flush();
            catch loggingError
                fprintf(2,'[OOPS] %s: %s\n[OOPS Log] %s\n', ...
                    ME.identifier,ME.message,loggingError.message);
            end
        end

        function LOG(level, msg, varargin)
        %LOG Generic logging entry point.

            % Session logger and forwarded arguments including caller/source metadata.
            [log, args] = oops.Log.prepareArgs_(varargin{:});
            log.log(level, oops.Log.normalizeMsg_(msg), args{:});
        end

        function flush()
        %FLUSH Flush pending UI/file sink output.

            oops.Log.get().flush();
        end

        function T = asTable()
        %ASTABLE Return stored log entries as a table.

            T = oops.Log.get().asTable();
        end

        function lines = exportText()
        %EXPORTTEXT Return formatted stored log lines.

            lines = oops.Log.get().exportText();
        end

    end

    methods (Static, Access=private)

        function log = peek_()
        %PEEK_ Return stored logger without creating one.

            % Logger instance used for this facade operation.
            log = oops.Log.store_();
        end

        function log = store_(newLog)
        %STORE_ Persistent storage owner for the logger handle.

            persistent L

            if nargin > 0

                % Persistent logger handle shared by all calls to the facade.
                L = newLog;
            end

            % Logger handle retained in the facade's persistent storage.
            log = L;
        end

        function [log, args] = prepareArgs_(varargin)
        %PREPAREARGS_ Preserve explicit Source or infer the app caller.

            % Active session logger used for this facade call.
            log = oops.Log.get();

            % Forwarded name/value arguments, extended with inferred source information.
            args = varargin;

            % Position of an explicitly supplied Source argument, if present.
            idx = oops.Log.findNameValue_(args, "Source");

            if ~isempty(idx)
                return
            end

            args = [{'Source', oops.Log.detectSource_(log.SourceDetail)}, args];
        end

        function source = detectSource_(sourceDetail)
        %DETECTSOURCE_ Infer the first caller outside the oops facade.

            % Caller stack excluding the source-detection helper itself.
            st = dbstack(1, '-completenames');

            % Find the first caller frame outside the logging facade itself.
            for k = 1:numel(st)

                % Current stack frame name checked against the facade's internal frames.
                name = string(st(k).name);

                if oops.Log.isFacadeFrame_(name)
                    continue
                end

                % Formatted name of the first external caller, or the unknown fallback.
                source = matlabx.logging.formatCallerName( ...
                    name, "Detail", sourceDetail);
                return
            end

            source = "unknown";
        end

        function tf = isFacadeFrame_(name)
        %ISFACADEFRAME_ True for fully qualified or short oops facade frames.

            name = string(name);
            tf = startsWith(name, "oops.Log.") || ...
                name == "oops.Log" || ...
                startsWith(name, "Log.") || ...
                name == "Log";
        end

        function msg = normalizeMsg_(msg)
        %NORMALIZEMSG_ Preserve exceptions and convert other messages to text.

            if ~isa(msg, 'MException')
                msg = string(msg);
            end

        end

        function idx = findNameValue_(args, name)
        %FINDNAMEVALUE_ Find a name-value pair position in varargin-like input.

            % Matching name/value argument position, initially empty.
            idx = [];

            % Inspect name/value argument pairs for the requested option.
            for k = 1:2:(numel(args)-1)

                % Current candidate argument checked against the requested option name.
                key = args{k};

                if (ischar(key) || isstring(key)) && strcmpi(string(key), string(name))
                    idx = k;
                    return
                end

            end

        end

    end

end
