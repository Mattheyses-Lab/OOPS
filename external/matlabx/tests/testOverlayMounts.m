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

function tests = testOverlayMounts
    tests = functiontests(localfunctions);
end
function setup(t)
    t.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(mfilename('fullpath'))));
    t.TestData.Figure = uifigure('Visible','off');
    t.TestData.Axes = matlabx.ui.axes.ImageAxes(t.TestData.Figure,'CData',zeros(10));
    t.TestData.Content = PassiveOverlayContent();
end
function teardown(t)
    delete(t.TestData.Figure);
    delete(t.TestData.Content);
end
function testMountRemoveAndVisibility(t)
    ax = t.TestData.Axes; c = t.TestData.Content;
    m = ax.mountOverlay(c);
    t.verifyEqual(m.Content,c);
    t.verifyEqual(ax.mountOverlay(c),m);
    t.verifyEqual(c.AttachCount,1);
    group = c.Graphic.Parent;
    layer = group.Parent;
    m.Visible = false;
    t.verifyEqual(string(group.Visible),"off");
    ax.OverlaysVisible = 'off';
    t.verifyEqual(string(layer.Visible),"off");
    ax.OverlaysVisible = 'on';
    t.verifyEqual(m.Visible,matlab.lang.OnOffSwitchState.off);
    m.remove();
    t.verifyFalse(isvalid(m));
    m.remove(); % Repeated removal must be harmless.
    t.verifyTrue(isvalid(c));
    t.verifyEmpty(c.Graphic.Parent);
    t.verifyFalse(isgraphics(group));
    t.verifyEqual(c.DetachCount,1);
    ax.unmountOverlay(c);
    m = ax.mountOverlay(c);
    ax.unmountOverlay(c);
    t.verifyFalse(isvalid(m));
end
function testTransferAndHostTeardown(t)
    ax = t.TestData.Axes; c = t.TestData.Content;
    m = ax.mountOverlay(c); graphic = c.Graphic;
    fig = uifigure('Visible','off');
    cleanup = onCleanup(@() delete(fig)); %#ok<NASGU>
    other = matlabx.ui.axes.ImageAxes(fig,'CData',zeros(10));
    second = other.mountOverlay(c);
    t.verifyFalse(isvalid(m));
    t.verifyEqual(c.Graphic,graphic);
    ax.unmountOverlay(c);
    t.verifyTrue(isvalid(second));
    delete(fig);
    t.verifyFalse(isvalid(second));
    t.verifyTrue(isgraphics(graphic));
    t.verifyEmpty(graphic.Parent);
    ax.mountOverlay(c);
    delete(ax);
    t.verifyTrue(isgraphics(graphic));
    t.verifyEmpty(graphic.Parent);
end
function testContentDeletionAndFailure(t)
    ax = t.TestData.Axes; c = t.TestData.Content;
    c.FailAttach = true;
    t.verifyError(@() ax.mountOverlay(c),'test:AttachFailed');
    t.verifyEmpty(c.Graphic.Parent);
    t.verifyEmpty(findobj(ax.getAxes(),'Tag','ApplicationOverlayMount'));
    c.FailAttach = false;
    m = ax.mountOverlay(c);
    delete(c);
    t.verifyFalse(isvalid(m));
    t.verifyEmpty(findobj(ax.getAxes(),'Tag','ApplicationOverlayMount'));
end
function testLayerOrdering(t)
    ax = t.TestData.Axes;
    polygon = ax.Overlays.add('Polygon','Vertices',[1 1;3 1;3 3]);
    m = ax.mountOverlay(t.TestData.Content); %#ok<NASGU>
    axesHandle = ax.getAxes();
    children = axesHandle.Children;
    layer = findobj(axesHandle,'Tag','ApplicationOverlayLayer');
    patch = findobj(axesHandle,'Tag','OverlayPolygon');
    img = findobj(axesHandle,'Type','image');
    t.verifyLessThan(find(children == patch),find(children == layer));
    t.verifyLessThan(find(children == layer),find(children == img));
    t.verifyEqual(t.TestData.Content.Graphic.PickableParts,'none');
end
