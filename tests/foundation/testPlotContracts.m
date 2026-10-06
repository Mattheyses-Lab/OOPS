% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tests = testPlotContracts
%TESTPLOTCONTRACTS Validate normalized renderer data and style values.

    tests = functiontests(localfunctions);
end

function setupOnce(t)
%SETUPONCE Add the repository root for namespaced class discovery.

    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    t.applyFixture(matlab.unittest.fixtures.PathFixture(root));
    t.applyFixture(matlab.unittest.fixtures.PathFixture( ...
        fullfile(root,'external','matlabx')));
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

    t.verifyError(constructor, ...
        'matlabx:ui:axes:plot:ScatterDataPointCountMismatch');
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
