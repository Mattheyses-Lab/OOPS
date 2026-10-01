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

classdef ImageAxesDisplayLimitsWindow < handle
    %IMAGEAXESDISPLAYLIMITSWINDOW Host-owned display-limits dialog controller.
    %
    %   ImageAxesDisplayLimitsWindow is a small collaborator for ImageAxes.
    %   It owns the display-limits popup and synchronizes that popup with the
    %   host ImageAxes display state. The underlying UI is currently
    %   matlabx.app.SliderGroupDialog, but the synchronization logic lives
    %   here so ImageAxes and the DisplayLimits toolbar tool stay lean.
    %
    %   Synchronization is bidirectional:
    %       - Slider edits call Host.setComponentCLim(...)
    %       - Host display/image events refresh the slider controls
    %
    %   The Refreshing_ and UpdatingHost_ guards prevent harmless but noisy
    %   feedback loops when one side is updating the other.

    properties (SetAccess = private)
        Host matlabx.ui.axes.ImageAxes = matlabx.ui.axes.ImageAxes.empty()
    end

    properties (Access = private, Transient, NonCopyable)
        Dialog matlabx.app.SliderGroupDialog = matlabx.app.SliderGroupDialog.empty()
        Listeners event.listener = event.listener.empty
    end

    properties (Access = private)
        Refreshing_ (1,1) logical = false
        UpdatingHost_ (1,1) logical = false
    end

    methods
        function obj = ImageAxesDisplayLimitsWindow(host)
        %IMAGEAXESDISPLAYLIMITSWINDOW Create a controller for one ImageAxes.
            arguments
                host (1,1) matlabx.ui.axes.ImageAxes
            end

            obj.Host = host;
            obj.Listeners(end+1) = listener(host, ...
                'DisplayStateChanged', @(~,evt) obj.onHostDisplayStateChanged(evt));
            obj.Listeners(end+1) = listener(host, ...
                'ImageDataChanged', @(~,evt) obj.onHostImageDataChanged(evt));
        end

        function open(obj)
        %OPEN Show the display-limits dialog, creating it if needed.
            state = obj.Host.getDisplayLimitsWindowState();
            if ~state.CanOpen
                return
            end

            if obj.hasOpenDialog()
                obj.refreshFromState(state);
                obj.Dialog.show();
                return
            end

            obj.createDialog(state);
        end

        function refresh(obj)
        %REFRESH Pull current ImageAxes display state into the dialog.
            if ~obj.hasOpenDialog() || obj.UpdatingHost_
                return
            end

            state = obj.Host.getDisplayLimitsWindowState();
            if ~state.CanOpen
                delete(obj.Dialog);
                obj.Dialog = matlabx.app.SliderGroupDialog.empty();
                return
            end

            obj.refreshFromState(state);
        end

        function delete(obj)
        %DELETE Tear down listeners and the owned dialog.
            if ~isempty(obj.Listeners)
                delete(obj.Listeners(isvalid(obj.Listeners)));
            end
            obj.Listeners = event.listener.empty;

            if ~isempty(obj.Dialog)
                delete(obj.Dialog(isvalid(obj.Dialog)));
            end
            obj.Dialog = matlabx.app.SliderGroupDialog.empty();
        end
    end

    methods (Access = private)
        function tf = hasOpenDialog(obj)
        %HASOPENDIALOG True when the underlying dialog handle is valid.
            tf = ~isempty(obj.Dialog) && all(isvalid(obj.Dialog));
        end

        function createDialog(obj, state)
        %CREATEDIALOG Create the underlying slider dialog on first open.
            obj.Dialog = matlabx.app.SliderGroupDialog( ...
                state.NumComponents, ...
                "Title", "Adjust display limits", ...
                "Name", state.Name, ...
                "Limits", state.Limits, ...
                "Value", state.Value, ...
                "RoundDigits", state.RoundDigits, ...
                "RoundValues", state.RoundValues, ...
                "ValueDisplayFormat", state.ValueDisplayFormat, ...
                "Colormap", state.Colormap, ...
                "ValueChangingFcn", @(o,e) obj.onSliderValueChanging(o,e), ...
                "ValueChangedFcn", @(o,e) obj.onSliderValueChanged(o,e), ...
                "ClosedFcn", @(~,~) obj.onDialogClosed());
        end

        function refreshFromState(obj, state)
        %REFRESHFROMSTATE Update existing controls from host state.
            obj.Refreshing_ = true;
            cleanup = onCleanup(@() obj.clearRefreshing_());

            obj.Dialog.updateGroup(state.NumComponents, ...
                "Name", state.Name, ...
                "Limits", state.Limits, ...
                "Value", state.Value, ...
                "RoundDigits", state.RoundDigits, ...
                "RoundValues", state.RoundValues, ...
                "ValueDisplayFormat", state.ValueDisplayFormat, ...
                "Colormap", state.Colormap);
        end

        function onSliderValueChanging(obj, slider, evt)
        %ONSLIDERVALUECHANGING Preview CLim changes during slider drags.
            obj.applySliderValue(slider, evt);
        end

        function onSliderValueChanged(obj, slider, evt)
        %ONSLIDERVALUECHANGED Commit CLim changes after slider edits.
            obj.applySliderValue(slider, evt);
        end

        function applySliderValue(obj, slider, evt)
        %APPLYSLIDERVALUE Push one slider value back to the host ImageAxes.
            if obj.Refreshing_
                return
            end

            obj.UpdatingHost_ = true;
            cleanup = onCleanup(@() obj.clearUpdatingHost_());
            obj.Host.setComponentCLim(slider.Value, evt.ID);
        end

        function onDialogClosed(obj)
        %ONDIALOGCLOSED Forget the dialog after the user closes it.
            obj.Dialog = matlabx.app.SliderGroupDialog.empty();
        end

        function onHostDisplayStateChanged(obj, ~)
        %ONHOSTDISPLAYSTATECHANGED Refresh controls after host display edits.
            obj.refresh();
        end

        function onHostImageDataChanged(obj, ~)
        %ONHOSTIMAGEDATACHANGED Refresh controls after image changes.
            obj.refresh();
        end

        function clearRefreshing_(obj)
        %CLEARREFRESHING_ Reset the refresh guard.
            obj.Refreshing_ = false;
        end

        function clearUpdatingHost_(obj)
        %CLEARUPDATINGHOST_ Reset the host-update guard.
            obj.UpdatingHost_ = false;
        end
    end
end
