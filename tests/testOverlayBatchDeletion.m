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

function tests = testOverlayBatchDeletion
%TESTOVERLAYBATCHDELETION Request ownership, event counts, and selection deltas.
    tests = functiontests(localfunctions);
end

function setup(tc)
    fig = uifigure('Visible','off');
    tc.TestData.Figure = fig;
    ax = matlabx.ui.axes.ImageAxes(fig,'Tools',{'Polygon'},'CData',zeros(10));
    tc.TestData.Axes = ax;
    for id = ["a" "b" "c"]
        ax.Tools.Polygon.addPolygon(id,[1 1; 3 1; 3 3; 1 3]);
    end
    ax.Overlays.add('Box','ID','box','Center',[5 5]);
    ax.Overlays.setSelected(["a" "b" "box"]);
    ax.Overlays.setActive('a');
    ax.Overlays.setHover('b');
    setappdata(fig,'Requests',{});
    setappdata(fig,'Deleted',string.empty(1,0));
    setappdata(fig,'Events',{});
end

function teardown(tc)
    % Do not let application test callbacks run during figure teardown.
    tc.TestData.Axes.Tools.Polygon.PolygonsDeleteRequestedFcn = [];
    tc.TestData.Axes.Tools.Polygon.PolygonDeletedFcn = [];
    delete(tc.TestData.Figure);
end

function testBatchAndSingleRequests(tc)
    ax = tc.TestData.Axes;
    tool = ax.Tools.Polygon;
    before = snapshot(ax.Overlays);
    tool.PolygonsDeleteRequestedFcn = @(~,e) recordRequest(tc.TestData.Figure,e.IDs);
    tool.PolygonDeletedFcn = @(~,~) error('test:LegacyCalled','Legacy callback must not run.');
    tool.deleteSelectedPolygons();
    tool.deleteAllPolygons();
    tool.removePolygon('a');
    tool.deleteActivePolygon();
    % Validate deduplication, missing IDs, and other overlay types as well.
    tool.removePolygon(["b" "b" "missing" "box" "a"]);
    tool.removePolygon(["missing" "box"]);
    requests = getappdata(tc.TestData.Figure,'Requests');
    verifyEqual(tc,numel(requests),5);
    verifyEqual(tc,requests{1},["a" "b"]);
    verifyEqual(tc,requests{2},["a" "b" "c"]);
    verifyEqual(tc,requests{3},"a");
    verifyEqual(tc,requests{4},"a");
    verifyEqual(tc,requests{5},["b" "a"]);
    verifyEqual(tc,snapshot(ax.Overlays),before);
end

function testThrowingRequestDoesNotMutate(tc)
    ax = tc.TestData.Axes;
    before = snapshot(ax.Overlays);
    ax.Tools.Polygon.PolygonsDeleteRequestedFcn = ...
        @(~,~) error('test:Rejected','Application rejected deletion.');
    verifyError(tc,@() ax.Tools.Polygon.deleteSelectedPolygons(),'test:Rejected');
    verifyEqual(tc,snapshot(ax.Overlays),before);
end

function testApplicationReconciliationDoesNotRecurse(tc)
    ax = tc.TestData.Axes;
    ax.Tools.Polygon.PolygonsDeleteRequestedFcn = ...
        @(~,e) reconcile(tc.TestData.Figure,ax.Overlays,e.IDs);
    ax.Tools.Polygon.deleteSelectedPolygons();
    verifyEqual(tc,numel(getappdata(tc.TestData.Figure,'Requests')),1);
    verifyEqual(tc,ax.Overlays.ids(),["box" "c"]);
    verifyEqual(tc,ax.Overlays.getSelectedIDs(),"box");
end

function testLegacyCallbacks(tc)
    ax = tc.TestData.Axes;
    ax.Tools.Polygon.PolygonDeletedFcn = ...
        @(~,e) recordLegacy(tc,ax.Overlays,e.ID);
    ax.Tools.Polygon.deleteSelectedPolygons();
    verifyEqual(tc,getappdata(tc.TestData.Figure,'Deleted'),["a" "b"]);
    ax.Tools.Polygon.deleteAllPolygons();
    verifyEqual(tc,getappdata(tc.TestData.Figure,'Deleted'),["a" "b" "c"]);
    verifyTrue(tc,ax.Overlays.has('box'));
end

function testDifferentialSelection(tc)
    manager = tc.TestData.Axes.Overlays;
    fig = tc.TestData.Figure;
    L = watchEvents(manager,fig);
    a = manager.get('a'); b = manager.get('b'); c = manager.get('c');
    setappdata(fig,'Writes',string.empty(1,0));
    L(end+1) = addlistener(a,'Selected','PostSet',@(~,~) recordWrite(fig,"a"));
    L(end+1) = addlistener(b,'Selected','PostSet',@(~,~) recordWrite(fig,"b"));
    L(end+1) = addlistener(c,'Selected','PostSet',@(~,~) recordWrite(fig,"c"));
    cleanup = onCleanup(@() delete(L)); %#ok<NASGU>
    % Same membership, including duplicate/reordered input, is a true no-op.
    manager.setSelected(["b" "a" "a" "missing"],Type="Polygon");
    verifyEmpty(tc,getappdata(fig,'Events'));
    verifyEmpty(tc,getappdata(fig,'Writes'));
    verifyEqual(tc,manager.getSelectedIDs(),["a" "b" "box"]);
    manager.setSelected(["c" "b"],Type="Polygon");
    verifyEqual(tc,getappdata(fig,'Writes'),["a" "c"]);
    verifyEqual(tc,manager.getSelectedIDs(),["b" "box" "c"]);
    events = getappdata(fig,'Events');
    verifyEqual(tc,numel(events),1);
    verifyEqual(tc,events{1}.Name,"SelectionChanged");
    verifyEqual(tc,events{1}.State,snapshot(manager));
    % Unfiltered replacement uses the same survivor ordering rule.
    manager.setSelected(["a" "c"]);
    verifyEqual(tc,manager.getSelectedIDs(),["c" "a"]);
end

function testBatchRemovalFinalState(tc)
    manager = tc.TestData.Axes.Overlays;
    fig = tc.TestData.Figure;
    L = watchEvents(manager,fig);
    cleanup = onCleanup(@() delete(L)); %#ok<NASGU>
    a = manager.get('a'); b = manager.get('b');
    manager.removeMany(["b" "a" "b" "missing"]);
    verifyFalse(tc,isvalid(a)); verifyFalse(tc,isvalid(b));
    verifyEqual(tc,manager.ids(),["box" "c"]);
    verifyEqual(tc,manager.getSelectedIDs(),"box");
    verifyEqual(tc,manager.getActiveID(),"");
    verifyEqual(tc,manager.getHoverID(),"");
    events = getappdata(fig,'Events');
    names = cellfun(@(e) e.Name,events);
    verifyEqual(tc,names,["OverlayRemoved" "OverlayRemoved" ...
        "ActiveChanged" "HoverChanged" "SelectionChanged"]);
    for i = 1:numel(events)
        verifyEqual(tc,events{i}.State,snapshot(manager));
    end
    manager.removeMany(["missing" "a"]);
    verifyEqual(tc,numel(getappdata(fig,'Events')),5);
end

function testUnaffectedStateAndClear(tc)
    manager = tc.TestData.Axes.Overlays;
    fig = tc.TestData.Figure;
    L = watchEvents(manager,fig);
    cleanup = onCleanup(@() delete(L)); %#ok<NASGU>
    manager.remove('c');
    events = getappdata(fig,'Events');
    verifyEqual(tc,numel(events),1);
    verifyEqual(tc,events{1}.Name,"OverlayRemoved");
    verifyEqual(tc,manager.getActiveID(),"a");
    verifyEqual(tc,manager.getHoverID(),"b");
    setappdata(fig,'Events',{});
    manager.clear();
    events = getappdata(fig,'Events');
    verifyEqual(tc,numel(events),6); % Three removals and three state changes.
    for i = 1:numel(events)
        verifyEqual(tc,events{i}.State,snapshot(manager));
    end
    verifyEmpty(tc,manager.ids());
    manager.clear();
    verifyEqual(tc,numel(getappdata(fig,'Events')),6);
end

function state = snapshot(manager)
    state = struct('IDs',manager.ids(),'Selected',manager.getSelectedIDs(), ...
        'Active',manager.getActiveID(),'Hover',manager.getHoverID());
    % Include object flags, not just manager IDs, when checking consistency.
    overlays = manager.all();
    state.Flags = cellfun(@(o) [o.Active o.Hovered o.Selected],overlays,'UniformOutput',false);
end

function L = watchEvents(manager,fig)
    L = event.listener.empty();
    for name = ["OverlayRemoved" "ActiveChanged" "HoverChanged" "SelectionChanged"]
        L(end+1) = addlistener(manager,name,@(~,~) recordEvent(fig,manager,name)); %#ok<AGROW>
    end
end

function recordEvent(fig,manager,name)
    events = getappdata(fig,'Events');
    events{end+1} = struct('Name',name,'State',snapshot(manager));
    setappdata(fig,'Events',events);
end

function recordRequest(fig,ids)
    requests = getappdata(fig,'Requests');
    requests{end+1} = ids;
    setappdata(fig,'Requests',requests);
end

function reconcile(fig,manager,ids)
    recordRequest(fig,ids);
    manager.removeMany(ids);
end

function recordLegacy(tc,manager,id)
    verifyFalse(tc,manager.has(id)); % Notification is after optimistic removal.
    ids = getappdata(tc.TestData.Figure,'Deleted');
    setappdata(tc.TestData.Figure,'Deleted',[ids id]);
end

function recordWrite(fig,id)
    setappdata(fig,'Writes',[getappdata(fig,'Writes') id]);
end
