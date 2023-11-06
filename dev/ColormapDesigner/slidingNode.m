classdef slidingNode < handle


    properties (Dependent=true)
        Value
        FaceColor
        EdgeColor
        YPosition
        ButtonDownFcn
        ID
    end


    properties (Access = private, Transient, NonCopyable)
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
                Options.YPosition (1,1) = 25.5
                Options.ButtonDownFcn = '';
                Options.ID (1,1) = 1
            end
            % create the primitive line object which will show a single plot marker
            obj.nodeHandle = line(Parent,...
                Options.Value,...
                Options.YPosition,...
                'ButtonDownFcn',Options.ButtonDownFcn,...
                'MarkerFaceColor',Options.FaceColor,...
                'MarkerEdgeColor',Options.EdgeColor,...
                'MarkerSize',10,...
                'Marker','o',...
                'LineWidth',1);
            addprop(obj.nodeHandle,'ID');
            obj.nodeHandle.ID = Options.ID;
        end

        % destructor
        function delete(obj)
            % delete the primitive line object
            delete(obj.nodeHandle)
        end

    end

    methods

        % add a context menu to the node
        function addContextMenu(obj,cm)
            obj.nodeHandle.ContextMenu = cm;
        end

    end

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

        function ID = get.ID(obj)
            ID = obj.nodeHandle.ID;
        end

        function set.ID(obj,val)
            obj.nodeHandle.ID = val;
        end

    end

end