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

classdef MachineState
    methods (Static)

        function S = load()
            file = matlabx.internal.Paths.machineStateFile();

            if ~isfile(file)
                S = struct();
                return
            end

            txt = fileread(file);
            S = jsondecode(txt);
        end

        function save(S)
            folder = matlabx.internal.Paths.prefRoot();
            if ~isfolder(folder)
                mkdir(folder);
            end

            file = matlabx.internal.Paths.machineStateFile();
            txt = jsonencode(S, PrettyPrint=true);

            fid = fopen(file, 'w');
            cleaner = onCleanup(@() fclose(fid));
            fwrite(fid, txt, 'char');
        end

        function value = get(fieldName, defaultValue)
            arguments
                fieldName (1,:) char
                defaultValue = []
            end

            S = matlabx.config.MachineState.load();
            if isfield(S, fieldName)
                value = S.(fieldName);
            else
                value = defaultValue;
            end
        end

        function set(fieldName, value)
            arguments
                fieldName (1,:) char
                value
            end

            S = matlabx.config.MachineState.load();
            S.(fieldName) = value;
            matlabx.config.MachineState.save(S);
        end

        function txt = print(fieldName)
        %PRINT Print current machine-local state, optionally limited to one field.
        %
        %   matlabx.config.MachineState.print() prints all saved state.
        %   matlabx.config.MachineState.print("UICalibration") prints one field.
        %   txt = matlabx.config.MachineState.print(...) returns formatted text.

            S = matlabx.config.MachineState.load();

            if nargin > 0
                fieldName = string(fieldName);
                if ~isscalar(fieldName)
                    error('matlabx:config:MachineState:InvalidField', ...
                        'Machine-state field must be a text scalar.');
                end

                fieldName = char(fieldName);
                if ~isfield(S, fieldName)
                    error('matlabx:config:MachineState:UnknownField', ...
                        'Unknown machine-state field "%s".', fieldName);
                end

                value = S.(fieldName);
                if isstruct(value) && isscalar(value)
                    S = value;
                else
                    S = struct(fieldName, value);
                end
            end

            if nargout == 0
                matlabx.struct.prettyPrint(S);
            else
                txt = matlabx.struct.prettyPrint(S);
            end
        end
    end
end
