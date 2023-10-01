classdef circularColorbar < handle
% plots a circular colorbar in the uiaxes specified by 'Parent'

    properties(Access=public, Dependent=true)
        % x coordinate of the center of the circular colorbar
        centerX (1,1) double
        % y coordinate of the center of the circular colorbar
        centerY (1,1) double
        % outer radius of the circular colorbar
        outerRadius (1,1) double
        % inner radius of the circular colorbar
        innerRadius (1,1) double
        % matrix of RGB triplets specifying the colors in the colorbar
        Colormap (:,3) double {mustBeInRange(Colormap,0,1)}
        % integer specifying the number of times the colors in Colormap are repeated
        nRepeats (1,1) double
        % interpolated or solid face colors
        colorMode (1,:) char {mustBeMember(colorMode,{'interp','flat'})}
        % font size of the theta labels
        FontSize (1,1) double
        % font color of the theta labels
        FontColor (1,1) double
        % visibility of colorbar
        Visible (1,1) matlab.lang.OnOffSwitchState
        % font name of the theta labels
        FontName (1,1) double
    end

    properties(Access=private)
        user_centerX (1,1) double = 0
        user_centerY (1,1) double = 0
        user_Colormap (:,3) double {mustBeInRange(user_Colormap,0,1)} = hsv(256)
        user_nRepeats (1,1) double = 2
        user_outerRadius (1,1) double = 10
        user_innerRadius (1,1) double = 7
        user_colorMode (1,:) char {mustBeMember(user_colorMode,{'interp','flat'})} = 'interp'
        user_FontSize (1,1) double = 12
        user_FontColor (1,3) double = [1 1 1]
        user_Visible (1,1) matlab.lang.OnOffSwitchState = "on"
        user_FontName (1,:) char = 'Arial'
    end


    properties(Dependent=true, AbortSet=true, Access=private)
        % patch XYData
        patchXYData (2,:) double
        % patch FaceVertexCData
        patchFaceVertexCData (:,3) double
        % nColors in the colormap
        nColors (1,1) double
    end

    properties(Access = private,Transient,NonCopyable)
        cbarPatch (1,1) matlab.graphics.primitive.Patch
        outerOutline (1,1) matlab.graphics.primitive.Line
        innerOutline (1,1) matlab.graphics.primitive.Line
        thetaLabels (4,1) matlab.graphics.primitive.Text
    end

    methods

        
        function obj = circularColorbar(Parent,NameValuePairs)
            % validate inputs and constuct the components

            % constructor input argument validation
            arguments
                Parent (1,1) matlab.ui.control.UIAxes
                NameValuePairs.centerX (1,1) double = 0
                NameValuePairs.centerY (1,1) double = 0
                NameValuePairs.outerRadius (1,1) double = 10
                NameValuePairs.innerRadius (1,1) double = 7
                NameValuePairs.Colormap (:,3) double {mustBeInRange(NameValuePairs.Colormap,0,1)} = hsv(256)
                NameValuePairs.nRepeats (1,1) double = 2
                NameValuePairs.colorMode (1,:) char {mustBeMember(NameValuePairs.colorMode,{'interp','flat'})} = 'interp'
                NameValuePairs.FontSize (1,1) double = 12
                NameValuePairs.FontColor (1,3) double = [1 1 1]
                NameValuePairs.Visible (1,1) matlab.lang.OnOffSwitchState = "on"
                NameValuePairs.FontName (1,:) char = 'Arial'
            end

            % primitive patch to form the violin outlines
            obj.cbarPatch  = patch(Parent,...
                'XData',NaN,...
                'YData',NaN,...
                'HitTest','off',...
                'PickableParts','none',...
                'FaceColor','interp',...
                'EdgeColor','none',...
                'Visible','off');
            % primitive lines to form colorbar outlines
            obj.outerOutline = line(Parent,...
                'XData',NaN,...
                'YData',NaN,...
                'LineWidth',2,...
                'Visible','off',...
                'HitTest','off',...
                'PickableParts','none');
            obj.innerOutline = line(Parent,...
                'XData',NaN,...
                'YData',NaN,...
                'LineWidth',2,...
                'Visible','off',...
                'HitTest','off',...
                'PickableParts','none');
            % primitive text to form theta labels
            for i = 1:4
                obj.thetaLabels(i) = matlab.graphics.primitive.Text(...
                    'Parent',Parent,...
                    'Interpreter','tex',...
                    'Visible','off');
            end

            % obj.centerX = NameValuePairs.centerX;
            % obj.centerY = NameValuePairs.centerY;
            % obj.outerRadius = NameValuePairs.outerRadius;
            % obj.innerRadius = NameValuePairs.innerRadius;
            % obj.Colormap = NameValuePairs.Colormap;
            % obj.nRepeats = NameValuePairs.nRepeats;
            % obj.colorMode = NameValuePairs.colorMode;

            obj.user_centerX = NameValuePairs.centerX;
            obj.user_centerY = NameValuePairs.centerY;
            obj.user_outerRadius = NameValuePairs.outerRadius;
            obj.user_innerRadius = NameValuePairs.innerRadius;
            obj.user_Colormap = NameValuePairs.Colormap;
            obj.user_nRepeats = NameValuePairs.nRepeats;
            obj.user_colorMode = NameValuePairs.colorMode;
            obj.user_FontSize = NameValuePairs.FontSize;
            obj.user_FontColor = NameValuePairs.FontColor;
            obj.user_Visible = NameValuePairs.Visible;
            obj.user_FontName = NameValuePairs.FontName;

            obj.updateAppearance();
            obj.cbarPatch.Visible = obj.Visible;
            obj.innerOutline.Visible = obj.Visible;
            obj.outerOutline.Visible = obj.Visible;
            set(obj.thetaLabels,'Visible',obj.Visible);
        end

        function delete(obj)

            delete(obj.cbarPatch);

        end

    end


    methods

        function [XData,YData,CData] = getXYCData(obj)
        % return X, Y, and CData for trapezoidal patches forming a circular ring
        % return X and YData for primitive lines making up the colorbar outlines

            % number of trapezoidal wedges making up the colorbar
            nWedges = obj.nColors*obj.nRepeats;

            % get the colormap, replicate nRepeats times and copy first color to the end
            cmap = obj.Colormap;
            cmap = [repmat(cmap,obj.nRepeats,1); cmap(1,:)];

            % get the angle of each trapezoid leg
            theta = linspace(0,360,nWedges+1);

            % need to invert theta if y-axis direction is flipped
            if strcmp(obj.cbarPatch.Parent.YDir,'reverse')
                theta = theta*-1;
            end

            % get coordinates for the vertices of the longer bases of the trapezoids
            x1 = obj.outerRadius*cosd(theta)+obj.centerX;
            y1 = obj.outerRadius*sind(theta)+obj.centerY;
        
            % get coordinates for the vertices of the shorter bases of the trapezoids
            x2 = obj.innerRadius*cosd(theta)+obj.centerX;
            y2 = obj.innerRadius*sind(theta)+obj.centerY;

            % x coordinates for each vertex
            XData = [ ...
                x1(1:nWedges); ...   % outer circle, vertex 1
                x2(1:nWedges); ...   % inner circle, vertex 1
                x2(2:nWedges+1); ... % inner circle, vertex 2
                x1(2:nWedges+1) ...  % outer circle, vertex 2
                ];

            % y coordinates for each vertex
            YData = [...
                y1(1:nWedges); ...   % outer circle, vertex 1
                y2(1:nWedges); ...   % inner circle, vertex 1
                y2(2:nWedges+1); ... % inner circle, vertex 2
                y1(2:nWedges+1) ...  % outer circle, vertex 2
                ];

            % color idxs for each vertex
            CDataIdxs = [ ...
                1:nWedges; ...       % outer circle, vertex 1 color idx
                1:nWedges; ...       % inner circle, vertex 1 color idx
                2:nWedges+1; ...     % inner circle, vertex 2 color idx
                2:nWedges+1 ...      % outer circle, vertex 1 color idx
                ];

            % convert color idxs to matrix of RGB triplets
            CData = cmap(CDataIdxs(:),:);

        end

        function [outerXData,outerYData,innerXData,innerYData] = getOutlineXYData(obj)

            % number of trapezoidal wedges making up the colorbar
            nWedges = obj.nColors*obj.nRepeats;

            % get the angle of each trapezoid leg
            theta = linspace(0,360,nWedges+1);

            % get X and YData for inner and outer outlines
            outerXData = obj.outerRadius*cosd(theta)+obj.centerX;
            outerYData = obj.outerRadius*sind(theta)+obj.centerY;
            innerXData = obj.innerRadius*cosd(theta)+obj.centerX;
            innerYData = obj.innerRadius*sind(theta)+obj.centerY;

        end




        function patchXYData = get.patchXYData(obj)

            % theta = linspace(0,360,256+255*(obj.nRepeats-1));
            % 
            % XData1 = (obj.outerRadius * cosd(theta))+obj.centerX;
            % YData1 = (obj.outerRadius * sind(theta))+obj.centerY;
            % 
            % XData2 = (obj.innerRadius * cosd(theta))+obj.centerX;
            % YData2 = (obj.innerRadius * sind(theta))+obj.centerY;
            % 
            % XData = [XData1,XData2];
            % YData = [YData1,YData2];
            % 
            % patchXYData = [XData;YData];


            theta = linspace(0,360,obj.nColors*obj.nRepeats+1);

            XData1 = (obj.outerRadius * cosd(theta))+obj.centerX;
            YData1 = (obj.outerRadius * sind(theta))+obj.centerY;

            XData2 = (obj.innerRadius * cosd(theta))+obj.centerX;
            YData2 = (obj.innerRadius * sind(theta))+obj.centerY;

            XData = [XData1,XData2];
            YData = [YData1,YData2];

            patchXYData = [XData;YData];


        end

        function patchFaceVertexCData = get.patchFaceVertexCData(obj)

            % cmap = obj.Colormap;
            % 
            % if obj.nRepeats == 1
            %     CData = cmap;
            % else
            %     CData = [cmap;repmat(cmap(2:end,:),obj.nRepeats-1,1)];
            % end
            % 
            % patchFaceVertexCData = [CData;CData];

            % cmap = obj.Colormap;
            % 
            % CData = repmat(cmap,obj.nRepeats,1);
            % 
            % patchFaceVertexCData = [CData;CData];


            cmap = obj.Colormap;

            % store the first color of the map
            beginColor = cmap(1,:);

            % replicate it depending on the number of repeats to get colors for each vertex in the outer circle
            CData = [repmat(cmap,obj.nRepeats,1); beginColor];

            % replicate once more for the inner circle
            patchFaceVertexCData = [CData;CData];
        end

        function nColors = get.nColors(obj)
            nColors = size(obj.Colormap,1);
        end

        function centerX = get.centerX(obj)
            centerX = obj.user_centerX;
        end

        function set.centerX(obj,val)
            obj.user_centerX = val;
            obj.updateAppearance();
        end

        function centerY = get.centerY(obj)
            centerY = obj.user_centerY;
        end

        function set.centerY(obj,val)
            obj.user_centerY = val;
            obj.updateAppearance();
        end

        function innerRadius = get.innerRadius(obj)
            innerRadius = obj.user_innerRadius;
        end

        function set.innerRadius(obj,val)
            obj.user_innerRadius = val;
            obj.updateAppearance();
        end

        function outerRadius = get.outerRadius(obj)
            outerRadius = obj.user_outerRadius;
        end

        function set.outerRadius(obj,val)
            obj.user_outerRadius = val;
            obj.updateAppearance();
        end

        function nRepeats = get.nRepeats(obj)
            nRepeats = obj.user_nRepeats;
        end

        function set.nRepeats(obj,val)
            obj.user_nRepeats = val;
            obj.updateAppearance();
        end

        function Colormap = get.Colormap(obj)
            Colormap = obj.user_Colormap;
        end

        function set.Colormap(obj,val)
            obj.user_Colormap = val;
            obj.updateAppearance();
        end

        function colorMode = get.colorMode(obj)
            colorMode = obj.user_colorMode;
        end

        function set.colorMode(obj,val)
            obj.user_colorMode = val;
            obj.updateAppearance();
        end

        function FontSize = get.FontSize(obj)
            FontSize = obj.user_FontSize;
        end

        function set.FontSize(obj,val)
            obj.user_FontSize = val;
            obj.updateAppearance();
        end

        function FontColor = get.FontColor(obj)
            FontColor = obj.user_FontColor;
        end

        function set.FontColor(obj,val)
            obj.user_FontColor = val;
            obj.updateAppearance();
        end

        function Visible = get.Visible(obj)
            Visible = obj.user_Visible;
        end

        function set.Visible(obj,val)
            obj.user_Visible = val;

            obj.cbarPatch.Visible = obj.Visible;
            obj.innerOutline.Visible = obj.Visible;
            obj.outerOutline.Visible = obj.Visible;
            set(obj.thetaLabels,'Visible',obj.Visible);
        end

        function FontName = get.FontName(obj)
            FontName = obj.user_FontName;
        end

        function set.FontName(obj,val)
            obj.user_FontName = val;
            obj.updateAppearance();
        end

    end


    methods (Access=private)

        function updateAppearance(obj)

            % update colorbar
            [XData,YData,CData] = obj.getXYCData();
            obj.cbarPatch.XData = XData;
            obj.cbarPatch.YData = YData;
            obj.cbarPatch.FaceVertexCData = CData;
            obj.cbarPatch.FaceColor = obj.colorMode;

            % update colorbar outlines
            [outerXData,outerYData,innerXData,innerYData] = obj.getOutlineXYData();
            obj.outerOutline.XData = outerXData;
            obj.outerOutline.YData = outerYData;
            obj.innerOutline.XData = innerXData;
            obj.innerOutline.YData = innerYData;

            % need to invert theta if y-axis direction is flipped
            if strcmp(obj.cbarPatch.Parent.YDir,'reverse')
                labelThetas = [0;-pi/2;-pi;-3*pi/2];
                labelVerticalAlignment = {"middle";"top";"middle";"bottom"};
            else
                labelThetas = [0;pi/2;pi;3*pi/2];
                labelVerticalAlignment = {"middle";"bottom";"middle";"top"};
            end


            % labelX = 0.95*obj.innerRadius*cos(labelThetas)+obj.centerX;
            % labelY = 0.95*obj.innerRadius*sin(labelThetas)+obj.centerY;
            % labelText = {"$0$","$\pi/2$","$\pi$","$-\pi/2$"};
            % labelHorizontalAlignment = {"right","center","left","center"};
            % 
            % for i = 1:4
            %     set(obj.thetaLabels(i),...
            %         'Position',[labelX(i) labelY(i) 0],...
            %         'String',labelText{i},...
            %         'HorizontalAlignment',labelHorizontalAlignment{i},...
            %         'VerticalAlignment',labelVerticalAlignment{i})
            % 
            % end


            labelPosition = mat2cell( ...
                [0.95*obj.innerRadius*cos(labelThetas)+obj.centerX, ...
                0.95*obj.innerRadius*sin(labelThetas)+obj.centerY, ...
                zeros(4,1)],ones(4,1),3);
            % 
            % 
            % 
            % labelX = 0.95*obj.innerRadius*cos(labelThetas)+obj.centerX;
            % labelY = 0.95*obj.innerRadius*sin(labelThetas)+obj.centerY;

            labelText = {"0";"\pi/2";"\pi";"-\pi/2"};
            labelHorizontalAlignment = {"right";"center";"left";"center"};

            set(obj.thetaLabels,...
                {'Position'},labelPosition,...
                {'String'},labelText,...
                {'HorizontalAlignment'},labelHorizontalAlignment,...
                {'VerticalAlignment'},labelVerticalAlignment,...
                'FontSize',obj.FontSize,...
                'Color',obj.FontColor,...
                'FontName',obj.FontName);

            % for i = 1:4
            %     set(obj.thetaLabels(i),...
            %         'Position',[labelX(i) labelY(i) 0],...
            %         'String',labelText{i},...
            %         'HorizontalAlignment',labelHorizontalAlignment{i},...
            %         'VerticalAlignment',labelVerticalAlignment{i})
            % 
            % end




        end

    end



end