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

function tests = testRectangleSelectionBatch
%TESTRECTANGLESELECTIONBATCH Verify one final selection update per rectangle.
    tests = functiontests(localfunctions);
end

function setup(t)
    fig = uifigure('Visible','off');
    ax = matlabx.ui.axes.ImageAxes(fig,'CData',zeros(20));
    ax.Overlays.add('Point','ID','a','Position',[2 2]);
    ax.Overlays.add('Point','ID','b','Position',[4 4]);
    ax.Overlays.add('Point','ID','c','Position',[15 15]);
    ax.Overlays.add('Box','ID','box','Center',[3 3],'BoxSize',2);
    t.TestData.Figure = fig;
    t.TestData.Axes = ax;
    t.TestData.Count = 0;
    t.TestData.Listener = addlistener(ax.Overlays,'SelectionChanged', ...
        @(~,~) increment(t));
end

function teardown(t)
    delete(t.TestData.Listener);
    delete(t.TestData.Figure);
end

function testReplaceMultiple(t)
    select(t,"replace",[0 6 0 6]);
    t.verifyEqual(t.TestData.Axes.Overlays.getSelectedIDs(),["a" "b" "box"]);
    t.verifyEqual(t.TestData.Count,1);
end

function testToggleMultipleUnselected(t)
    select(t,"toggle",[0 6 0 6]);
    t.verifyEqual(t.TestData.Axes.Overlays.getSelectedIDs(),["a" "b" "box"]);
    t.verifyEqual(t.TestData.Count,1);
end

function testToggleMixedAndStableOrder(t)
    manager = t.TestData.Axes.Overlays;
    manager.setSelected(["c" "a"]);
    resetCount(t);
    select(t,"toggle",[0 6 0 6]);
    % Existing a is removed, c survives in place, then b and box are added
    % in deterministic rectangle-query order.
    t.verifyEqual(manager.getSelectedIDs(),["c" "b" "box"]);
    t.verifyEqual(t.TestData.Count,1);
end

function testRemoveMultiple(t)
    manager = t.TestData.Axes.Overlays;
    manager.setSelected(["c" "a" "b" "box"]);
    resetCount(t);
    select(t,"remove",[0 6 0 6]);
    t.verifyEqual(manager.getSelectedIDs(),"c");
    t.verifyEqual(t.TestData.Count,1);
end

function testEmptyRectangleModes(t)
    manager = t.TestData.Axes.Overlays;
    manager.setSelected(["c" "a"]);
    resetCount(t);

    select(t,"toggle",[8 9 8 9]);
    select(t,"remove",[8 9 8 9]);
    t.verifyEqual(manager.getSelectedIDs(),["c" "a"]);
    t.verifyEqual(t.TestData.Count,0);

    select(t,"replace",[8 9 8 9]);
    t.verifyEmpty(manager.getSelectedIDs());
    t.verifyEqual(t.TestData.Count,1);
end

function testRestrictedReplacePreservesOtherTypes(t)
    manager = t.TestData.Axes.Overlays;
    manager.setSelected(["c" "box" "a"]);
    resetCount(t);
    manager.selectInsideRectangle([0 6 0 6],Mode="replace",Type="Point");
    % box is outside the target type and retains its relative position;
    % a survives, and b is appended as the newly selected point.
    t.verifyEqual(manager.getSelectedIDs(),["box" "a" "b"]);
    t.verifyEqual(t.TestData.Count,1);
end

function testBatchManagerMethods(t)
    manager = t.TestData.Axes.Overlays;
    manager.toggleSelected(["a" "b" "missing" "a"]);
    t.verifyEqual(manager.getSelectedIDs(),["a" "b"]);
    t.verifyEqual(t.TestData.Count,1);
    manager.deselect(["a" "b" "missing"]);
    t.verifyEmpty(manager.getSelectedIDs());
    t.verifyEqual(t.TestData.Count,2);
    manager.deselect(["a" "missing"]);
    t.verifyEqual(t.TestData.Count,2);
end

function select(t,mode,rect)
    t.TestData.Axes.Overlays.selectInsideRectangle(rect,Mode=mode);
end

function increment(t)
    t.TestData.Count = t.TestData.Count + 1;
end

function resetCount(t)
    t.TestData.Count = 0;
end
