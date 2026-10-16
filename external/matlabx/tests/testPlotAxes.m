function tests = testPlotAxes
%TESTPLOTAXES Transfer renderer primitives while keeping UI hosts stationary.

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

function testClearRestoresHostAxesBaseline(t)
    a=t.TestData.A; v=t.TestData.Violin;
    foreground=[0.2 0.4 0.6];

    a.mount(v);
    a.ForegroundColor=foreground;
    drawnow;

    a.Axes.XAxis.Visible='off';
    a.Axes.YAxis.Visible='off';
    a.Axes.ZAxis.Visible='on';
    a.Axes.XColor='none';
    a.Axes.YColor='none';
    a.Axes.ZColor='none';
    a.Axes.ColorOrderIndex=4;

    a.clear();

    t.verifyEqual(string(a.Axes.XAxis.Visible),"on");
    t.verifyEqual(string(a.Axes.YAxis.Visible),"on");
    t.verifyEqual(string(a.Axes.ZAxis.Visible),"off");
    t.verifyEqual(a.Axes.XColor,foreground);
    t.verifyEqual(a.Axes.YColor,foreground);
    t.verifyEqual(a.Axes.ZColor,foreground);
    t.verifyEqual(a.Axes.XLabel.Color,foreground);
    t.verifyEqual(a.Axes.YLabel.Color,foreground);
    t.verifyEqual(a.Axes.ZLabel.Color,foreground);
    t.verifyEqual(a.Axes.Title.Color,foreground);
    t.verifyEqual(a.Axes.Subtitle.Color,foreground);
    t.verifyEqual(a.Axes.ColorOrderIndex,1);
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

function testScatterMarkerAppearance(t)
    host=t.TestData.A; renderer=t.TestData.Scatter;
    renderer.setStyle(matlabx.ui.axes.plot.ScatterStyle( ...
        MarkerLineWidth=1.75,MarkerFaceColorMode="Custom", ...
        MarkerFaceColor=[0.8 0.2 0.1],MarkerEdgeColorMode="CData"));
    host.mount(renderer);
    points=findobj(host.Axes,'Type','scatter');
    t.verifyEqual(points.LineWidth,1.75);
    t.verifyEqual(points.MarkerFaceColor,[0.8 0.2 0.1]);
    t.verifyEqual(string(points.MarkerEdgeColor),"flat");
end

function testRoutedDataTips(t)
    host=t.TestData.A;
    t.TestData.Scatter.setStyle(matlabx.ui.axes.plot.ScatterStyle( ...
        DataTipFormat="%.3g"));
    host.mount(t.TestData.Scatter);
    points=findobj(host.Axes,'Type','scatter');
    labels=string({points(1).DataTipTemplate.DataTipRows.Label});
    t.verifyEqual(labels,["Series","X","Y"]);
    formats=string({points(1).DataTipTemplate.DataTipRows.Format});
    t.verifyTrue(all(formats(ismember(labels,["X","Y"])) == "%.3g"));
    event=matlabx.ui.interaction.HubEvent( ...
        t.TestData.Figure,points(1),"Down",[]);
    t.verifyTrue(host.matches(event));
    host.onDown(event);
    t.verifyTrue(event.Handled);
    t.verifyNumElements(findall(points(1),'Type','datatip'),1);

    host.mount(t.TestData.Violin);
    points=findobj(host.Axes,'Type','scatter','Tag','');
    labels=string({points(1).DataTipTemplate.DataTipRows.Label});
    t.verifyEqual(labels,["Series","Value"]);
    marker=findobj(host.Axes,'Tag','ViolinCentralStatistic');
    event=matlabx.ui.interaction.HubEvent( ...
        t.TestData.Figure,marker(1),"Down",[]);
    host.onDown(event);
    t.verifyTrue(event.Handled);
    summaryTip=findall(marker(1),'Type','datatip');
    t.verifyNumElements(summaryTip,1);
    t.verifyEqual(summaryTip.DataIndex,2);

    % Hub hit testing may return internal opaque data-tip objects. Any target
    % outside the ordinary graphics hierarchy must simply fail to match.
    event=matlabx.ui.interaction.HubEvent( ...
        t.TestData.Figure,struct("Internal",true),"Up",[]);
    t.verifyFalse(host.matches(event));
end

function testHoverDataTipsAreTemporaryAndClicksAreRetained(t)
    host=t.TestData.A;
    host.mount(t.TestData.Scatter);
    points=findobj(host.Axes,'Type','scatter');

    moveEvent=matlabx.ui.interaction.HubEvent( ...
        t.TestData.Figure,points(1),"Move",[]);
    host.onMove(moveEvent);
    hoverTip=findall(points(1),'Type','datatip');
    t.verifyNumElements(hoverTip,1);
    host.onMove(moveEvent);
    t.verifyEqual(findall(points(1),'Type','datatip'),hoverTip);

    leaveEvent=matlabx.ui.interaction.HubEvent( ...
        t.TestData.Figure,points(1),"Leave",[]);
    host.onLeave(leaveEvent);
    t.verifyEmpty(findall(points(1),'Type','datatip'));

    % Clicking while a preview is visible replaces it with one retained tip.
    host.onMove(moveEvent);
    clickEvent=matlabx.ui.interaction.HubEvent( ...
        t.TestData.Figure,points(1),"Down",[]);
    host.onDown(clickEvent);
    host.onLeave(leaveEvent);
    t.verifyTrue(clickEvent.Handled);
    t.verifyNumElements(findall(points(1),'Type','datatip'),1);

    host.mount(t.TestData.Violin);
    marker=findobj(host.Axes,'Tag','ViolinCentralStatistic');
    normalLineWidth=marker(1).LineWidth;
    moveEvent=matlabx.ui.interaction.HubEvent( ...
        t.TestData.Figure,marker(1),"Move",[]);
    leaveEvent=matlabx.ui.interaction.HubEvent( ...
        t.TestData.Figure,marker(1),"Leave",[]);
    host.onMove(moveEvent);
    t.verifyNumElements(findall(marker(1),'Type','datatip'),1);
    t.verifyEqual(marker(1).LineWidth,normalLineWidth+1);
    host.onLeave(leaveEvent);
    t.verifyEmpty(findall(marker(1),'Type','datatip'));
    t.verifyEqual(marker(1).LineWidth,normalLineWidth);
end

function testViolinSummaryStatistics(t)
    host=t.TestData.A; renderer=t.TestData.Violin;
    values=[1 2 3 4 20];
    renderer.update(matlabx.ui.axes.plot.ViolinData( ...
        Values={values},SeriesNames="Group",CData={[0 0 1]}), ...
        matlabx.ui.axes.plot.ViolinStyle( ...
        CentralStatistic="median",ErrorStatistic="iqr", ...
        MarkerLineWidth=1.5,MarkerEdgeAlpha=0.4, ...
        MarkerFaceColorMode="Custom",MarkerFaceColor=[0.8 0.2 0.1], ...
        MarkerEdgeColorMode="CData", ...
        ViolinLineWidth=1.75,ViolinEdgeAlpha=0.35, ...
        ErrorBarsLineWidth=2,CentralStatLineWidth=1.25));
    host.mount(renderer);
    marker=findobj(host.Axes,'Tag','ViolinCentralStatistic');
    t.verifyEqual(string(marker.Visible),"on");
    t.verifyEqual(string(marker.HitTest),"on");
    t.verifyEqual(lower(string(marker.PickableParts)),"visible");

    marker=findobj(host.Axes,'Tag','ViolinCentralStatistic');
    bars=findobj(host.Axes,'Tag','ViolinErrorBars');
    bounds=prctile(values,[25 75]);
    t.verifyEqual(marker.YData,repmat(median(values),1,3));
    t.verifyEqual(sort(unique(bars.YData(isfinite(bars.YData)))), ...
        sort(bounds(:)));
    labels=string({marker.DataTipTemplate.DataTipRows.Label});
    t.verifyTrue(all(ismember(["Median","Q1","Q3"],labels)));
    points=findobj(host.Axes,'Type','scatter','Tag','');
    outlines=findobj(host.Axes,'Type','patch','Tag','');
    t.verifyEqual(points.LineWidth,1.5);
    t.verifyEqual(points.MarkerEdgeAlpha,0.4);
    t.verifyEqual(points.MarkerFaceColor,[0.8 0.2 0.1]);
    t.verifyEqual(string(points.MarkerEdgeColor),"flat");
    t.verifyEqual(outlines.LineWidth,1.75);
    t.verifyEqual(outlines.EdgeAlpha,0.35);
    t.verifyEqual(bars.LineWidth,2);
    t.verifyEqual(marker.LineWidth,1.25);

    renderer.setStyle(matlabx.ui.axes.plot.ViolinStyle( ...
        CentralStatistic="mean",ErrorStatistic="sem"));
    center=mean(values);
    sem=std(values)/sqrt(numel(values));
    t.verifyEqual(marker.YData,repmat(center,1,3));
    t.verifyEqual(sort(unique(bars.YData(isfinite(bars.YData)))), ...
        sort([center-sem;center+sem]),'AbsTol',1e-12);
    labels=string({marker.DataTipTemplate.DataTipRows.Label});
    t.verifyTrue(all(ismember(["Mean","SEM"],labels)));
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
    p.SummaryDataTipCell={{"Group","Custom score"},{"Demo",0.92}};
    t.verifyEqual(string(p.SummaryDataTipCell{1}),["Group","Custom score"]);
    p.setData([1 1 1 1],[3 5 7 9],[0.1 0.2 0.3 0.4]);
    t.verifyEqual(string(p.SummaryDataTipCell{1}),["Group","Custom score"]);
    p.SummaryDataTipCell={{},{}};
    labels=string(p.SummaryDataTipCell{1});
    t.verifyTrue(all(ismember(["Series","n","Mean","SD","Max","Min"],labels)));
    summaryRows=meanMarker.DataTipTemplate.DataTipRows;
    summaryFormats=string({summaryRows.Format});
    t.verifyEqual(summaryFormats(labels == "n"),"%d");
    t.verifyTrue(all(summaryFormats(ismember(labels,["Mean","SD","Max","Min"])) == "%.2f"));
    p.DataTipFormat="%.3g";
    summaryRows=meanMarker.DataTipTemplate.DataTipRows;
    summaryFormats=string({summaryRows.Format});
    t.verifyTrue(all(summaryFormats(ismember(labels,["Mean","SD","Max","Min"])) == "%.3g"));
    p.Parent=b;
    t.verifyEqual(p.Parent,b);
    for h=graphics'
        t.verifyEqual(h.Parent,b);
    end
    p.PointsVisible='off'; p.ViolinOutlinesVisible='off';
    p.Parent=[];
    t.verifyEmpty(p.Parent);
    for h=graphics'
        t.verifyEmpty(h.Parent);
        t.verifyEqual(string(h.Visible),"off");
    end
end

function testStandaloneScatterParent(t)
    a=t.TestData.A.Axes; b=t.TestData.B.Axes;
    p=matlabx.ui.axes.plot.Scatter(a,XData=[1 2 3],YData=[3 1 2], ...
        CData=[0.2 0.5 0.8]);
    cleanup=onCleanup(@() delete(p)); %#ok<NASGU>
    graphics=a.Children;
    t.verifyNumElements(graphics,2);
    t.verifyEqual(p.Parent,a);

    p.DataTipCell={{"First","Second","Third"},{1:3,4:6,7:9}};
    t.verifyEqual(string(p.DataTipCell{1}),["First","Second","Third"]);
    points=findobj(a,'Type','scatter');
    pointRows=points.DataTipTemplate.DataTipRows;
    t.verifyTrue(all(string({pointRows.Format}) == "%.2f"));
    p.DataTipFormat="%.3g";
    pointRows=points.DataTipTemplate.DataTipRows;
    t.verifyTrue(all(string({pointRows.Format}) == "%.3g"));
    p.DataTipCell={{"Only"},{1:3}};
    t.verifyEqual(string(p.DataTipCell{1}),"Only");
    p.DataTipCell={{},{}};
    t.verifyEqual(string(p.DataTipCell{1}),["X","Y"]);

    p.Parent=b;
    t.verifyEqual(p.Parent,b);
    for h=graphics'
        t.verifyEqual(h.Parent,b);
    end

    p.Parent=[];
    t.verifyEmpty(p.Parent);
    for h=graphics'
        t.verifyEmpty(h.Parent);
    end
end
