% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef OverlayVisibility < matlabx.ui.axes.AxesTool
%OVERLAYVISIBILITY Control one passive application-overlay mount.
% Enabled records the user's preference. Available records whether the
% active model/view source can currently provide the requested content.

    properties (SetAccess=private)
        Available (1,1) logical = false
    end

    properties
        RefreshRequestedFcn = []
    end

    properties (Access=private)
        Mount = []
        MenuLabel (1,1) string
    end

    methods

        function obj = OverlayVisibility(host,mount,name,opts)
        %OVERLAYVISIBILITY Construct a state tool for an existing passive mount.

            arguments
                host (1,1) matlabx.ui.axes.ImageAxes
                mount (1,1) matlabx.ui.axes.ImageAxesOverlayMount
                name (1,1) string
                opts.Tooltip (1,1) string = "Show/Hide " + name
                opts.MenuLabel (1,1) string = "Show " + lower(name)
                opts.Icon = []
            end

            obj@matlabx.ui.axes.AxesTool(host,name, ...
                'Tooltip',char(opts.Tooltip), ...
                'AxesType',"image", ...
                'Icon',opts.Icon, ...
                'Style','state');

            obj.Mount = mount;
            obj.MenuLabel = opts.MenuLabel;
        end

        function setAvailable(obj,value)
        %SETAVAILABLE Apply content availability without changing preference.

            validateattributes(value,{'logical'},{'scalar'});

            obj.Available = value;
            obj.updateVisibility();
        end

        function onEnabled(obj)
        %ONENABLED Refresh available content before revealing its mount.

            if ~isempty(obj.RefreshRequestedFcn)
                obj.RefreshRequestedFcn(obj,[]);
            end

            obj.updateVisibility();
        end

        function onDisabled(obj)
        %ONDISABLED Hide content while retaining its data and availability.

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
                obj.Name + ".Visible", ...
                obj.MenuLabel, ...
                @(~,~) obj.toggle(), ...
                'Owner',obj, ...
                'Checked',matlab.lang.OnOffSwitchState(obj.Enabled), ...
                'RefreshFcn',@(item) obj.refreshMenuItem(item));
        end

    end

    methods (Access=private)

        function toggle(obj)
        %TOGGLE Change visibility through the AxesTool state lifecycle.

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
        %UPDATEVISIBILITY Combine the stored preference with availability.

            if isvalid(obj.Mount)
                obj.Mount.Visible = matlab.lang.OnOffSwitchState( ...
                    obj.Enabled && obj.Available);
            end
        end

    end

end
