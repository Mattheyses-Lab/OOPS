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

classdef Logging < handle
%LOGGING Declarative logging policy for matlabx logging.
%
%   Level is the primary modern filtering control and means "minimum emitted
%   level." Sink-specific Level/Detail values may be left empty to inherit the
%   global Level/Detail.
%
%   ShowDebugOutput is retained for older settings files and code paths. It is
%   only used to infer Level when Level has not been explicitly supplied.

    properties (Dependent)
        Level (1,1) string
        ShowDebugOutput (1,1) logical
    end

    properties
        Detail (1,1) string {mustBeMember(Detail, ["normal", "verbose", "debug"])} = "normal"
        SourceDetail (1,1) string {mustBeMember(SourceDetail, ["short", "full"])} = "short"

        CommandWindowLevel (1,1) string = ""
        CommandWindowDetail (1,1) string = ""

        UILevel (1,1) string = ""
        UIDetail (1,1) string = ""

        FileLevel (1,1) string = ""
        FileDetail (1,1) string = ""
    end

    properties (Access=private)
        Level_ (1,1) string = "INFO"
        ShowDebugOutput_ (1,1) logical = false
        LevelWasExplicit_ (1,1) logical = false
    end

    methods
        function obj = Logging(opts)
            arguments
                opts.Level = []
                opts.Detail = []
                opts.SourceDetail = []
                opts.ShowDebugOutput = []
                opts.CommandWindowLevel = []
                opts.CommandWindowDetail = []
                opts.UILevel = []
                opts.UIDetail = []
                opts.FileLevel = []
                opts.FileDetail = []
            end

            if ~isempty(opts.ShowDebugOutput)
                obj.ShowDebugOutput = opts.ShowDebugOutput;
            end
            if ~isempty(opts.Level)
                obj.Level = opts.Level;
            end
            if ~isempty(opts.Detail)
                obj.Detail = opts.Detail;
            end
            if ~isempty(opts.SourceDetail)
                obj.SourceDetail = opts.SourceDetail;
            end

            obj.applyOptional_("CommandWindowLevel", opts.CommandWindowLevel);
            obj.applyOptional_("CommandWindowDetail", opts.CommandWindowDetail);
            obj.applyOptional_("UILevel", opts.UILevel);
            obj.applyOptional_("UIDetail", opts.UIDetail);
            obj.applyOptional_("FileLevel", opts.FileLevel);
            obj.applyOptional_("FileDetail", opts.FileDetail);
        end

        function value = get.Level(obj)
            value = obj.Level_;
        end

        function set.Level(obj, value)
            obj.Level_ = matlabx.config.Logging.normalizeLevel(value);
            obj.LevelWasExplicit_ = true;
        end

        function value = get.ShowDebugOutput(obj)
            value = obj.ShowDebugOutput_;
        end

        function set.ShowDebugOutput(obj, value)
            obj.ShowDebugOutput_ = logical(value);

            if ~obj.LevelWasExplicit_
                if obj.ShowDebugOutput_
                    obj.Level_ = "DEBUG";
                else
                    obj.Level_ = "INFO";
                end
            end
        end

        function set.Detail(obj, value)
            obj.Detail = matlabx.config.Logging.normalizeDetail(value);
        end

        function set.CommandWindowLevel(obj, value)
            obj.CommandWindowLevel = matlabx.config.Logging.normalizeOptionalLevel(value);
        end

        function set.UILevel(obj, value)
            obj.UILevel = matlabx.config.Logging.normalizeOptionalLevel(value);
        end

        function set.FileLevel(obj, value)
            obj.FileLevel = matlabx.config.Logging.normalizeOptionalLevel(value);
        end

        function set.CommandWindowDetail(obj, value)
            obj.CommandWindowDetail = matlabx.config.Logging.normalizeOptionalDetail(value);
        end

        function set.UIDetail(obj, value)
            obj.UIDetail = matlabx.config.Logging.normalizeOptionalDetail(value);
        end

        function set.FileDetail(obj, value)
            obj.FileDetail = matlabx.config.Logging.normalizeOptionalDetail(value);
        end

        function S = toStruct(obj)
            S = struct( ...
                'Level', char(obj.Level), ...
                'Detail', char(obj.Detail), ...
                'SourceDetail', char(obj.SourceDetail), ...
                'CommandWindowLevel', char(obj.CommandWindowLevel), ...
                'CommandWindowDetail', char(obj.CommandWindowDetail), ...
                'UILevel', char(obj.UILevel), ...
                'UIDetail', char(obj.UIDetail), ...
                'FileLevel', char(obj.FileLevel), ...
                'FileDetail', char(obj.FileDetail), ...
                'ShowDebugOutput', obj.ShowDebugOutput);
        end

        function fromStruct(obj,S)
            hasLevel = isfield(S,'Level') && ~isempty(S.Level);

            if isfield(S,'ShowDebugOutput')
                obj.ShowDebugOutput = S.ShowDebugOutput;
            end

            if hasLevel
                obj.Level = S.Level;
            end

            if isfield(S,'Detail'), obj.Detail = S.Detail; end
            if isfield(S,'SourceDetail'), obj.SourceDetail = S.SourceDetail; end
            if isfield(S,'CommandWindowLevel'), obj.CommandWindowLevel = S.CommandWindowLevel; end
            if isfield(S,'CommandWindowDetail'), obj.CommandWindowDetail = S.CommandWindowDetail; end
            if isfield(S,'UILevel'), obj.UILevel = S.UILevel; end
            if isfield(S,'UIDetail'), obj.UIDetail = S.UIDetail; end
            if isfield(S,'FileLevel'), obj.FileLevel = S.FileLevel; end
            if isfield(S,'FileDetail'), obj.FileDetail = S.FileDetail; end
        end
    end

    methods (Access=private)
        function applyOptional_(obj, name, value)
            if ~isempty(value)
                obj.(name) = value;
            end
        end
    end

    methods (Static)
        function value = normalizeLevel(value)
            value = upper(string(value));
            if ~isscalar(value) || ~ismember(value, ["DEBUG", "INFO", "WARN", "ERROR"])
                error('matlabx:config:Logging:InvalidLevel', ...
                    'Logging level must be DEBUG, INFO, WARN, or ERROR.');
            end
        end

        function value = normalizeOptionalLevel(value)
            value = string(value);
            if strlength(value) == 0
                value = "";
                return
            end
            value = matlabx.config.Logging.normalizeLevel(value);
        end

        function value = normalizeDetail(value)
            value = lower(string(value));
            if ~isscalar(value) || ~ismember(value, ["normal", "verbose", "debug"])
                error('matlabx:config:Logging:InvalidDetail', ...
                    'Logging detail must be normal, verbose, or debug.');
            end
        end

        function value = normalizeOptionalDetail(value)
            value = string(value);
            if strlength(value) == 0
                value = "";
                return
            end
            value = matlabx.config.Logging.normalizeDetail(value);
        end
    end
end
