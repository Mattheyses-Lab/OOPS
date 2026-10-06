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

function tests = testPlotAxes
%TESTPLOTAXES Transfer renderer primitives while keeping UI hosts stationary.
    tests = functiontests(localfunctions);
end

function setup(t)
    f = uifigure('Visible','off');
    t.TestData.Figure = f;
    grid = uigridlayout(f,[1 2]);
    t.TestData.A = matlabx.ui.axes.PlotAxes(grid);
    t.TestData.B = matlabx.ui.axes.PlotAxes(grid);
    t.TestData.Scatter = matlabx.ui.axes.plot.ScatterRenderer();
    t.TestData.Violin = matlabx.ui.axes.plot.ViolinRenderer();
    t.TestData.Scatter.update(matlabx.ui.axes.plot.ScatterData( ...
        XData={[1 2 3 4]},YData={[2 4 3 5]},SeriesNames="Samples",CData={[1 0 0]}), ...
        matlabx.ui.axes.plot.ScatterStyle(HullVisible=true,LegendVisible=true));
    t.TestData.Violin.update(matlabx.ui.axes.plot.ViolinData( ...
        Values={[1000 1200 1400],[1600 1800 2000]}, ...
        SeriesNames=["Group A" "Group B"],CData={[0 1 0],[0 0 1]}), ...
        matlabx.ui.axes.plot.ViolinStyle());
end

function teardown(t)
    delete(t.TestData.Scatter);
    delete(t.TestData.Violin);
    delete(t.TestData.Figure);
end

function testTransferAndDisplacement(t)
    a=t.TestData.A; b=t.TestData.B;
    s=t.TestData.Scatter; v=t.TestData.Violin;
    parentA=a.Parent; parentB=b.Parent;
    axesA=a.Axes; axesB=b.Axes;
    a.mount(s); b.mount(v);
    scatterGraphics=findobj(a.Axes,'Type','scatter');
    hullGraphics=findobj(a.Axes,'Type','patch');
    violinGraphics=b.Axes.Children;
    means=findobj(b.Axes,'Tag','ViolinCentralStatistic');
    t.verifyNumElements(means,2);
    b.mount(s);
    drawnow;
    t.verifyEqual(a.Parent,parentA); t.verifyEqual(b.Parent,parentB);
    t.verifyEqual(a.Axes,axesA); t.verifyEqual(b.Axes,axesB);
    t.verifyEmpty(a.Content); t.verifyEqual(b.Content,s);
    t.verifyEqual(s.Host,b); t.verifyEmpty(v.Host);
    t.verifyEqual(b.Axes.XTickMode,'auto');
    t.verifyEqual(b.Axes.XTickLabelMode,'auto');
    t.verifyLessThan(max(b.Axes.YLim),100);
    for h=violinGraphics'
        t.verifyEqual(string(h.Visible),"off");
        t.verifyEmpty(h.Parent);
    end
    for h=[scatterGraphics;hullGraphics]'
        t.verifyEqual(h.Parent,b.Axes);
    end
    a.mount(s);
    t.verifyEqual(a.Content,s); t.verifyEmpty(b.Content);
    t.verifyEqual(scatterGraphics.Parent,a.Axes);
    % Displaced content remains reusable, including every mean marker.
    b.mount(v);
    for h=violinGraphics'
        t.verifyEqual(h.Parent,b.Axes);
    end
    t.verifyTrue(all(string({means.Visible})=="on"));
end

function testDetachSurvivesHostDeletion(t)
    a=t.TestData.A; b=t.TestData.B; s=t.TestData.Scatter;
    a.mount(s);
    points=findobj(a.Axes,'Type','scatter');
    delete(a);
    t.verifyEmpty(s.Host);
    t.verifyTrue(isvalid(points)); t.verifyEmpty(points.Parent);
    b.mount(s);
    t.verifyEqual(points.Parent,b.Axes);
    delete(s);
    t.verifyEmpty(b.Content);
end

function testPublicAttachDetachAndClear(t)
    a=t.TestData.A; s=t.TestData.Scatter;
    s.attach(a);
    t.verifyEqual(a.Content,s);
    s.detach();
    t.verifyEmpty(a.Content); t.verifyEmpty(s.Host);
    a.mount(s); a.clear(); a.clear();
    t.verifyEmpty(a.Content); t.verifyEmpty(s.Host);
end

function testResetAndEmptyContent(t)
    a=t.TestData.A; s=t.TestData.Scatter;
    a.Axes.XDir='reverse'; a.Axes.XScale='log';
    a.Axes.XGrid='on'; a.Axes.XMinorTick='on';
    a.Axes.XTick=[1 2]; a.Axes.XTickLabel={'old','labels'};
    a.mount(s);
    t.verifyEqual(a.Axes.XDir,'normal');
    t.verifyEqual(a.Axes.XScale,'linear');
    t.verifyEqual(string(a.Axes.XGrid),"off");
    t.verifyEqual(string(a.Axes.XMinorTick),"off");
    s.setData(matlabx.ui.axes.plot.ScatterData(XData={},YData={},SeriesNames=strings(0,1),CData={}));
    t.verifyEmpty(findobj(a.Axes,'Type','scatter'));
end

function testLowLevelHullAndColor(t)
    ax=t.TestData.A.Axes;
    p=matlabx.ui.axes.plot.Scatter(ax,'HullVisible','off');
    cleanup=onCleanup(@() delete(p)); %#ok<NASGU>
    for values = {[1 1],[1 2 3],[NaN Inf 2]}
        p.HullVisible='off';
        p.XData=values{1}; p.YData=values{1};
        p.HullVisible='on';
        hull=findobj(ax,'Type','patch');
        t.verifyTrue(all(isnan(hull.XData)));
    end
    p.CData=[1 0 0]; t.verifyEqual(p.CData,[1 0 0]);
end

function testPointColorsAndResizingGroups(t)
    a=t.TestData.A; s=t.TestData.Scatter; v=t.TestData.Violin;
    s.setData(matlabx.ui.axes.plot.ScatterData( ...
        XData={1:4},YData={1:4},SeriesNames="Group",CData={[0.1 0.2 0.3 0.4]}));
    a.mount(s);
    points=findobj(a.Axes,'Type','scatter');
    t.verifyEqual(points.CData(:),[0.1;0.2;0.3;0.4]);
    a.mount(v);
    v.setData(matlabx.ui.axes.plot.ViolinData( ...
        Values={[]},SeriesNames="Empty",CData={[]}));
    drawnow;
    means=findobj(a.Axes,'Tag','ViolinCentralStatistic');
    t.verifyNumElements(means,1);
    t.verifyTrue(all(isnan(means.YData)));
    v.setData(matlabx.ui.axes.plot.ViolinData( ...
        Values={},SeriesNames=strings(0,1),CData={}));
    t.verifyEmpty(a.Axes.Children);
end

function testFigureDeletionAndRemount(t)
    s=t.TestData.Scatter; v=t.TestData.Violin;
    t.TestData.A.mount(s); t.TestData.B.mount(v);
    points=findobj(t.TestData.A.Axes,'Type','scatter');
    means=findobj(t.TestData.B.Axes,'Tag','ViolinCentralStatistic');
    delete(t.TestData.Figure);
    t.verifyEmpty(s.Host); t.verifyEmpty(v.Host);
    t.verifyTrue(all(isvalid([points;means])));
    f=uifigure('Visible','off');
    cleanup=onCleanup(@() delete(f)); %#ok<NASGU>
    host=matlabx.ui.axes.PlotAxes(f);
    host.mount(s);
    t.verifyEqual(points.Parent,host.Axes);
    host.mount(v);
    t.verifyEqual(means(1).Parent,host.Axes);
end

function testStandaloneViolinPrimitives(t)
    a=t.TestData.A.Axes; b=t.TestData.B.Axes;
    p=matlabx.ui.axes.plot.Violin(a,XData=[1 1 1 1],YData=[2 4 6 8], ...
        CData=[0.1 0.2 0.3 0.4],ErrorBarsVisible='off');
    cleanup=onCleanup(@() delete(p)); %#ok<NASGU>
    graphics=a.Children;
    t.verifyNumElements(graphics,4);
    t.verifyEqual(p.CData(:),[0.1;0.2;0.3;0.4]);
    meanMarker=findobj(a,'Tag','ViolinCentralStatistic');
    t.verifyEqual(string(meanMarker.Visible),"off");
    p.setParent(b);
    for h=graphics'
        t.verifyEqual(h.Parent,b);
    end
    p.PointsVisible='off'; p.ViolinOutlinesVisible='off';
    p.setParent([]);
    for h=graphics'
        t.verifyEmpty(h.Parent);
        t.verifyEqual(string(h.Visible),"off");
    end
end
