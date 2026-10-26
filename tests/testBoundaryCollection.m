function tests=testBoundaryCollection
%TESTBOUNDARYCOLLECTION Shared rendering and manager-state regression checks.

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

    tests=functiontests(localfunctions);
end

function setup(testCase)
    fig=uifigure(Visible='off');
    ax=matlabx.ui.axes.ImageAxes(fig,CData=zeros(10,12),Tools={'Boundaries','RectangleSelect'});
    collection=ax.Overlays.createBoundaryCollection();
    vertices={ [1 1;4 1;4 4;1 4], [7 6;10 6;10 9;7 9] };
    hitMap=zeros(10,12,'uint32');
    hitMap(1:4,1:4)=1;
    hitMap(6:9,7:10)=2;
    collection.setData(["first","second"],vertices,HitMap=hitMap, ...
        Colors=[1 0 0;0 1 0]);
    testCase.TestData.Figure=fig;
    testCase.TestData.Axes=ax;
    testCase.TestData.Collection=collection;
end

function teardown(testCase)
    delete(testCase.TestData.Figure);
end

function testSharedGraphicsAndHitMap(testCase)
    ax=testCase.TestData.Axes;
    collection=testCase.TestData.Collection;
    patches=findobj(ax.getAxes(),'Type','patch','-regexp','Tag','^BoundaryCollection');
    verifyNumElements(testCase,patches,4);
    verifyEqual(testCase,sort(ax.Overlays.ids(Type='Boundary')),sort(["first","second"]));
    verifyEqual(testCase,collection.idAt([2 2]),"first");
    verifyEqual(testCase,collection.idAt([8 7]),"second");
    verifyEqual(testCase,collection.idAt([12 1]),"");
end

function testStatePartitionsAndRectangleSelection(testCase)
    ax=testCase.TestData.Axes;
    ax.Overlays.setSelected("first",Type="Boundary");
    selected=findobj(ax.getAxes(),'Tag','BoundaryCollectionSelected');
    verifyEqual(testCase,size(selected.Faces,1),1);
    selectedVertices=selected.Faces(1,isfinite(selected.Faces(1,:)));
    verifyEqual(testCase,unique(selected.FaceVertexCData(selectedVertices,:),'rows'),[1 1 0]);
    ax.Overlays.setActive("second");
    active=findobj(ax.getAxes(),'Tag','BoundaryCollectionActive');
    activeBounds=findobj(ax.getAxes(),'Tag','BoundaryCollectionActiveBounds');
    verifyEqual(testCase,size(active.Faces,1),1);
    activeVertices=active.Faces(1,isfinite(active.Faces(1,:)));
    verifyEqual(testCase,unique(active.FaceVertexCData(activeVertices,:),'rows'),[0.30 0.65 1.00]);
    verifyEqual(testCase,activeBounds.XData,[7 10 10 7 7]);
    verifyEqual(testCase,activeBounds.YData,[6 6 9 9 6]);
    verifyEqual(testCase,activeBounds.Color,testCase.TestData.Collection.ActiveEdgeColor);
    verifyEqual(testCase,activeBounds.LineWidth,testCase.TestData.Collection.ActiveLineWidth);
    verifyEqual(testCase,activeBounds.HitTest,matlab.lang.OnOffSwitchState.off);
    ax.Overlays.setSelected(["first","second"],Type="Boundary");
    verifyEqual(testCase,size(selected.Faces,1),2);
    verifyEmpty(testCase,active.Faces);
    verifyEqual(testCase,selected.LineWidth,testCase.TestData.Collection.SelectionLineWidth);
    verifyEqual(testCase,active.LineWidth,testCase.TestData.Collection.ActiveLineWidth);
    testCase.TestData.Collection.ShowActiveEdgeWhenSelected=true;
    verifyEqual(testCase,size(active.Faces,1),1);
    testCase.TestData.Collection.ShowActiveEdgeWhenSelected=false;
    verifyEmpty(testCase,active.Faces);
    testCase.TestData.Collection.ActiveEdgeColor=[];
    verifyEqual(testCase,activeBounds.Color,testCase.TestData.Collection.SelectionEdgeColor);
    ax.Overlays.deselect("second");
    verifyEqual(testCase,activeBounds.Color,[0 1 0]);
    activeVertices=active.Faces(1,isfinite(active.Faces(1,:)));
    verifyEqual(testCase,unique(active.FaceVertexCData(activeVertices,:),'rows'),[0 1 0]);
    ax.Overlays.setHover("first");
    hovered=findobj(ax.getAxes(),'Tag','BoundaryCollectionHovered');
    verifyEqual(testCase,size(hovered.Faces,1),1);
    verifyEmpty(testCase,selected.Faces);
    base=findobj(ax.getAxes(),'Tag','BoundaryCollectionBase');
    verifyEqual(testCase,size(base.Faces,1),2);
    verifyEqual(testCase,base.HitTest,matlab.lang.OnOffSwitchState.on);
    verifyEqual(testCase,active.HitTest,matlab.lang.OnOffSwitchState.off);
    verifyEqual(testCase,hovered.HitTest,matlab.lang.OnOffSwitchState.off);
    ax.Overlays.clearActive();
    verifyTrue(testCase,all(isnan(activeBounds.XData)));
    verifyTrue(testCase,all(isnan(activeBounds.YData)));
    verifyEqual(testCase,ax.Overlays.idsInsideRectangle([0 5 0 5],Type="Boundary"),"first");
    ax.Tools.Boundaries.disable();
    verifyEmpty(testCase,ax.Overlays.idsInsideRectangle([0 5 0 5],Type="Boundary"));
end

function testBatchRemovalReindexesHitMap(testCase)
    ax=testCase.TestData.Axes;
    collection=testCase.TestData.Collection;
    ax.Overlays.remove("first");
    verifyEqual(testCase,collection.IDs,"second");
    verifyEqual(testCase,collection.idAt([8 7]),"second");
    verifyEqual(testCase,collection.idAt([2 2]),"");
end

function testValidation(testCase)
    collection=testCase.TestData.Collection;
    verifyError(testCase,@() collection.setData(["a","b"],{[1 1;2 1;1 2],[3 3;4 3;3 4]}, ...
        HitMap=ones(2,'uint32')), ...
        'matlabx:ui:axes:BoundaryCollection:InvalidHitMapSize');
end

function testBoundingBoxDisplayAndSmallestHitWins(testCase)
    ax=testCase.TestData.Axes;
    collection=testCase.TestData.Collection;
    collection.setData(["large","small"], ...
        {[1 1;9 1;9 9;1 9],[4 4;6 4;6 6;4 6]}, ...
        HitMap=zeros(10,12,'uint32'),Colors=[1 0 0;0 1 0]);
    collection.DisplayGeometry="boundingbox";
    activeBounds=findobj(ax.getAxes(),'Tag','BoundaryCollectionActiveBounds');
    ax.Overlays.setActive("small");
    verifyTrue(testCase,all(isnan(activeBounds.XData)));
    active=findobj(ax.getAxes(),'Tag','BoundaryCollectionActive');
    verifyEqual(testCase,size(active.Faces,1),1);
    ax.Overlays.setSelected("small",Type="Boundary");
    verifyEmpty(testCase,active.Faces);
    ax.Overlays.setHover("small");
    selected=findobj(ax.getAxes(),'Tag','BoundaryCollectionSelected');
    hovered=findobj(ax.getAxes(),'Tag','BoundaryCollectionHovered');
    verifyEmpty(testCase,selected.Faces);
    verifyEqual(testCase,size(hovered.Faces,1),1);
    verifyEqual(testCase,collection.idAt([2 2]),"large");
    verifyEqual(testCase,collection.idAt([5 5]),"small");
    collection.HitTestGeometry="hitmap";
    verifyEqual(testCase,collection.idAt([5 5]),"");
    collection.HitTestGeometry="display";
    verifyEqual(testCase,collection.idAt([5 5]),"small");
end

function testUniformBaseColorDoesNotReplaceBoundaryColors(testCase)
    ax=testCase.TestData.Axes;
    collection=testCase.TestData.Collection;
    base=findobj(ax.getAxes(),'Tag','BoundaryCollectionBase');
    collection.EdgeColor=[0.2 0.4 0.8];
    collection.UsePerBoundaryColors=false;
    used=unique(base.FaceVertexCData(unique(base.Faces(isfinite(base.Faces))),:),'rows');
    verifyEqual(testCase,used,[0.2 0.4 0.8]);
    verifyEqual(testCase,ax.Overlays.get("first").Color,[1 0 0]);
    verifyEqual(testCase,ax.Overlays.get("second").Color,[0 1 0]);
    collection.UsePerBoundaryColors=true;
    firstVertices=base.Faces(1,isfinite(base.Faces(1,:)));
    secondVertices=base.Faces(2,isfinite(base.Faces(2,:)));
    verifyEqual(testCase,unique(base.FaceVertexCData(firstVertices,:),'rows'),[1 0 0]);
    verifyEqual(testCase,unique(base.FaceVertexCData(secondVertices,:),'rows'),[0 1 0]);
end
