% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef OrientationField < matlabx.ui.axes.AxesTool
%ORIENTATIONFIELD Control one passive orientation-field mount in ImageAxes.
% Enabled records the user's visibility preference. Available records whether
% the current viewer source and model outputs can supply field data.

    properties (SetAccess=private)
        Available (1,1) logical = false
    end

    properties (Access=private)
        Mount = []
    end

    methods

        function obj = OrientationField(host,mount)
        %ORIENTATIONFIELD Construct an application tool for an existing mount.

            arguments
                host (1,1) matlabx.ui.axes.ImageAxes
                mount (1,1) matlabx.ui.axes.ImageAxesOverlayMount
            end

            obj@matlabx.ui.axes.AxesTool(host,"OrientationField", ...
                'Tooltip','Show/Hide Orientation Field', ...
                'AxesType',"image", ...
                'Icon',matlabx.internal.Paths.icons('DrawLineWhiteFGTransparentBG.svg'), ...
                'Style','state');

            obj.Mount = mount;
        end

        function setAvailable(obj,value)
        %SETAVAILABLE Apply source availability without changing user preference.

            validateattributes(value,{'logical'},{'scalar'});
            obj.Available = value;
            obj.updateVisibility();
        end

        function onEnabled(obj)
        %ONENABLED Show available field content after a user toggle.

            obj.updateVisibility();
        end

        function onDisabled(obj)
        %ONDISABLED Hide the field while retaining its data and availability.

            obj.updateVisibility();
        end

        function onUninstall(obj)
        %ONUNINSTALL Hide content when its controlling UI is removed.

            if isvalid(obj.Mount)
                obj.Mount.Visible = 'off';
            end
        end

        function contributeContextMenu(obj,menu)
        %CONTRIBUTECONTEXTMENU Add an owner-scoped visibility command.

            menu.addItem( ...
                "OrientationField.Visible", ...
                "Show orientation field", ...
                @(~,~) obj.toggle(), ...
                'Owner',obj, ...
                'Checked',matlab.lang.OnOffSwitchState(obj.Enabled), ...
                'RefreshFcn',@(item) obj.refreshMenuItem(item));
        end

    end

    methods (Access=private)

        function toggle(obj)
        %TOGGLE Change the stored user preference through AxesTool lifecycle.

            if obj.Enabled
                obj.disable();
            else
                obj.enable();
            end
        end

        function refreshMenuItem(obj,item)
        %REFRESHMENUITEM Synchronize checked state before the menu opens.

            item.Checked = matlab.lang.OnOffSwitchState(obj.Enabled);
        end

        function updateVisibility(obj)
        %UPDATEVISIBILITY Combine user preference with current availability.

            if isvalid(obj.Mount)
                obj.Mount.Visible = matlab.lang.OnOffSwitchState( ...
                    obj.Enabled && obj.Available);
            end
        end

    end

end
