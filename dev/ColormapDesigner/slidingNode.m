classdef slidingNode < handle
%%  SLIDINGNODE creates slideable thumbs for colormapSliderWidget
%
%   NOTES:
%       This class is not designed to be used independently. It is used internally by colormapSliderWidget to
%       create the draggable color position slider thumbs.
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

    properties(Dependent=true)
        Value
        FaceColor
        EdgeColor
        EdgeWidth
        YPosition
        ButtonDownFcn
        ID
        Size1
        Size2
    end

    properties(SetAccess=private)
        isSelected (1,1) logical = false
    end

    properties(Access=private)
        user_Size1
        user_Size2
    end

    properties(Access=private,Transient,NonCopyable)
        nodeHandle matlab.graphics.primitive.Line
    end

    %% constructor and destructor

    methods

        % destructor
        function obj = slidingNode(Parent,Options)
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
                Options.Size1 (1,1) = 10
                Options.Size2 (1,1) = 12
            end
            % create the primitive line object which will show a single plot marker
            obj.nodeHandle = line(Parent,...
                Options.Value,...
                Options.YPosition,...
                'ButtonDownFcn',Options.ButtonDownFcn,...
                'MarkerFaceColor',Options.FaceColor,...
                'MarkerEdgeColor',Options.EdgeColor,...
                'MarkerSize',Options.Size1,...
                'Marker','o',...
                'LineWidth',Options.EdgeWidth);
            addprop(obj.nodeHandle,'ID');
            obj.nodeHandle.ID = Options.ID;
            obj.user_Size1 = Options.Size1;
            obj.user_Size2 = Options.Size2;
        end

        % destructor
        function delete(obj)
            % delete the primitive line object
            delete(obj.nodeHandle)
        end

    end

    %% context menus

    methods

        % add a context menu to the node
        function addContextMenu(obj,cm)
            obj.nodeHandle.ContextMenu = cm;
        end

    end

    %% dependent Set and Get methods

    methods

        function Value = get.Value(obj)
            Value = obj.nodeHandle.XData;
        end

        function set.Value(obj,val)
            obj.nodeHandle.XData = val;
        end

        function YPosition = get.YPosition(obj)
            YPosition = obj.nodeHandle.YData;
        end

        function set.YPosition(obj,val)
            obj.nodeHandle.YData = val;
        end

        function set.ButtonDownFcn(obj,val)
            obj.nodeHandle.ButtonDownFcn = val;
        end

        function ButtonDownFcn = get.ButtonDownFcn(obj)
            ButtonDownFcn = obj.nodeHandle.ButtonDownFcn;
        end

        function Color = get.FaceColor(obj)
            Color = obj.nodeHandle.MarkerFaceColor;
        end
        
        function set.FaceColor(obj,val)
            obj.nodeHandle.MarkerFaceColor = val;
        end
        
        function EdgeColor = get.EdgeColor(obj)
            EdgeColor = obj.nodeHandle.MarkerEdgeColor;
        end
        
        function set.EdgeColor(obj,val)
            obj.nodeHandle.MarkerEdgeColor = val;
        end

        function EdgeWidth = get.EdgeWidth(obj)
            EdgeWidth = obj.nodeHandle.LineWidth;
        end
        
        function set.EdgeWidth(obj,val)
            obj.nodeHandle.LineWidth = val;
        end

        function ID = get.ID(obj)
            ID = obj.nodeHandle.ID;
        end

        function set.ID(obj,val)
            obj.nodeHandle.ID = val;
        end

        function Size1 = get.Size1(obj)
            Size1 = obj.user_Size1;
        end

        function set.Size1(obj,val)
            obj.user_Size1 = val;
            obj.nodeHandle.MarkerSize = val;
        end

        function Size2 = get.Size2(obj)
            Size2 = obj.user_Size2;
        end

        function set.Size2(obj,val)
            obj.user_Size2 = val;
            obj.nodeHandle.MarkerSize = val;
        end

    end

    % select and deselect nodes
    methods

        function select(obj)
            obj.isSelected = true;
            obj.nodeHandle.MarkerSize = obj.Size2;
        end

        function deselect(obj)
            obj.isSelected = false;
            obj.nodeHandle.MarkerSize = obj.Size1;
        end

    end

end