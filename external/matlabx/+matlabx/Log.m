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

classdef Log
%MATLABX.LOG  Static facade and singleton accessor for the matlabx logger.
%
% Typical use
% -----------
%   matlabx.Log.INFO("Application started")
%   matlabx.Log.WARN("Something looks odd")
%
% Get underlying logger handle when needed
% ----------------------------------------
%   log = matlabx.Log.get();
%   log.setFileSink(logPath, true);
%   log.setUISink(@(lines) appendToTextArea(matlabx.LogTextArea, lines), true);
%
% Configure policy
% ----------------
%   matlabx.Log.configure(matlabx.Settings.get().Logging)
%   matlabx.Log.configure("Level","DEBUG","Detail","debug")
%
% Notes
% -----
% - Lazy-creates a single matlabx.logging.Logger for the current MATLAB session.
% - Public wrapper methods preserve explicit Source values; otherwise the logger
%   infers Source according to its own AutoDetectSource/SourceDetail policy.
% - clear() removes the stored handle from the facade. If other references exist,
%   the logger object itself will remain alive until those references are released.

    methods (Static)

        function log = get()
        %GET Return the active logger, creating it if needed.
            log = matlabx.Log.peek_();
            if isempty(log) || ~isvalid(log)
                log = matlabx.logging.Logger();
                log.configure(matlabx.Log.config_());
                matlabx.Log.store_(log);
            end
        end

        function set(log)
        %SET Replace the active logger.
            arguments
                log (1,1) matlabx.logging.Logger
            end
            log.configure(matlabx.Log.config_());
            matlabx.Log.store_(log);
        end

        function config = configure(varargin)
        %CONFIGURE Apply a logging policy to the active/session logger.
        %
        %   matlabx.Log.configure(config)
        %   matlabx.Log.configure("Level","DEBUG","Detail","debug")

            config = matlabx.Log.parseConfig_(varargin{:});
            matlabx.Log.config_(config);

            log = matlabx.Log.peek_();
            if ~isempty(log) && isvalid(log)
                log.configure(config);
            end
        end

        function config = getConfig()
        %GETCONFIG Return the active session logging policy.
            config = matlabx.Log.config_();
        end

        function clear()
        %CLEAR Clear the stored logger handle from the facade.
            matlabx.Log.store_([]);
        end

        function deleteLogger()
        %DELETE Delete the active logger.
            log = matlabx.Log.peek_();
            if ~isempty(log) && isvalid(log), delete(log); end
            matlabx.Log.clear();
        end

        function tf = exists()
        %EXISTS True if a valid logger is currently stored.
            log = matlabx.Log.peek_();
            tf = ~isempty(log) && isvalid(log);
        end

        function INFO(msg, varargin)
        %INFO Log an INFO message.
            args = matlabx.Log.forwardSourceArgs_(varargin{:});
            matlabx.Log.get().info(msg, args{:});
        end

        function DEBUG(msg, varargin)
        %DEBUG Log a DEBUG message.
            args = matlabx.Log.forwardSourceArgs_(varargin{:});
            matlabx.Log.get().debug(msg, args{:});
        end

        function WARN(msg, varargin)
        %WARN Log a WARN message.
            args = matlabx.Log.forwardSourceArgs_(varargin{:});
            matlabx.Log.get().warn(msg, args{:});
        end

        function ERROR(msg, varargin)
        %ERROR Log an ERROR message.
            args = matlabx.Log.forwardSourceArgs_(varargin{:});
            matlabx.Log.get().error(msg, args{:});
        end

        function EXCEPTION(ME, varargin)
        %EXCEPTION Log an MException as an error.
            args = matlabx.Log.forwardSourceArgs_(varargin{:});
            matlabx.Log.get().error(ME, args{:});
        end

        function LOG(level, msg, varargin)
        %LOG Generic logging entry point.
            args = matlabx.Log.forwardSourceArgs_(varargin{:});
            matlabx.Log.get().log(level, msg, args{:});
        end

        function flush()
        %FLUSH Flush pending UI/file sink output.
            matlabx.Log.get().flush();
        end

        function T = asTable()
        %ASTABLE Return stored log entries as a table.
            T = matlabx.Log.get().asTable();
        end

        function lines = exportText()
        %EXPORTTEXT Return formatted stored log lines.
            lines = matlabx.Log.get().exportText();
        end

    end

    methods (Static, Access=private)

        function log = peek_()
        %PEEK_ Return stored logger without creating one.
            log = matlabx.Log.store_();
        end

        function log = store_(newLog)
        %STORE_ Persistent storage owner for the logger handle.
            persistent L
            if nargin > 0
                L = newLog;
            end
            log = L;
        end

        function config = config_(newConfig)
        %CONFIG_ Persistent storage owner for the session logging policy.
            persistent C
            if nargin > 0
                C = newConfig;
            end

            if isempty(C) || ~isvalid(C)
                C = matlabx.Log.defaultConfig_();
            end

            config = C;
        end

        function config = defaultConfig_()
        %DEFAULTCONFIG Use Settings.Logging when available, otherwise defaults.
            try
                settings = matlabx.Settings.get();
                config = matlabx.Log.copyConfig_(settings.Logging);
            catch
                config = matlabx.config.Logging();
            end
        end

        function config = parseConfig_(varargin)
        %PARSECONFIG_ Convert config object or name-value pairs to a policy.
            if nargin == 1 && isa(varargin{1}, 'matlabx.config.Logging')
                config = matlabx.Log.copyConfig_(varargin{1});
                return
            end

            if mod(nargin, 2) ~= 0
                error('matlabx:Log:InvalidConfigureInput', ...
                    'configure expects a matlabx.config.Logging object or name-value pairs.');
            end

            config = matlabx.Log.copyConfig_(matlabx.Log.config_());
            for k = 1:2:nargin
                name = string(varargin{k});
                if ~isscalar(name) || strlength(name) == 0
                    error('matlabx:Log:InvalidConfigureName', ...
                        'Logging configuration names must be text scalars.');
                end

                name = char(name);
                if ~isprop(config, name)
                    error('matlabx:Log:UnknownConfigureName', ...
                        'Unknown logging configuration property "%s".', name);
                end

                config.(name) = varargin{k+1};
            end
        end

        function config = copyConfig_(source)
        %COPYCONFIG_ Copy a logging policy so facade configuration is session-local.
            config = matlabx.config.Logging();
            config.fromStruct(source.toStruct());
        end

        function args = forwardSourceArgs_(varargin)
            %FORWARDSOURCEARGS_ Preserve explicit Source and leave inference to Logger.
            args = varargin;
        end

    end

end
