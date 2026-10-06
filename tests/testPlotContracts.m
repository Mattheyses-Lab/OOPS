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

function tests = testPlotContracts
%TESTPLOTCONTRACTS Validate normalized renderer data and style values.

    tests = functiontests(localfunctions);
end

function setupOnce(t)
%SETUPONCE Add the repository root for namespaced class discovery.

    root = fileparts(fileparts(mfilename('fullpath')));
    t.applyFixture(matlab.unittest.fixtures.PathFixture(root));
end

function testScatterDataNormalizesAndRetainsAlignment(t)
%TESTSCATTERDATANORMALIZESANDRETAINSALIGNMENT Normalize column inputs by group.

    data = matlabx.ui.axes.plot.ScatterData( ...
        XData={[1;2],[3;4]}, ...
        YData={[5;6],[7;8]}, ...
        SeriesNames=["First","Second"], ...
        CData={[0.1;0.2],[0.3;0.4]});

    t.verifySize(data.XData,[2 1]);
    t.verifySize(data.XData{1},[1 2]);
    t.verifyEqual(data.SeriesNames,["First";"Second"]);
    t.verifyEqual(data.CData{2},[0.3 0.4]);
end

function testScatterDataRejectsMisalignedPoints(t)
%TESTSCATTERDATAREJECTSMISALIGNEDPOINTS Reject unequal X/Y group lengths.

    constructor = @() matlabx.ui.axes.plot.ScatterData( ...
        XData={[1 2]},YData={[1]},SeriesNames="Group",CData={[1 2]});

    t.verifyError(constructor,'matlabx:ui:axes:plot:ScatterDataPointCountMismatch');
end

function testViolinDataAndStyleAreIndependentValues(t)
%TESTVIOLINDATAANDSTYLEAREINDEPENDENTVALUES Keep data separate from appearance.

    data = matlabx.ui.axes.plot.ViolinData( ...
        Values={[1;2;3]},SeriesNames="Group",CData={[0.1;0.2;0.3]});
    style = matlabx.ui.axes.plot.ViolinStyle(MarkerSize=25,PointsVisible=false);

    t.verifyEqual(data.Values{1},[1 2 3]);
    t.verifyEqual(style.MarkerSize,25);
    t.verifyFalse(style.PointsVisible);
end

function testColorShapesAndGroupCounts(t)
%TESTCOLORSHAPESANDGROUPCOUNTS Accept the documented forms, reject arbitrary matrices.
    for colors = {0.5,[1 0 0],[0.1 0.2 0.3 0.4],ones(4,3)}
        data = matlabx.ui.axes.plot.ScatterData( ...
            XData={1:4},YData={1:4},SeriesNames="Group",CData=colors);
        t.verifyEqual(data.CData{1},colors{1});
    end
    t.verifyError(@() matlabx.ui.axes.plot.ScatterData( ...
        XData={1:4},YData={1:4},SeriesNames="Group",CData={ones(2)}), ...
        'matlabx:ui:axes:plot:ScatterColorCountMismatch');
    t.verifyError(@() matlabx.ui.axes.plot.ViolinData( ...
        Values={1:4},SeriesNames=["A" "B"],CData={0.5}), ...
        'matlabx:ui:axes:plot:ViolinDataGroupCountMismatch');
end
