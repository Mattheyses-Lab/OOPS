function tests = testPlotAxesTools
%TESTPLOTAXESTOOLS Test PlotAxes tools, menus, ownership, and export.

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

function setup(testCase)
    testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
        fileparts(mfilename('fullpath'))));
    fig = uifigure('Visible','off');
    host = matlabx.ui.axes.PlotAxes(fig);
    testCase.TestData.Figure = fig;
    testCase.TestData.Host = host;
    testCase.TestData.Tool = ExternalPlotAxesTool(host);
end

function teardown(testCase)
    if isvalid(testCase.TestData.Figure)
        delete(testCase.TestData.Figure);
    end
    if isvalid(testCase.TestData.Tool)
        delete(testCase.TestData.Tool);
    end
end

function testDefaultBuiltinsAndContextMenu(testCase)
    host = testCase.TestData.Host;
    testCase.verifyEqual(sort(string(fieldnames(host.Tools))), ...
        sort(["Export";"CopyGraphics"]));
    testCase.verifyNumElements(findall(host.Axes.Toolbar, ...
        'Tooltip','Export plot'),1);
    testCase.verifyNumElements(findall(host.ContextMenu, ...
        'Text','Export Plot...'),1);
    testCase.verifyNumElements(findall(host.ContextMenu, ...
        'Text','Copy as Vector Graphics'),1);
end

function testExternalToolLifecycleAndReinstall(testCase)
    host = testCase.TestData.Host;
    tool = testCase.TestData.Tool;
    host.installTool(tool);
    testCase.verifyEqual(host.getInstalledTool(tool.Name),tool);
    testCase.verifyNumElements(findall(host.Axes.Toolbar, ...
        'Tooltip','External plot test tool'),1);
    testCase.verifyTrue(isgraphics(tool.Menu));

    button = findall(host.Axes.Toolbar,'Tooltip','External plot test tool');
    button.Value = 'on';
    button.ValueChangedFcn(button,[]);
    testCase.verifyTrue(tool.Enabled);
    testCase.verifyEqual(tool.Enables,1);

    host.uninstallTool(tool);
    testCase.verifyTrue(isvalid(tool));
    testCase.verifyFalse(isgraphics(tool.Menu));
    testCase.verifyEqual(tool.Disables,1);
    host.installTool(tool);
    testCase.verifyEqual(tool.Installs,2);
end

function testDuplicateAndWrongHostAreRejected(testCase)
    host = testCase.TestData.Host;
    tool = testCase.TestData.Tool;
    host.installTool(tool);
    host.installTool(tool);
    testCase.verifyNumElements(findall(host.Axes.Toolbar, ...
        'Tooltip','External plot test tool'),1);

    otherFigure = uifigure('Visible','off');
    cleanup = onCleanup(@() delete(otherFigure));
    other = matlabx.ui.axes.PlotAxes(otherFigure);
    testCase.verifyError(@() other.installTool(tool), ...
        'matlabx:ui:ToolHostMismatch');
end

function testHostDoesNotDeleteBorrowedTool(testCase)
    host = testCase.TestData.Host;
    tool = testCase.TestData.Tool;
    host.installTool(tool);
    delete(host);
    testCase.verifyTrue(isvalid(tool));
    testCase.verifyFalse(tool.Installed);
end

function testDeletingBorrowedToolUnregistersIt(testCase)
    host = testCase.TestData.Host;
    tool = testCase.TestData.Tool;
    host.installTool(tool);
    delete(tool);
    testCase.verifyEmpty(host.getInstalledTool("ExternalPlotTool"));
    testCase.verifyEmpty(findall(host.Axes.Toolbar, ...
        'Tooltip','External plot test tool'));
end

function testContextMenuAndDisplayState(testCase)
    host = testCase.TestData.Host;
    host.ContextMenuItems = ["Toolbar","Grid","Box"];
    host.ToolbarVisible = 'off';
    host.GridVisible = 'on';
    host.BoxVisible = 'on';
    testCase.verifyEqual(host.Axes.Toolbar.Visible, ...
        matlab.lang.OnOffSwitchState.off);
    testCase.verifyEqual(host.Axes.XGrid,matlab.lang.OnOffSwitchState.on);
    testCase.verifyEqual(host.Axes.YGrid,matlab.lang.OnOffSwitchState.on);
    testCase.verifyEqual(host.Axes.Box,matlab.lang.OnOffSwitchState.on);
end

function testVectorAndRasterExport(testCase)
    host = testCase.TestData.Host;
    plot(host.Axes,1:3,[1 4 2]);
    pdfFile = string(tempname) + ".pdf";
    pngFile = string(tempname) + ".png";
    cleanup = onCleanup(@() deleteFiles([pdfFile pngFile]));
    host.exportPlot(pdfFile,ContentType="vector");
    host.exportPlot(pngFile,ContentType="image",Resolution=100);
    testCase.verifyTrue(isfile(pdfFile));
    testCase.verifyTrue(isfile(pngFile));
end

function deleteFiles(files)
    for file = files
        if isfile(file), delete(file); end
    end
end
