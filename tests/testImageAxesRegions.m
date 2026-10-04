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

function tests = testImageAxesRegions
%TESTIMAGEAXESREGIONS Mask display and polygon interaction regression checks.
    tests = functiontests(localfunctions);
end

function setup(testCase)
    fig = uifigure('Visible','off');
    testCase.TestData.Figure = fig;
    testCase.TestData.Axes = matlabx.ui.axes.ImageAxes(fig, ...
        'CData', reshape(1:120,10,12), 'Tools', {'Polygon','RectangleSelect'});
end

function teardown(testCase)
    delete(testCase.TestData.Figure);
end

function testMaskDisplay(testCase)
    ax = testCase.TestData.Axes;
    h = findobj(ax.getAxes(), 'Type','image');
    original = h.CData;
    mask = false(10,12);
    mask(3:6,4:8) = true;
    ax.Mask = mask;
    verifyEqual(testCase, h.AlphaData, 1);
    ax.MaskEnabled = 'on';
    verifyEqual(testCase, h.AlphaData, double(mask));
    verifyEqual(testCase, h.CData, original);
    ax.toggleMask();
    verifyEqual(testCase, h.AlphaData, 1);
    verifyEqual(testCase, ax.Mask, mask);
    ax.toggleMask();
    ax.Mask = [];
    verifyEqual(testCase, h.AlphaData, 1);
end

function testMaskValidationAndReplacement(testCase)
    ax = testCase.TestData.Axes;
    verifyError(testCase, @() set(ax,'Mask',ones(10,12)), ...
        'matlabx:ui:axes:ImageAxes:InvalidMask');
    verifyError(testCase, @() set(ax,'Mask',true(12,10)), ...
        'matlabx:ui:axes:ImageAxes:InvalidMask');
    ax.Mask = true(10,12);
    ax.MaskEnabled = 'on';
    ax.CData = zeros(10,12,3,'uint8');
    verifyEmpty(testCase, ax.Mask);
    ax.Mask = false(10,12);
    h = findobj(ax.getAxes(), 'Type','image');
    verifyEqual(testCase, h.AlphaData, zeros(10,12));
    ax.ImageData = matlabx.image.Image5D.fromComponents(zeros(5,6));
    verifyEmpty(testCase, ax.Mask);
    verifyEqual(testCase, h.AlphaData, 1);
end

function testMaskAcrossViews(testCase)
    ax = testCase.TestData.Axes;
    ax.ImageData = matlabx.image.Image5D.fromComponents({rand(10,12,1,2), rand(10,12,1,2)});
    ax.Mask = false(10,12);
    ax.Mask(2:5,3:7) = true;
    ax.MaskEnabled = 'on';
    h = findobj(ax.getAxes(),'Type','image');
    ax.C = 2;
    ax.Z = 2;
    verifyEqual(testCase, h.AlphaData, double(ax.Mask));
    ax.ShowComposite = 'on';
    verifyEqual(testCase, size(h.CData), [10 12 3]);
    verifyEqual(testCase, h.AlphaData, double(ax.Mask));
end

function testPolygonGeometry(testCase)
    ax = testCase.TestData.Axes;
    vertices = [0 0; 4 0; 2 2; 0 2];
    p = ax.Overlays.add('Polygon','Vertices',vertices,'ID','region');
    patch = findobj(ax.getAxes(), 'Tag','OverlayPolygon');
    verifyEqual(testCase,numel(patch),1);
    verifyEqual(testCase,patch.Type,'patch');
    verifyEqual(testCase,patch.Vertices,vertices);
    verifyEqual(testCase,patch.Faces,1:4);
    verifyEqual(testCase,p.Center,[14/9 8/9],'AbsTol',1e-12);
    verifyEqual(testCase,ax.Overlays.idsInsideRectangle([1 2 0 1]),"region");
    % Closure, duplicate vertices, and winding are app-owned and preserved.
    closed = [vertices; vertices(1,:)];
    verifyWarningFree(testCase,@() set(p,'Vertices',closed));
    verifyEqual(testCase,p.Vertices,closed);
    verifyEqual(testCase,p.Center,[14/9 8/9],'AbsTol',1e-12);
    p.Vertices = flipud(closed) + 1e6;
    verifyEqual(testCase,p.Center,[14/9 8/9]+1e6,'AbsTol',1e-9);
    p.Vertices = [1 1; 2 2; 3 3];
    verifyEqual(testCase,p.Center,[2 2]);
    % Self-touching contours must not trigger normalization warnings.
    raw = [0 0; 4 0; 2 2; 4 4; 0 4; 2 2; 0 0];
    verifyWarningFree(testCase,@() set(p,'Vertices',raw));
    verifyEqual(testCase,patch.Vertices,raw);
    p.Selected = true;
    verifyEqual(testCase,patch.LineWidth,p.SelectionLineWidth);
    p.Visible = 'off';
    verifyEqual(testCase,string(patch.Visible),"off");
    p.Vertices = zeros(0,2);
    verifyEmpty(testCase,patch.Faces);
    verifyTrue(testCase,all(isnan(p.Center)));
end

function testPolygonSelectionAndDeletion(testCase)
    ax = testCase.TestData.Axes;
    tool = ax.Tools.Polygon;
    tool.addPolygon('a',[1 1; 3 1; 3 3; 1 3]);
    tool.addPolygon('b',[6 6; 8 6; 8 8; 6 8]);
    box = ax.Overlays.add('Box','ID','box','Center',[5 5]);
    ax.Overlays.select(box.ID);
    tool.PolygonDeletedFcn = @(~,data) setappdata(ax,'DeletedPolygon',data.ID);
    tool.PolygonSelectionChangedFcn = @(~,data) setappdata(ax,'PolygonSelection',data.IDs);
    tool.selectAllPolygons();
    verifyEqual(testCase, sort(tool.getSelectedPolygonIDs()), ["a" "b"]);
    verifyEqual(testCase, sort(getappdata(ax,'PolygonSelection')), ["a" "b"]);
    tool.clearPolygonSelection();
    verifyEqual(testCase, ax.Overlays.getSelectedIDs(), "box");
    tool.setActivePolygonID('a');
    tool.deleteActivePolygon();
    verifyEqual(testCase, getappdata(ax,'DeletedPolygon'), "a");
    verifyFalse(testCase, ax.Overlays.has('a'));
    verifyEqual(testCase, ax.Overlays.getActiveID(), "");
    tool.selectAllPolygons();
    tool.deleteSelectedPolygons();
    verifyEmpty(testCase, ax.Overlays.ids(Type="Polygon"));
    verifyTrue(testCase, ax.Overlays.has('box'));
end

function testPolygonClickAndMarqueeRouting(testCase)
    ax = testCase.TestData.Axes;
    ax.Overlays.add('Polygon','ID','a','Vertices',[1 1; 3 1; 3 3; 1 3]);
    target = findobj(ax.getAxes(),'Tag','OverlayPolygon');
    E = matlabx.ui.interaction.HubEvent(testCase.TestData.Figure,target,'Down',[]);
    ax.routeEventToTools(E);
    verifyEqual(testCase, ax.Overlays.getActiveID(), "a");
    verifyTrue(testCase, E.StopPropagation);
    ax.Overlays.clearActive();
    ax.Tools.RectangleSelect.enable();
    E = matlabx.ui.interaction.HubEvent(testCase.TestData.Figure,target,'Down',[]);
    ax.Tools.Polygon.onPassiveDown(E);
    verifyFalse(testCase, E.StopPropagation);
    verifyEqual(testCase, ax.Overlays.getActiveID(), "");
    ax.Tools.Polygon.PolygonSelectionChangedFcn = ...
        @(~,data) setappdata(ax,'MarqueeSelection',data.IDs);
    % Exercise the manager query and selection used by RectangleSelect.
    ids = ax.Overlays.idsInsideRectangle([1 4 1 4], Type="Polygon");
    ax.Overlays.setSelected(ids, Type="Polygon");
    verifyEqual(testCase, ax.Tools.Polygon.getSelectedPolygonIDs(), "a");
    verifyEqual(testCase, getappdata(ax,'MarqueeSelection'), "a");
end

function testToolRemovalPreservesPolygons(testCase)
    ax = testCase.TestData.Axes;
    p = ax.Overlays.add('Polygon','ID','a','Vertices',[1 1; 3 1; 3 3; 1 3]);
    ax.Tools = {'RectangleSelect'};
    verifyTrue(testCase, isvalid(p));
    verifyTrue(testCase, ax.Overlays.has('a'));
end

function testDisplayToggleTools(testCase)
    ax = testCase.TestData.Axes;
    ax.loadTools({'Mask','Overlays'});
    ax.installTool('Mask');
    ax.installTool('Overlays');
    verifyFalse(testCase, ax.Tools.Mask.Enabled);
    verifyTrue(testCase, ax.Tools.Overlays.Enabled);
    ax.Tools.Mask.enable(); % No mask is a valid, harmless state.
    verifyEqual(testCase, string(ax.MaskEnabled), "on");
    h = findobj(ax.getAxes(),'Type','image');
    verifyEqual(testCase, h.AlphaData, 1);
    ax.MaskEnabled = 'off';
    verifyFalse(testCase, ax.Tools.Mask.Enabled);
    ax.toggleMask();
    verifyTrue(testCase, ax.Tools.Mask.Enabled);
    ax.Tools.Mask.disable();
    verifyEqual(testCase, string(ax.MaskEnabled), "off");
    ax.Tools.Overlays.disable();
    verifyEqual(testCase, string(ax.OverlaysVisible), "off");
    ax.toggleOverlays();
    verifyTrue(testCase, ax.Tools.Overlays.Enabled);
    ax.OverlaysVisible = 'off';
    verifyFalse(testCase, ax.Tools.Overlays.Enabled);
    ax.Tools.Overlays.enable();
    verifyEqual(testCase, string(ax.OverlaysVisible), "on");
end

function testGlobalOverlayVisibility(testCase)
    ax = testCase.TestData.Axes;
    p = ax.Overlays.add('Polygon','ID','p','Vertices',[1 1; 3 1; 3 3; 1 3]);
    hidden = ax.Overlays.add('Box','ID','hidden','Center',[5 5]);
    hidden.Visible = 'off';
    otherView = ax.Overlays.add('Point','ID','other','Position',[5 5],'Z',2);
    ax.Overlays.setActive('p');
    ax.Overlays.select('p');
    ax.OverlaysVisible = 'off';
    verifyEqual(testCase, string(p.Visible), "on");
    verifyEqual(testCase, string(p.ViewVisible), "off");
    boundary = findobj(ax.getAxes(),'Tag','OverlayPolygon');
    verifyEqual(testCase, string(boundary.Visible), "off");
    verifyEmpty(testCase, ax.Overlays.idsInsideRectangle([0 12 0 10]));
    added = ax.Overlays.add('Box','ID','added','Center',[4 4]);
    verifyEqual(testCase, string(added.ViewVisible), "off");
    ax.toggleOverlays();
    verifyEqual(testCase, string(boundary.Visible), "on");
    verifyEqual(testCase, string(hidden.Visible), "off");
    verifyEqual(testCase, string(otherView.ViewVisible), "off");
    verifyEqual(testCase, string(added.ViewVisible), "on");
    verifyEqual(testCase, ax.Overlays.getActiveID(), "p");
    verifyEqual(testCase, ax.Overlays.getSelectedIDs(), "p");
end
