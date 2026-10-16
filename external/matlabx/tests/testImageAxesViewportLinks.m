function tests = testImageAxesViewportLinks
%TESTIMAGEAXESVIEWPORTLINKS Atomic bidirectional viewport/Zoom synchronization.

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

    tests = functiontests(localfunctions);
end

function setup(t)
    fig = uifigure('Visible','off');
    grid = uigridlayout(fig,[1 2]);
    image = zeros(100,120);
    t.TestData.Figure = fig;
    t.TestData.First = matlabx.ui.axes.ImageAxes(grid, ...
        'CData',image,'Tools',{'Zoom'});
    t.TestData.Second = matlabx.ui.axes.ImageAxes(grid, ...
        'CData',image,'Tools',{'Zoom'});
end

function teardown(t)
    if isvalid(t.TestData.First), t.TestData.First.removeLinks(); end
    delete(t.TestData.Figure);
end

function testBidirectionalViewportAndZoomToolState(t)
    first = t.TestData.First;
    second = t.TestData.Second;
    first.addLink(second,{'Viewport'});

    first.ZoomEnabled = true;
    t.verifyTrue(first.Tools.Zoom.Enabled);
    t.verifyEqual(string(toolbarButton(first).Value),"on");
    first.setViewportCenterAndZoomFactor([60 50],4);
    verifyMatchingViewport(t,first,second);
    t.verifyTrue(second.ZoomEnabled);
    t.verifyTrue(second.Tools.Zoom.Enabled);
    t.verifyEqual(string(toolbarButton(second).Value),"on");
    t.verifyEqual(string(second.ViewportBoxVisible),"on");

    second.setViewportCenterAndZoomFactor([30 25],2);
    verifyMatchingViewport(t,second,first);

    second.Tools.Zoom.disable();
    verifyMatchingViewport(t,second,first);
    t.verifyFalse(first.ZoomEnabled);
    t.verifyFalse(first.Tools.Zoom.Enabled);
    t.verifyEqual(string(toolbarButton(first).Value),"off");
    t.verifyEqual(string(first.ViewportBoxVisible),"off");
end

function testInitialSyncAndUnlink(t)
    first = t.TestData.First;
    second = t.TestData.Second;
    first.Tools.Zoom.enable();
    first.setViewportCenterAndZoomFactor([70 60],5);

    first.addLink(second,{'Viewport'});
    verifyMatchingViewport(t,first,second);
    t.verifyTrue(second.Tools.Zoom.Enabled);

    first.removeLinks();
    prior = second.getViewport();
    first.setViewportCenterAndZoomFactor([25 25],2);
    t.verifyEqual(second.getViewport(),prior);
end

function testFollowCursorLockIsLinked(t)
    first = t.TestData.First;
    second = t.TestData.Second;
    first.addLink(second,{'Viewport'});
    first.ZoomEnabled = true;
    first.setViewportCenterAndZoomFactor([60 50],4);
    lockedViewport = first.getViewport();

    first.FollowCursorEnabled = false;
    t.verifyFalse(second.FollowCursorEnabled);
    t.verifyEqual(second.getViewport().XLim,lockedViewport.XLim,'AbsTol',1e-10);
    t.verifyEqual(second.getViewport().YLim,lockedViewport.YLim,'AbsTol',1e-10);

    second.FollowCursorEnabled = true;
    t.verifyTrue(first.FollowCursorEnabled);
    verifyMatchingViewport(t,second,first);
end

function testDefaultLinkSetIncludesViewport(t)
    props = matlabx.ui.axes.ImageAxes.getLinkableProperties();
    t.verifyTrue(any(strcmp(props,'Viewport')));

    first = t.TestData.First;
    second = t.TestData.Second;
    first.addLink(second);
    first.Tools.Zoom.enable();
    first.setViewportCenterAndZoomFactor([60 50],3);
    verifyMatchingViewport(t,first,second);
end

function verifyMatchingViewport(t,source,target)
    sourceView = source.getViewport();
    targetView = target.getViewport();
    t.verifyEqual(targetView.XLim,sourceView.XLim,'AbsTol',1e-10);
    t.verifyEqual(targetView.YLim,sourceView.YLim,'AbsTol',1e-10);
    t.verifyEqual(target.ZoomEnabled,source.ZoomEnabled);
    t.verifyEqual(target.FollowCursorEnabled,source.FollowCursorEnabled);
end

function button = toolbarButton(ax)
    button = findall(ax.getAxes().Toolbar,'Tooltip','Zoom/Follow Cursor');
end
