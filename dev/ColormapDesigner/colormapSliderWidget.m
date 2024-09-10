classdef colormapSliderWidget < matlab.ui.componentcontainer.ComponentContainer
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

    properties(SetObservable=true)
        cmap (256,3) = gray
    end

    properties(Access=private)
        % ancestor figure of the component
        parentFig
        % idx of the sliding node
        activeNodeIdx = NaN
        % normalized positions of the colors in the colormap (0 -> first color, 1 -> last color, etc...)
        mapNodes = [0, 1]
        % colors of each color node in the colormap
        rgbTriplets = [0 0 0;1 1 1]
        % index of each color node in the colormap (1 -> first color, 256 -> last color)
        barNodes = [1, 256]
        % idx of each sliding node, used to ensure nodes do not overlap or cross
        nodeIDs = [1, 2]
    end
    
    properties(Access = private,Transient,NonCopyable)
        % outermost grid for the entire component
        containerGrid (1,1) matlab.ui.container.GridLayout
        % panel to hold colorbar slider axes
        colorbarPanel (1,1) matlab.ui.container.Panel
        % axes to hold the colorbar slider
        colorbarAxes (1,1) matlab.ui.control.UIAxes
        % image to show colormap
        colorbarImage (1,1) matlab.graphics.primitive.Image
        % axes to hold RGB nodes
        nodeSliderAxes (1,1) matlab.ui.control.UIAxes
        % the RGB nodes
        slidingNodes (:,1) slidingNode
        % context menu shown when right-clicking a node
        nodeCM (:,1)
        % listener for the colormap
        colormapListener (1,1)
    end

    properties(Dependent=true)
        nNodes (1,1) double
    end

    events (HasCallbackProperty, NotifyAccess = protected)
        ColormapChanged % ColormapChangedFcn callback property will be generated
    end
    
    methods(Access=protected)
    
        function setup(obj)
            % grid layout manager to enclose all the components
            obj.containerGrid = uigridlayout(obj,...
                [1,1],...
                "ColumnWidth",{'1x'},...
                "RowHeight",{30},...
                "BackgroundColor",obj.BackgroundColor,...
                "Padding",[5 5 5 5],...
                "Scrollable","on",...
                "RowSpacing",0);
            % axes to hold the example colorbar image
            obj.colorbarAxes = uiaxes(obj.containerGrid,...
                'XTick',[],...
                'YTick',[],...
                'XLim',[1 256],...
                'YLim',[0 50],...
                'XColor',[0 0 0],...
                'YColor',[0 0 0],...
                'Units','Normalized',...
                'InnerPosition',[0 0 1 1],...
                'LineWidth',2,...
                'Box','on',...
                'BoxStyle','full',...
                'HitTest','on',...
                'PickableParts','all',...
                'ButtonDownFcn',@(o,e) obj.colorbarClicked(o,e));
            obj.colorbarAxes.Layout.Row =  1;
            obj.colorbarAxes.Toolbar.Visible = 'off';
            disableDefaultInteractivity(obj.colorbarAxes)
            % image to display the colormap
            obj.colorbarImage = image(obj.colorbarAxes,...
                'CData',repmat(1:256,50,1),...
                'CDataMapping','scaled',...
                'PickableParts','none',...
                'HitTest','off');
            % get the parent figure so we can set up context menus
            obj.parentFig = ancestor(obj,'figure','toplevel');
            % create the context menu for the sliding nodes
            obj.nodeCM = uicontextmenu(obj.parentFig);
            uimenu(obj.nodeCM,"Text","Delete node");
            % create the beginning and end nodes
            obj.slidingNodes(1) = slidingNode(obj.colorbarAxes,...
                "EdgeColor",[1 1 1],...
                "FaceColor",[0 0 0],...
                "Value",1,...
                "YPosition",25,...
                "ButtonDownFcn",@(o,e) obj.slidingNodeClicked(o,e),...
                "ID",1);
            obj.slidingNodes(2) = slidingNode(obj.colorbarAxes,...
                "EdgeColor",[0 0 0],...
                "FaceColor",[1 1 1],...
                "Value",256,...
                "YPosition",25.5,...
                "ButtonDownFcn",@(o,e) obj.slidingNodeClicked(o,e),...
                "ID",2);
            % set up listener for cmap to enable the ColormapChanged callback
            obj.colormapListener = addlistener(...
                obj,'cmap',...
                'PostSet',@(o,e) obj.colormapChanged);
        end

        function update(obj)
            % convert map idxs to the range [0,1]
            obj.mapNodes = (obj.barNodes-1)/255;
            % compute and store cmap
            obj.cmap = mapFromRGB(obj.rgbTriplets,"colorPositions",obj.mapNodes);
            % set the 'Colormap' property of the example colorbar to cmap
            obj.colorbarAxes.Colormap = obj.cmap;
        end
    
    end

    %% callback methods

    methods

        % called when the colorbar is clicked at a position with no existing node
        function colorbarClicked(obj,source,~)
            % get the horizontal position of the clicked point
            xPosition = round(source.CurrentPoint(1));
            % add a new slidingNode at that position
            obj.addNewNode(xPosition);
        end

        % called when one of the sliding nodes is clicked
        function slidingNodeClicked(obj,source,~)
            % the index of the clicked node
            nodeIdx = source.ID;
            % select the node
            obj.selectNode(nodeIdx);
            % choose behavior based on the type of click
            switch obj.parentFig.SelectionType
                case 'alt'
                %% ctrl-click or right-click - delete node
                    % if user clicked first or last nodes
                    if nodeIdx==1 || nodeIdx==obj.nodeIDs(end)
                        % do nothing
                        return
                    else
                        % otherwise, delete the clicked node
                        obj.deleteNode(nodeIdx);
                    end
                case 'normal'
                %% left-click - enable sliding
                    % if user selected first or last nodes
                    if nodeIdx==1 || nodeIdx==obj.nodeIDs(end)
                        % do nothing
                        return
                    else
                        % store idx of clicked node
                        obj.activeNodeIdx = nodeIdx;
                        % set WindowButtonMotionFcn to enable sliding
                        obj.parentFig.WindowButtonMotionFcn = @(o,e) obj.startSliding(o,e);
                        % set WindowButtonUpFcn so that sliding ends when button is released
                        obj.parentFig.WindowButtonUpFcn = @(o,e) obj.stopSliding(o,e);
                    end
                case 'extend'
                % shift-click
                % nothing yet

                case 'open'
                %% double-click - open color picker
                    try
                        % hide figure
                        obj.parentFig.Visible = 'off';
                        % open color picker
                        newNodeColor = uisetcolor();
                    catch
                        % use existing color if error caught
                        newNodeColor = obj.rgbTriplets(nodeIdx,:);
                    end
                    % show the figure
                    obj.parentFig.Visible = 'on';
                    % user selected 'cancel'
                    if isequal(newNodeColor,0)
                        % do nothing
                        return
                    else
                        % update the list of colors
                        obj.rgbTriplets(nodeIdx,:) = newNodeColor;
                        % update colors of the slidingNode
                        obj.slidingNodes(nodeIdx).FaceColor = newNodeColor;
                        obj.slidingNodes(nodeIdx).EdgeColor = getBWContrastColor(newNodeColor);
                    end
            end
        end

        function startSliding(obj,~,~)
            % the node that is actively sliding
            activeNode = obj.slidingNodes(obj.activeNodeIdx);
            % current position of the cursor (rounded to the nearest integer)
            newVal = round(obj.colorbarAxes.CurrentPoint(1));
            % upper and lower limits of the node position, so that nodes do not cross each other
            upperLim = obj.slidingNodes(obj.activeNodeIdx+1).Value-1;
            lowerLim = obj.slidingNodes(obj.activeNodeIdx-1).Value+1;
            % make sure values fall within the range (lowerLim,upperLim)
            fixedVal = max(min(newVal,upperLim),lowerLim);
            % move the node to the position of the cursor, confined to the range (lowerLim,upperLim)
            activeNode.Value = fixedVal;
            % update the map index (barNodes) and color node positions (mapNodes)
            obj.barNodes(obj.activeNodeIdx) = fixedVal;
            obj.mapNodes(obj.activeNodeIdx) = (newVal-1)/255;
        end

        function stopSliding(obj,~,~)
            obj.parentFig.WindowButtonMotionFcn = '';
            obj.parentFig.WindowButtonUpFcn = '';
        end

        function colormapChanged(obj)
            % notify object that cmap has changed - ColormapChangedFcn will be called
            notify(obj,'ColormapChanged');
        end

    end

    %% node management

    methods

        function addNewNode(obj,nodePosition)
            % logical vector of nodes to the left of the new node position
            nodesBelow = obj.barNodes < nodePosition;
            % logical vector of nodes to the right of the new node position
            nodesAbove = obj.barNodes > nodePosition;
            % get the color of the new node from its position
            newNodeColor = obj.cmap(nodePosition,:);
            % idx of new node
            newNodeID = numel(obj.slidingNodes(nodesBelow))+1;
            % create new slidingNode object
            newSlidingNode = slidingNode(obj.colorbarAxes,...
                "EdgeColor",getBWContrastColor(newNodeColor),...
                "FaceColor",newNodeColor,...
                "Value",nodePosition,...
                "YPosition",25.5,...
                "ButtonDownFcn",@(o,e) obj.slidingNodeClicked(o,e),...
                "ID",newNodeID);
            % add it to the list of nodes
            obj.slidingNodes = [obj.slidingNodes(nodesBelow);newSlidingNode;obj.slidingNodes(nodesAbove)];
            % adjust other associated properties
            obj.barNodes = [obj.barNodes(nodesBelow),nodePosition,obj.barNodes(nodesAbove)];
            obj.rgbTriplets = [obj.rgbTriplets(nodesBelow,:);newNodeColor;obj.rgbTriplets(nodesAbove,:)];
            obj.nodeIDs = [obj.nodeIDs(nodesBelow),newNodeID,obj.nodeIDs(nodesAbove)+1];
            % reset node IDs
            for nodeIdx = obj.nodeIDs
                obj.slidingNodes(nodeIdx).ID = nodeIdx;
            end
        end

        function deleteNode(obj,nodePosition)
            % the node to delete
            node2Delete = obj.slidingNodes(nodePosition);
            % delete the node
            delete(node2Delete)
            % clear the placeholder
            obj.slidingNodes(nodePosition) = [];
            % delete node info for other associated properties
            obj.barNodes(nodePosition) = [];
            obj.rgbTriplets(nodePosition,:) = [];
            obj.nodeIDs = [obj.nodeIDs(1:nodePosition-1),obj.nodeIDs(nodePosition+1:end)-1];
            % reset node IDs
            for nodeIdx = obj.nodeIDs
                obj.slidingNodes(nodeIdx).ID = nodeIdx;
            end
        end

        function selectNode(obj,nodePosition)
            % set the active node idx
            obj.activeNodeIdx = nodePosition;

            for i = 1:obj.nNodes
                if i == obj.activeNodeIdx
                    obj.slidingNodes(i).EdgeWidth = 2;
                else
                    obj.slidingNodes(i).EdgeWidth = 1;
                end
            end
        end

    end

    %% node info

    methods

        function nNodes = get.nNodes(obj)
            nNodes = numel(obj.slidingNodes(isvalid(obj.slidingNodes)));
        end

    end

end