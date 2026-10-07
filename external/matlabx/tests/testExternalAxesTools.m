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

function tests = testExternalAxesTools
    tests = functiontests(localfunctions);
end
function setup(t)
    t.applyFixture(matlab.unittest.fixtures.PathFixture(fileparts(mfilename('fullpath'))));
    t.TestData.Figure = uifigure('Visible','off');
    t.TestData.Host = matlabx.ui.axes.ImageAxes(t.TestData.Figure,'CData',zeros(10));
    t.TestData.Tool = ExternalAxesTool(t.TestData.Host);
end
function teardown(t)
    delete(t.TestData.Figure);
    delete(t.TestData.Tool);
end
function testInstallToggleUninstallReinstall(t)
    ax = t.TestData.Host; tool = t.TestData.Tool;
    ax.installTool(tool);
    t.verifyEqual(ax.Tools.ExternalTool,tool);
    t.verifyEqual(ax.getInstalledTool("ExternalTool"),tool);
    buttons = findall(ax.getAxes().Toolbar,'Tooltip','External test tool');
    t.verifyNumElements(buttons,1);
    t.verifyTrue(isgraphics(tool.Menu));
    buttons.Value = 'on';
    buttons.ValueChangedFcn(buttons,[]);
    t.verifyEqual(tool.Enables,1);
    t.verifyTrue(tool.Enabled);
    ax.installTool(tool);
    t.verifyEqual(tool.Installs,1);
    t.verifyNumElements(findall(ax.getAxes().Toolbar,'Tooltip','External test tool'),1);
    menu = tool.Menu;
    ax.uninstallTool(tool);
    t.verifyEqual(tool.Disables,1);
    t.verifyEqual(tool.Uninstalls,1);
    t.verifyFalse(isgraphics(menu));
    t.verifyFalse(isgraphics(buttons));
    t.verifyTrue(isvalid(tool));
    t.verifyFalse(tool.Installed);
    t.verifyFalse(isfield(ax.Tools,'ExternalTool'));
    ax.uninstallTool(tool);
    ax.installTool(tool);
    t.verifyEqual(tool.Installs,2);
    ax.uninstallTool("ExternalTool");
    t.verifyEqual(tool.Uninstalls,2);
end
function testWrongHostAndConflictingName(t)
    ax = t.TestData.Host; tool = t.TestData.Tool;
    other = matlabx.ui.axes.ImageAxes(t.TestData.Figure);
    t.verifyError(@() other.installTool(tool),'matlabx:ui:ToolHostMismatch');
    ax.installTool(tool);
    duplicate = ExternalAxesTool(ax);
    cleanup = onCleanup(@() delete(duplicate)); %#ok<NASGU>
    t.verifyError(@() ax.installTool(duplicate),'matlabx:ui:ToolNameConflict');
    ax.uninstallTool(duplicate);
    t.verifyEqual(ax.getInstalledTool("ExternalTool"),tool);
end
function testDeleteTool(t)
    ax = t.TestData.Host; tool = t.TestData.Tool;
    ax.installTool(tool);
    tool.enable();
    menu = tool.Menu;
    delete(tool);
    t.verifyEmpty(ax.getInstalledTool("ExternalTool"));
    t.verifyFalse(isgraphics(menu));
    t.verifyEmpty(findall(ax.getAxes().Toolbar,'Tooltip','External test tool'));
    ax.uninstallTool(tool);
    delete(tool);
end
function testDeleteHostAndFigure(t)
    ax = t.TestData.Host; tool = t.TestData.Tool;
    ax.installTool(tool);
    tool.enable();
    delete(ax);
    t.verifyTrue(isvalid(tool));
    t.verifyFalse(tool.Installed);
    t.verifyFalse(tool.Enabled);
    t.verifyTrue(tool.GraphicsAliveAtUninstall);
    other = matlabx.ui.axes.ImageAxes(t.TestData.Figure);
    second = ExternalAxesTool(other);
    cleanup = onCleanup(@() delete(second)); %#ok<NASGU>
    other.installTool(second);
    delete(t.TestData.Figure);
    t.verifyTrue(isvalid(second));
    t.verifyFalse(second.Installed);
    t.verifyTrue(second.GraphicsAliveAtUninstall);
end
function testBuiltInAndFailedInstall(t)
    ax = t.TestData.Host; tool = t.TestData.Tool;
    ax.loadTools("Zoom");
    ax.installTool("Zoom");
    zoom = ax.getInstalledTool("Zoom");
    t.verifyTrue(zoom.Installed);
    ax.uninstallTool("Zoom");
    t.verifyTrue(isvalid(zoom));
    ax.installTool("Zoom");
    tool.FailInstall = true;
    t.verifyError(@() ax.installTool(tool),'test:InstallFailed');
    t.verifyEmpty(ax.getInstalledTool("ExternalTool"));
    t.verifyFalse(isgraphics(tool.Menu));
    delete(ax);
    t.verifyFalse(isvalid(zoom));
end

function testHotkeyRemovedAndRestored(t)
    ax = t.TestData.Host; tool = t.TestData.Tool;
    ax.installTool(tool);
    event = keyEvent(t);
    ax.routeHotkey(event);
    t.verifyTrue(tool.Enabled);
    t.verifyTrue(event.StopPropagation);
    ax.uninstallTool(tool);
    event = keyEvent(t);
    ax.routeHotkey(event);
    t.verifyFalse(event.StopPropagation);
    t.verifyFalse(tool.Enabled);
    ax.installTool(tool);
    ax.routeHotkey(keyEvent(t));
    t.verifyTrue(tool.Enabled);
end
function event = keyEvent(~)
    event = ToolHotkeyEvent();
end

function testInvalidInstances(t)
    ax = t.TestData.Host;
    t.verifyError(@() ax.installTool(matlabx.ui.axes.AxesTool.empty), ...
        'matlabx:ui:InvalidTool');
    tool = t.TestData.Tool;
    delete(tool);
    t.verifyError(@() ax.installTool(tool),'matlabx:ui:InvalidTool');
end

function testIndependentContributionSettings(t)
    ax = t.TestData.Host;
    configurations = [true true; true false; false true; false false];

    for k = 1:size(configurations,1)
        tool = ExternalAxesTool(ax);
        tool.ContributeToolbar = configurations(k,1);
        tool.ContributeContextMenu = configurations(k,2);
        ax.installTool(tool);

        buttons = findall(ax.getAxes().Toolbar,'Tooltip','External test tool');
        t.verifyEqual(~isempty(buttons),tool.ContributeToolbar);
        t.verifyEqual(isLiveGraphic(tool.Menu),tool.ContributeContextMenu);
        t.verifyTrue(tool.Installed);
        t.verifyEqual(tool.Installs,1);

        % Contributions are independent of controller state and hotkeys.
        event = keyEvent(t);
        ax.routeHotkey(event);
        t.verifyTrue(tool.Enabled);
        t.verifyTrue(event.StopPropagation);
        t.verifyEqual(tool.Enables,1);

        ax.uninstallTool(tool);
        t.verifyTrue(isvalid(tool));
        t.verifyFalse(tool.Installed);
        t.verifyFalse(tool.Enabled);
        t.verifyEmpty(findall(ax.getAxes().Toolbar, ...
            'Tooltip','External test tool'));
        t.verifyFalse(isLiveGraphic(tool.Menu));

        % The same configuration must also clean up through tool deletion.
        ax.installTool(tool);
        delete(tool);
        t.verifyEmpty(ax.getInstalledTool("ExternalTool"));
        t.verifyEmpty(findall(ax.getAxes().Toolbar, ...
            'Tooltip','External test tool'));
    end
end

function tf = isLiveGraphic(value)
    tf = ~isempty(value) && all(isgraphics(value));
end
