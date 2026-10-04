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

classdef SliderThumb < handle
%%  SLIDERTHUMB draggable thumb used by uislidereditfield

    properties
        ID
    end

    properties(Dependent)
        YPosition
        Value
        Visible
    end

    properties(SetObservable,AbortSet)
        FaceColor = [0.5 0.5 0.5]
        EdgeColor = 1
        EdgeWidth = 1
        ButtonDownFcn = ''
        Size1 = 6
        Size2 = 8

        isSelected (1,1) logical = false
    end

    properties(Access=private,Transient,NonCopyable)
        thumb matlab.graphics.primitive.Line
        pendingUpdate logical = false
        L event.listener
    end

    %% constructor and destructor

    methods

        % destructor
        function obj = SliderThumb(Parent,Options)
            % validate input args, set defaults
            arguments
                Parent (1,1) matlab.ui.control.UIAxes
                Options.Value (1,1) double = 1
                Options.FaceColor (1,3) = [0.5 0.5 0.5]
                Options.EdgeColor (1,3) = [0 0 0]
                Options.EdgeWidth (1,1) = 1
                Options.YPosition (1,1) = 25.5
                Options.ButtonDownFcn = '';
                Options.ID (1,1) = 1
                Options.Size1 (1,1) = 6
                Options.Size2 (1,1) = 8
            end
            % create the primitive line object which will show a single plot marker
            obj.thumb = line(Parent,...
                Options.Value,...
                Options.YPosition,...
                'ButtonDownFcn',Options.ButtonDownFcn,...
                'MarkerFaceColor',Options.FaceColor,...
                'MarkerEdgeColor',Options.EdgeColor,...
                'MarkerSize',Options.Size1,...
                'Marker','o',...
                'LineWidth',Options.EdgeWidth);
            addprop(obj.thumb,'ID');
            obj.thumb.ID = Options.ID;

            % apply inputs
            obj.Value       = Options.Value;
            obj.YPosition   = Options.YPosition;

            obj.FaceColor   = Options.FaceColor;
            obj.EdgeColor   = Options.EdgeColor;
            obj.EdgeWidth   = Options.EdgeWidth;
            obj.Size1       = Options.Size1;
            obj.Size2       = Options.Size2;
            obj.ID          = Options.ID;

            obj.L = addlistener(obj, {'FaceColor','EdgeColor','EdgeWidth','Size1','Size2','isSelected'}, ...
                'PostSet', @(~,~) obj.updateAppearance());

        end

        % destructor
        function delete(obj)
            % delete the primitive line object
            delete(obj.thumb)
        end

    end

    %% context menus

    methods

        % add a context menu to the thumb
        function addContextMenu(obj,cm)
            obj.thumb.ContextMenu = cm;
        end

    end

    methods (Access=private)

        function updateAppearance(obj)

            set(obj.thumb,...
                'MarkerFaceColor',obj.FaceColor,...
                'MarkerEdgeColor',obj.EdgeColor,...
                'LineWidth',obj.EdgeWidth);
            
            if obj.isSelected
                obj.thumb.MarkerSize = obj.Size2; % Increase size when selected
            else
                obj.thumb.MarkerSize = obj.Size1; % Reset size when not selected
            end

        end

    end


    %% Dependent Set/Get
    methods

        function val = get.Value(obj)
            val = obj.thumb.XData;
        end

        function set.Value(obj,val)
            if val==obj.thumb.XData
                return
            end
            obj.thumb.XData = val;
        end

        function val = get.YPosition(obj)
            val = obj.thumb.YData;
        end

        function set.YPosition(obj,val)
            if val==obj.thumb.YData
                return
            end
            obj.thumb.YData = val;
        end

        function val = get.Visible(obj)
            val = obj.thumb.Visible;
        end

        function set.Visible(obj,val)
            obj.thumb.Visible = val;
        end

    end

    %% Thumb select/deselect
    methods

        function select(obj)
            if obj.isSelected
                return
            end

            obj.isSelected = true;
        end

        function deselect(obj)
            if ~obj.isSelected
                return
            end

            obj.isSelected = false;
        end

    end

end
