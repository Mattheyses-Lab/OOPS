% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Version
%VERSION Compare numeric major/minor/patch versions independently of formatting.

    methods (Static)

        function result = compare(first,second)
        %COMPARE Return -1, 0, or 1; omitted minor/patch components are zero.
        % Compare components in order: weighted arithmetic fails when a minor
        % or patch component reaches 100 or exceeds a higher component's weight.

            try

                % Numeric version components compared lexicographically against the second version.
                a = oops.Version.parts_(first);

                % Numeric components of the second version, padded to match the first.
                b = oops.Version.parts_(second);

                % First component where the padded versions differ.
                index = find(a ~= b,1);

                if isempty(index)

                    % Comparison result: -1 for older, 0 for equal, and 1 for newer.
                    result = 0;
                else
                    result = sign(a(index)-b(index));
                end

            catch ME

                if ~isempty(which('matlabx.logging.Logger'))
                    oops.Log.EXCEPTION(ME);
                end

                rethrow(ME);
            end
        end

    end

    methods (Static, Access=private)

        function parts = parts_(value)
        %PARTS_ Validate a numeric version and normalize it to three components.

            % Version text normalized to a scalar string before parsing.
            value = string(value);

            if ~isscalar(value) || ismissing(value) || ...
                    isempty(regexp(char(value),'^\d+(?:\.\d+){0,2}$','once'))
                error('oops:version:InvalidVersion','Expected a numeric major.minor.patch version.');
            end

            % Dot-separated version components validated as nonnegative integers.
            components = str2double(split(value,'.'));

            if any(~isfinite(components) | components > flintmax)
                error('oops:version:InvalidVersion','Version components must be finite exact integers.');
            end

            % Numeric component vector used by version comparison.
            parts = zeros(3,1);
            parts(1:numel(components)) = components;
        end

    end
end
