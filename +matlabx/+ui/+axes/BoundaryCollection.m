classdef BoundaryCollection < handle
%BOUNDARYCOLLECTION Batch renderer for individually managed boundaries.
%
%   Each boundary remains a first-class ImageAxes overlay with a string ID.
%   The collection renders all boundaries with four shared patch primitives:
%   one stable base layer and selected, active, and hovered accents. HitMap is a
%   Y-by-X integer matrix whose value K maps directly to IDs(K); zero is
%   background and the numeric indices are disposable renderer data.

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

    properties (SetObservable, AbortSet)
        Visible (1,1) matlab.lang.OnOffSwitchState = "on"
        UsePerBoundaryColors (1,1) logical = true
        EdgeColor (1,3) double {mustBeBetween(EdgeColor,0,1)} = [1 1 1]
        EdgeAlpha (1,1) double {mustBeBetween(EdgeAlpha,0,1)} = 1
        LineWidth (1,1) double {mustBePositive} = 0.5
        HoverEdgeColor = [1 1 1]
        HoverEdgeAlpha (1,1) double {mustBeBetween(HoverEdgeAlpha,0,1)} = 1
        HoverLineWidth (1,1) double {mustBePositive} = 1
        SelectionEdgeColor = [1 1 0]
        SelectionEdgeAlpha (1,1) double {mustBeBetween(SelectionEdgeAlpha,0,1)} = 1
        SelectionLineWidth (1,1) double {mustBePositive} = 2
        ActiveEdgeColor = [0.30 0.65 1.00]
        ActiveEdgeAlpha (1,1) double {mustBeBetween(ActiveEdgeAlpha,0,1)} = 1
        ActiveLineWidth (1,1) double {mustBePositive} = 1
        ShowActiveEdgeWhenSelected (1,1) logical = false
        DisplayGeometry (1,1) string {mustBeMember(DisplayGeometry,["boundary","boundingbox"])} = "boundary"
        HitTestGeometry (1,1) string {mustBeMember(HitTestGeometry,["auto","hitmap","display"])} = "auto"
        HitTestRadius (1,1) double {mustBeInteger,mustBeNonnegative} = 1
    end

    properties (SetAccess=private)
        Host matlabx.ui.axes.ImageAxes
        IDs (1,:) string = string.empty(1,0)
        HitMap = zeros(0,0,'uint32')
    end

    properties (Access=private)
        Updating (1,1) logical = false
        GeometryDirty (1,1) logical = true
        StateDirty (1,1) logical = true
        PackedVertices (:,2) double = zeros(0,2)
        FaceRows double = zeros(0,0)
    end

    properties (Access=private, Transient, NonCopyable)
        StatePatches matlab.graphics.primitive.Patch = matlab.graphics.primitive.Patch.empty()
        ActiveBoundsLine matlab.graphics.primitive.Line = matlab.graphics.primitive.Line.empty()
        Listeners event.listener = event.listener.empty()
    end

    methods
        function obj = BoundaryCollection(host)
        %BOUNDARYCOLLECTION Create an empty collection attached to ImageAxes.
            obj.Host = host;
            ax = host.getAxes();
            tags = ["Base","Selected","Active","Hovered"];
            for i = 1:4
                obj.StatePatches(i) = patch(ax, ...
                    Faces=zeros(0,0), Vertices=zeros(0,2), ...
                    FaceColor="none", EdgeColor="flat", ...
                    FaceVertexCData=zeros(0,3), CDataMapping="direct", ...
                    HitTest="on", PickableParts="all", ...
                    Tag="BoundaryCollection"+tags(i));
                setappdata(obj.StatePatches(i),"matlabxBoundaryCollection",obj);
            end
            % Keep one stable graphics target beneath the visual state
            % accents. Moving a face between pickable patches during hover
            % can invalidate the next routed target and make hover oscillate.
            set(obj.StatePatches(2:4),HitTest="off",PickableParts="none");
            obj.ActiveBoundsLine = line(ax,NaN,NaN, ...
                HitTest="off",PickableParts="none", ...
                Tag="BoundaryCollectionActiveBounds");
            manager = host.Overlays;
            obj.Listeners(end+1) = addlistener(manager,'ActiveChanged',@(~,~) obj.onManagerStateChanged());
            obj.Listeners(end+1) = addlistener(manager,'HoverChanged',@(~,~) obj.onManagerStateChanged());
            obj.Listeners(end+1) = addlistener(manager,'SelectionChanged',@(~,~) obj.onManagerStateChanged());
            obj.Listeners(end+1) = addlistener(manager,'OverlayRemoved',@(~,~) obj.onManagerMembershipChanged());
            obj.Listeners(end+1) = addlistener(host,'OverlaysVisible','PostSet',@(~,~) obj.refresh());
            obj.Listeners(end+1) = addlistener(obj, ...
                {'Visible','UsePerBoundaryColors','EdgeColor','EdgeAlpha','LineWidth', ...
                'HoverEdgeColor','HoverEdgeAlpha', ...
                'HoverLineWidth','SelectionEdgeColor','SelectionEdgeAlpha', ...
                'SelectionLineWidth','ActiveEdgeColor','ActiveEdgeAlpha','ActiveLineWidth', ...
                'ShowActiveEdgeWhenSelected'}, ...
                'PostSet',@(~,~) obj.refresh());
            obj.Listeners(end+1) = addlistener(obj,'DisplayGeometry','PostSet', ...
                @(~,~) obj.requestGeometryRefresh());
            obj.refresh();
        end

        function delete(obj)
        %DELETE Remove collection graphics and its logical overlay entries.
            for k = 1:numel(obj)
                delete(obj(k).Listeners(isvalid(obj(k).Listeners)));
                obj(k).Listeners = event.listener.empty();
                if ~isempty(obj(k).Host) && isvalid(obj(k).Host)
                    ids = obj(k).IDs(arrayfun(@(id) obj(k).Host.Overlays.has(id),obj(k).IDs));
                    obj(k).Host.Overlays.removeMany(ids);
                end
                delete(obj(k).StatePatches(isgraphics(obj(k).StatePatches)));
                obj(k).StatePatches = matlab.graphics.primitive.Patch.empty();
                delete(obj(k).ActiveBoundsLine(isgraphics(obj(k).ActiveBoundsLine)));
                obj(k).ActiveBoundsLine = matlab.graphics.primitive.Line.empty();
            end
        end

        function setData(obj, ids, vertices, opts)
        %SETDATA Atomically reconcile UUIDs, loops, colors, and the hit map.
            arguments
                obj (1,1)
                ids
                vertices
                opts.HitMap = []
                opts.Colors double = zeros(0,3)
                opts.Labels = string.empty(1,0)
            end
            ids = string(ids(:).');
            if numel(unique(ids)) ~= numel(ids) || any(strlength(ids)==0)
                error('matlabx:ui:axes:BoundaryCollection:InvalidIDs', ...
                    'Boundary IDs must be unique, nonempty text values.');
            end
            if ~iscell(vertices) || numel(vertices) ~= numel(ids)
                error('matlabx:ui:axes:BoundaryCollection:InvalidVertices', ...
                    'Vertices must be one cell array entry per boundary ID.');
            end
            colors = opts.Colors;
            if isempty(colors), colors = repmat([1 1 1],numel(ids),1); end
            validateattributes(colors,{'double'},{'size',[numel(ids),3],'>=',0,'<=',1});
            labels = string(opts.Labels);
            if isempty(labels), labels = strings(size(ids)); else, labels = labels(:).'; end
            if numel(labels) ~= numel(ids)
                error('matlabx:ui:axes:BoundaryCollection:InvalidLabels', ...
                    'Labels must contain one value per boundary ID.');
            end
            hitMap = obj.validateHitMap(opts.HitMap,numel(ids));

            obj.Updating = true;
            guard = onCleanup(@() obj.finishUpdate());
            old = obj.IDs;
            obj.Host.Overlays.removeMany(old(~ismember(old,ids)));
            for i = 1:numel(ids)
                existing = obj.Host.Overlays.get(ids(i));
                if isempty(existing)
                    item = matlabx.ui.axes.overlays.Boundary(obj.Host,obj, ...
                        ID=ids(i),Vertices=vertices{i},Color=colors(i,:),Label=labels(i));
                    obj.Host.Overlays.add(item);
                elseif isa(existing,'matlabx.ui.axes.overlays.Boundary') ...
                        && existing.Collection == obj
                    existing.Label = labels(i);
                    existing.setGeometry(vertices{i},colors(i,:));
                else
                    error('matlabx:ui:axes:BoundaryCollection:DuplicateID', ...
                        'Overlay ID "%s" belongs to another overlay.',ids(i));
                end
            end
            obj.IDs = ids;
            obj.HitMap = hitMap;
            obj.GeometryDirty = true;
            obj.StateDirty = true;
            clear guard;
        end

        function id = idAt(obj, xy)
        %IDAT Resolve an image coordinate using the configured hit geometry.
            id = "";
            if isempty(xy) || any(~isfinite(xy)), return; end
            mode=obj.HitTestGeometry;
            if mode=="auto"
                if obj.DisplayGeometry=="boundingbox", mode="display"; else, mode="hitmap"; end
            end
            if mode=="hitmap"
                if isempty(obj.HitMap), return; end
                x = round(xy(1)); y = round(xy(2));
                if x >= 1 && x <= size(obj.HitMap,2) && y >= 1 && y <= size(obj.HitMap,1)
                    value = double(obj.HitMap(y,x));
                    if value == 0 && obj.HitTestRadius > 0
                        r = obj.HitTestRadius;
                        ys = max(1,y-r):min(size(obj.HitMap,1),y+r);
                        xs = max(1,x-r):min(size(obj.HitMap,2),x+r);
                        block = obj.HitMap(ys,xs);
                        [ry,rx] = find(block>0);
                        if ~isempty(ry)
                            d = hypot(double(xs(rx)-x),double(ys(ry)-y));
                            [~,j] = min(d);
                            value = double(block(ry(j),rx(j)));
                        end
                    end
                    if value >= 1 && value <= numel(obj.IDs)
                        candidate = obj.IDs(value);
                        if obj.Host.Overlays.has(candidate), id = candidate; end
                    end
                end
                return
            end
            id = obj.displayGeometryHit(xy);
        end

        function tf = ownsTarget(obj, target)
        %OWNSTARGET True when target is one of the four shared patches.
            tf = ~isempty(target) && any(obj.StatePatches(isgraphics(obj.StatePatches))==target);
        end

        function requestGeometryRefresh(obj)
        %REQUESTGEOMETRYREFRESH Mark packed topology stale.
            obj.GeometryDirty = true;
            obj.StateDirty = true;
            if ~obj.Updating, obj.refresh(); end
        end

        function requestStateRefresh(obj)
        %REQUESTSTATEREFRESH Mark state partitioning stale.
            obj.StateDirty = true;
        end

        function refresh(obj)
        %REFRESH Rebuild stale topology and apply four state partitions.
            if obj.Updating || numel(obj.StatePatches)~=4 ...
                    || ~all(isgraphics(obj.StatePatches))
                return
            end
            obj.pruneMissingIDs();
            if obj.GeometryDirty, obj.packGeometry(); end
            obj.renderStates();
            obj.StateDirty = false;
        end
    end

    methods (Access=private)
        function finishUpdate(obj)
            obj.Updating = false;
            obj.refresh();
        end

        function map = validateHitMap(obj,map,n)
            if isempty(map), map = zeros(0,0,'uint32'); return; end
            validateattributes(map,{'numeric','logical'},{'2d','real','finite','nonnegative'});
            if any(map(:)~=fix(map(:))) || any(map(:)>n)
                error('matlabx:ui:axes:BoundaryCollection:InvalidHitMap', ...
                    'HitMap values must be integer indices from zero through numel(IDs).');
            end
            imageSize=obj.Host.RenderSourceSize;
            if numel(imageSize)<2 || size(map,1)~=imageSize(1) || size(map,2)~=imageSize(2)
                error('matlabx:ui:axes:BoundaryCollection:InvalidHitMapSize', ...
                    'HitMap must match the displayed image height and width.');
            end
            map = uint32(map);
        end

        function pruneMissingIDs(obj)
            keep = arrayfun(@(id) obj.Host.Overlays.has(id),obj.IDs);
            if all(keep), return; end
            oldToNew = zeros(1,numel(keep),'uint32');
            oldToNew(keep) = uint32(1:sum(keep));
            if ~isempty(obj.HitMap)
                lookup = [uint32(0),oldToNew];
                obj.HitMap = reshape(lookup(double(obj.HitMap)+1),size(obj.HitMap));
            end
            obj.IDs = obj.IDs(keep);
            obj.GeometryDirty = true;
        end

        function packGeometry(obj)
            n = numel(obj.IDs);
            counts = zeros(1,n);
            items = cell(1,n);
            for i=1:n
                items{i}=obj.Host.Overlays.get(obj.IDs(i));
                if obj.DisplayGeometry=="boundingbox"
                    counts(i)=4;
                else
                    counts(i)=size(items{i}.Vertices,1);
                end
            end
            obj.PackedVertices = zeros(sum(counts),2);
            obj.FaceRows = NaN(n,max([counts 0]));
            first=1;
            for i=1:n
                last=first+counts(i)-1;
                if obj.DisplayGeometry=="boundingbox"
                    b=items{i}.Bounds;
                    obj.PackedVertices(first:last,:)=[b(1),b(3);b(2),b(3);b(2),b(4);b(1),b(4)];
                else
                    obj.PackedVertices(first:last,:)=items{i}.Vertices;
                end
                obj.FaceRows(i,1:counts(i))=first:last;
                first=last+1;
            end
            obj.GeometryDirty=false;
        end

        function renderStates(obj)
            % The base patch is also the stable hit surface and therefore
            % always contains every visible boundary. State patches repeat
            % affected faces above it as non-pickable visual accents. This
            % avoids changing the graphics object beneath the cursor when a
            % boundary enters or leaves hover.
            groups = cell(1,4); colors = cell(1,4);
            for i=1:numel(obj.IDs)
                item=obj.Host.Overlays.get(obj.IDs(i));
                if isempty(item) || item.Visible=="off" || ...
                        ~item.appliesToView(obj.Host.C,obj.Host.Z,obj.Host.T,obj.Host.ShowComposite)
                    continue
                end
                groups{1}(end+1)=i; %#ok<AGROW>
                baseColor=obj.baseColor(item);
                colors{1}(end+1,:)=baseColor; %#ok<AGROW>

                % Hover is the authoritative transient boundary style. Do
                % not leave wider selected/active strokes visible beneath it.
                if item.Selected && ~item.Hovered
                    groups{2}(end+1)=i; %#ok<AGROW>
                    color=baseColor;
                    if ~isempty(obj.SelectionEdgeColor), color=obj.SelectionEdgeColor; end
                    colors{2}(end+1,:)=color; %#ok<AGROW>
                end
                if item.Active && ~item.Hovered ...
                        && (~item.Selected || obj.ShowActiveEdgeWhenSelected)
                    groups{3}(end+1)=i; %#ok<AGROW>
                    color=baseColor;
                    if item.Selected && ~isempty(obj.SelectionEdgeColor), color=obj.SelectionEdgeColor; end
                    if ~isempty(obj.ActiveEdgeColor), color=obj.ActiveEdgeColor; end
                    colors{3}(end+1,:)=color; %#ok<AGROW>
                end
                if item.Hovered
                    groups{4}(end+1)=i; %#ok<AGROW>
                    color=baseColor;
                    if item.Selected && ~isempty(obj.SelectionEdgeColor), color=obj.SelectionEdgeColor; end
                    if item.Active && ~isempty(obj.ActiveEdgeColor), color=obj.ActiveEdgeColor; end
                    if ~isempty(obj.HoverEdgeColor), color=obj.HoverEdgeColor; end
                    colors{4}(end+1,:)=color; %#ok<AGROW>
                end
            end
            widths=[obj.LineWidth,obj.SelectionLineWidth,obj.ActiveLineWidth,obj.HoverLineWidth];
            alphas=[obj.EdgeAlpha,obj.SelectionEdgeAlpha,obj.ActiveEdgeAlpha,obj.HoverEdgeAlpha];
            visible=obj.Visible=="on" && obj.Host.OverlaysVisible=="on";
            for g=1:4
                idx=groups{g};
                vertexColors=zeros(size(obj.PackedVertices,1),3);
                if isempty(idx)
                    faces=zeros(0,size(obj.FaceRows,2));
                else
                    faces=obj.FaceRows(idx,:);
                    % EdgeColor="flat" still requires one CData row per
                    % packed vertex. Repeat each face's color over the vertices
                    % it references; unused vertices can retain zero CData.
                    for j=1:numel(idx)
                        vertexIndices=faces(j,isfinite(faces(j,:)));
                        vertexColors(vertexIndices,:)=repmat(colors{g}(j,:), ...
                            numel(vertexIndices),1);
                    end
                end
                set(obj.StatePatches(g),Vertices=obj.PackedVertices,Faces=faces, ...
                    FaceVertexCData=vertexColors,EdgeColor="flat",LineWidth=widths(g), ...
                    EdgeAlpha=alphas(g),Visible=matlab.lang.OnOffSwitchState(visible && ~isempty(idx)));
            end
            obj.renderActiveBounds(visible);
        end

        function renderActiveBounds(obj,visible)
            % Draw one noninteractive box around the active boundary.
            x=NaN; y=NaN; color=obj.ActiveEdgeColor;
            id=obj.Host.Overlays.getActiveID(Type="Boundary");
            item=obj.Host.Overlays.get(id);
            % In bounding-box display the shared state patches already draw
            % this exact geometry. Keeping a second line would bypass hover
            % and active/selection composition policies.
            if obj.DisplayGeometry=="boundary" && visible ...
                    && ~isempty(item) && item.Collection==obj ...
                    && item.Visible=="on" ...
                    && item.appliesToView(obj.Host.C,obj.Host.Z,obj.Host.T,obj.Host.ShowComposite)
                bounds=item.Bounds;
                x=[bounds(1),bounds(2),bounds(2),bounds(1),bounds(1)];
                y=[bounds(3),bounds(3),bounds(4),bounds(4),bounds(3)];
                if isempty(color)
                    color=obj.baseColor(item);
                    if item.Selected && ~isempty(obj.SelectionEdgeColor)
                        color=obj.SelectionEdgeColor;
                    end
                end
            end
            if isempty(color), color=[1 1 1]; end
            set(obj.ActiveBoundsLine,XData=x,YData=y,Color=color, ...
                LineWidth=obj.ActiveLineWidth, ...
                Visible=matlab.lang.OnOffSwitchState(visible && all(isfinite(x))));
        end

        function id = displayGeometryHit(obj,xy)
            id="";
            if obj.DisplayGeometry=="boundingbox"
                candidates=zeros(1,0);
                areas=zeros(1,0);
                for i=1:numel(obj.IDs)
                    item=obj.Host.Overlays.get(obj.IDs(i));
                    if isempty(item) || item.Visible=="off" ...
                            || ~item.appliesToView(obj.Host.C,obj.Host.Z,obj.Host.T,obj.Host.ShowComposite)
                        continue
                    end
                    b=item.Bounds;
                    if xy(1)>=b(1) && xy(1)<=b(2) && xy(2)>=b(3) && xy(2)<=b(4)
                        candidates(end+1)=i; %#ok<AGROW>
                        areas(end+1)=(b(2)-b(1))*(b(4)-b(3)); %#ok<AGROW>
                    end
                end
                if ~isempty(candidates)
                    [~,j]=min(areas);
                    id=obj.IDs(candidates(j));
                end
                return
            end
            for i=numel(obj.IDs):-1:1
                item=obj.Host.Overlays.get(obj.IDs(i));
                if isempty(item) || item.Visible=="off" ...
                        || ~item.appliesToView(obj.Host.C,obj.Host.Z,obj.Host.T,obj.Host.ShowComposite)
                    continue
                end
                b=item.Bounds;
                if xy(1)<b(1)||xy(1)>b(2)||xy(2)<b(3)||xy(2)>b(4), continue; end
                if inpolygon(xy(1),xy(2),item.Vertices(:,1),item.Vertices(:,2))
                    id=item.ID; return
                end
            end
        end

        function color=baseColor(obj,item)
            if obj.UsePerBoundaryColors
                color=item.Color;
            else
                color=obj.EdgeColor;
            end
        end

        function onManagerStateChanged(obj)
            obj.StateDirty=true;
            obj.refresh();
        end

        function onManagerMembershipChanged(obj)
            if obj.Updating, return; end
            obj.GeometryDirty=true;
            obj.refresh();
        end
    end
end
