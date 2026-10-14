% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef AuxiliaryComposite < matlabx.ui.axes.AxesTool
%AUXILIARYCOMPOSITE Toggle merged display for an auxiliary-channel source.

    properties (SetAccess=private)
        Available (1,1) logical = false
    end

    methods

        function obj = AuxiliaryComposite(host)
        %AUXILIARYCOMPOSITE Install a context-only state controller.

            obj@matlabx.ui.axes.AxesTool(host,"AuxiliaryComposite", ...
                'Tooltip','Show/Hide Auxiliary Channel Composite', ...
                'AxesType',"image", ...
                'Style','state');
            obj.ContributeToolbar = false;
        end

        function setAvailable(obj,value)
        %SETAVAILABLE Restrict composite behavior to a mergeable channel source.

            validateattributes(value,{'logical'},{'scalar'});
            obj.Available = value;

            if ~value
                obj.Host.ShowComposite = 'off';
            elseif obj.Enabled
                obj.Host.ShowComposite = 'on';
            end
        end

        function onEnabled(obj)
        %ONENABLED Show the merged image when channel content is available.

            if obj.Available
                obj.Host.ShowComposite = 'on';
            end
        end

        function onDisabled(obj)
        %ONDISABLED Return to the currently selected individual component.

            obj.Host.ShowComposite = 'off';
        end

        function contributeContextMenu(obj,menu)
        %CONTRIBUTECONTEXTMENU Add a checked composite command to ImageAxes.

            menu.addItem( ...
                "AuxiliaryComposite.Visible", ...
                "Show channel composite", ...
                @(~,~) obj.toggle(), ...
                'Owner',obj, ...
                'Checked',matlab.lang.OnOffSwitchState(obj.Enabled && obj.Available), ...
                'Enabled',matlab.lang.OnOffSwitchState(obj.Available), ...
                'RefreshFcn',@(item) obj.refreshMenuItem(item));
        end

    end

    methods (Access=private)

        function toggle(obj)
        %TOGGLE Change the remembered composite preference.

            if obj.Enabled
                obj.disable();
            else
                obj.enable();
            end
        end

        function refreshMenuItem(obj,item)
        %REFRESHMENUITEM Synchronize availability and checked state on opening.

            item.Enable = matlab.lang.OnOffSwitchState(obj.Available);
            item.Checked = matlab.lang.OnOffSwitchState(obj.Enabled && obj.Available);
        end

    end

end
