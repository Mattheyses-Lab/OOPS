% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tests = testGUI
%TESTGUI Runtime controller checks with real MATLAB controls; no interaction dialogs.
tests = functiontests(localfunctions);
end
function setupOnce(t)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
t.applyFixture(matlab.unittest.fixtures.PathFixture(root));
oops.setup.run();
end
function setup(t)
oops.Log.close(); logger = oops.Log.get(); logger.PrintToCommandWindow = false;
p = oops.model.Project();
for k = 1:2
    g = p.addGroup("Group "+k);
    for j = 1:3
        input = matlabx.image.Image5D.fromComponents({rand(20,30),rand(20,30),rand(20,30),rand(20,30)});
        image = g.addImage(input,"Image "+j);
        mask = false(20,30); mask(2:4,2:4)=true; mask(10:13,18:20)=true;
        image.setMask(mask,oops.analysis.segment.objectsFromMask(mask));
    end
end
t.TestData.Project = p;
t.TestData.GUI = oops.app.GUI(Project=p,Visible='off',WriteLogFile=false);
end
function teardown(t)
delete(t.TestData.GUI); delete(t.TestData.Project); oops.Log.close();
end
function testTreesControlIndependentState(t)
ui = t.TestData.GUI; p = ui.Project; g = p.Groups(1);
t.verifyEqual(ui.ImagesTree.SelectedNodes.NodeData,g.Images(1).ID);
ui.ImagesTree.CheckedNodes = ui.ImagesTree.Children([2 3]);
ui.ImagesTree.CheckedNodesChangedFcn(ui.ImagesTree,[]);
t.verifyEqual(g.SelectedImageIDs,[g.Images(2).ID;g.Images(3).ID]);
t.verifyEqual(g.ActiveImageID,g.Images(1).ID);
ui.ImagesTree.SelectedNodes = ui.ImagesTree.Children(3);
ui.ImagesTree.SelectionChangedFcn(ui.ImagesTree,[]);
t.verifyEqual(g.ActiveImageID,g.Images(3).ID);
t.verifyEqual(numel(ui.ImagesTree.CheckedNodes),2);
p.Groups(2).setActiveImage(p.Groups(2).Images(2));
p.setActiveGroup(p.Groups(2)); p.setActiveGroup(g);
t.verifyEqual(ui.ImagesTree.SelectedNodes.NodeData,g.Images(3).ID);
t.verifyEqual(numel(ui.ImagesTree.CheckedNodes),2);
end

function testCollapsedObjectTreeDefersAndReusesNodes(t)
%TESTCOLLAPSEDOBJECTTREEDEFERSANDREUSESNODES Avoid hidden UI reconstruction.

ui = t.TestData.GUI;
group = ui.Project.ActiveGroup;
item = ui.SettingsAccordion.getItem("Objects");
nodes = ui.ObjectsTree.Children;
oldIDs = string({nodes.NodeData});
item.collapse();
group.setActiveImage(group.Images(2));
t.verifyEqual(string({ui.ObjectsTree.Children.NodeData}),oldIDs);
item.expand();
t.verifyEqual(ui.ObjectsTree.Children,nodes);
t.verifyEqual(string({nodes.NodeData}), ...
    reshape(oops.model.internal.ids(group.Images(2).Objects),1,[]));
t.verifyEqual(string(nodes(1).ContextMenu.UserData),group.Images(2).Objects(1).ID);
end

function testImageActivationRunsOneLazyViewerRefresh(t)
%TESTIMAGEACTIVATIONRUNSONELAZYVIEWERREFRESH Avoid duplicate and hidden-overlay work.

ui = t.TestData.GUI;
group = ui.Project.ActiveGroup;
t.verifyFalse(ui.LeftViewer.Tools.ObjectBoundaries.Enabled);
t.verifyFalse(ui.OrientationFieldTools{1}.Enabled);

profile clear;
profile on;
profileCleanup = onCleanup(@() profile('off'));
group.setActiveImage(group.Images(2));
profile off;
stats = profile('info');
names = string({stats.FunctionTable.FunctionName});
entry = stats.FunctionTable(names == "GUI>GUI.refreshViewers");
t.verifyEqual(numel(entry),1);

if ~isempty(entry)
    t.verifyEqual(entry.NumCalls,1);
end

% Deferred object overlays are populated only if their visibility tool is enabled.
t.verifyEmpty(ui.LeftViewer.Overlays.ids(Type="Polygon"));
t.verifyEmpty(ui.RightViewer.Overlays.ids(Type="Polygon"));
end

function testImageNavigationPreservesContentPanelTitles(t)
%TESTIMAGENAVIGATIONPRESERVESCONTENTPANELTITLES Keep source-only titles.

ui = t.TestData.GUI;
ui.Project.Settings.View.LeftSource = "Average intensity";
ui.Project.Settings.View.RightSource = "Mask";

% Use the same tree callback path as an interactive image activation.
node = ui.ImagesTree.Children(2);
ui.ImagesTree.SelectedNodes = node;
ui.ImagesTree.SelectionChangedFcn(ui.ImagesTree,[]);

t.verifyEqual(string(ui.ViewerPanels(1).Title),"Average intensity");
t.verifyEqual(string(ui.ViewerPanels(2).Title),"Mask");
end

function testGroupSwatchesAndBulkTreeSelection(t)
%TESTGROUPSWATCHESANDBULKTREESELECTION Reflect colors and batch commands.

ui = t.TestData.GUI;
p = ui.Project;
icon = string(ui.GroupsTree.Children(1).Icon);
t.verifyTrue(isfile(icon));
t.verifyTrue(startsWith(icon,string(fullfile(prefdir,'matlabx','cache','icons'))));

menu = ui.ImagesTree.ContextMenu;
selectAll = menu.Children(strcmp(string({menu.Children.Text}),"Select all"));
invert = menu.Children(strcmp(string({menu.Children.Text}),"Invert selection"));
clear = menu.Children(strcmp(string({menu.Children.Text}),"Clear selection"));
selectAll.MenuSelectedFcn(selectAll,[]);
t.verifyEqual(p.ActiveGroup.SelectedImageIDs,oops.model.internal.ids(p.ActiveGroup.Images));
invert.MenuSelectedFcn(invert,[]);
t.verifyEmpty(p.ActiveGroup.SelectedImageIDs);
selectAll.MenuSelectedFcn(selectAll,[]);
clear.MenuSelectedFcn(clear,[]);
t.verifyEmpty(p.ActiveGroup.SelectedImageIDs);
end
function testSummaryTracksActiveObjectWithoutViewerRedraw(t)
%TESTSUMMARYTRACKSACTIVEOBJECTWITHOUTVIEWERREDRAW Keep summary updates independent.
ui = t.TestData.GUI;
t.verifyEqual(ui.SummaryDomain.Items,{'Project','Image','Group','Object'});
t.verifyEqual(ui.SummaryTable.Data{'Total images','Values'},{'6'});
ui.SummaryDomain.Value = 'Object';
ui.SummaryDomain.ValueChangedFcn(ui.SummaryDomain,[]);
im = ui.Project.ActiveImage;
region = im.ActiveObject;
leftData = ui.LeftViewer.ImageData;

profile clear; profile on;
cleanupProfile = onCleanup(@() profile('off'));
region.setMeasurements(struct('OrderMean',.75));
profile off;
info = profile('info');
names = string({info.FunctionTable.FunctionName});
t.verifyFalse(any(contains(names,'refreshViewers')));
t.verifyEqual(ui.SummaryTable.Data{'Mean order','Values'},{'0.75'});
t.verifyEqual(ui.LeftViewer.ImageData,leftData);

im.setActiveObject(im.Objects(2));
t.verifyEqual(ui.SummaryTable.Data{'Name','Values'},{'Object 2'});
im.removeObjects(im.Objects);
t.verifyEmpty(ui.SummaryTable.Data);
end

function testSettingsDriveSameViewersAndLog(t)
ui = t.TestData.GUI; p = ui.Project;
left = ui.LeftViewer; right = ui.RightViewer;
control = ui.SettingsUI.View.LeftSource;
control.Value = 'Mask'; control.ValueChangedFcn(control,[]);
t.verifyEqual(p.Settings.View.LeftSource,"Mask");
t.verifyEqual(ui.LeftViewer,left); t.verifyEqual(ui.RightViewer,right);
t.verifyEqual(left.ImageData.getPlane(1,1,1),p.ActiveImage.Mask);
p.Settings.ObjectDisplay.CropMargin = 8;
t.verifyFalse(isfield(ui.SettingsUI,"ObjectDisplay"));
p.Settings.View.LeftSource = "Input";
left.C = 3;
p.ActiveGroup.setSelectedImages(p.ActiveGroup.Images(2));
t.verifyEqual(left.C,3,'Batch selection must preserve the viewer frame.');
oops.Log.INFO("UI sink verification"); oops.Log.flush();
t.verifyTrue(any(contains(string(ui.LogTextArea.Value),"UI sink verification")));
end

function testLargeViewerViewportsLinkOnlyWhileBothAreVisible(t)
%TESTLARGEVIEWERVIEWPORTSLINKONLYWHILEBOTHAREVISIBLE Follow main panel content.

ui = t.TestData.GUI;
settings = ui.Project.Settings.View;

% Two image sources form one bidirectional viewport link group.
settings.LeftSource = "Input";
settings.RightSource = "Average intensity";
t.verifyTrue(ui.LeftViewer.hasLinks);
t.verifyTrue(ui.RightViewer.hasLinks);

ui.LeftViewer.enableTool("Zoom");
ui.LeftViewer.setViewportCenterAndZoomFactor([12 8],2);
leftViewport = ui.LeftViewer.getViewport();
rightViewport = ui.RightViewer.getViewport();
t.verifyEqual(rightViewport.XLim,leftViewport.XLim,'AbsTol',1e-10);
t.verifyEqual(rightViewport.YLim,leftViewport.YLim,'AbsTol',1e-10);

% Replacing either main viewer with another content type removes the pair.
settings.RightSource = "Scatterplot";
t.verifyFalse(ui.LeftViewer.hasLinks);
t.verifyFalse(ui.RightViewer.hasLinks);
end

function testObjectViewersProvidePassiveAnalysisOverlays(t)
%TESTOBJECTVIEWERSPROVIDEPASSIVEANALYSISOVERLAYS Mount active-object content.

ui = t.TestData.GUI;
image = ui.Project.ActiveImage;
region = image.ActiveObject;

% Stored analytical arrays and parent-coordinate midline supply all three overlays.
image.setResults(struct( ...
    'Order',0.5*ones(20,30), ...
    'Azimuth',pi/4*ones(20,30)));
region.setMidlineResult([2 2;3 3;4 4],[],struct());
ui.Project.Settings.ObjectSelection.Color = [0.2 0.4 0.6];
ui.Project.Settings.View.RightSource = "Objects";

for k = 1:4
    t.verifyTrue(ui.ObjectViewerBoundaryTools{k}.Available);
    t.verifyTrue(ui.ObjectViewerOrientationTools{k}.Available);
    t.verifyTrue(ui.ObjectViewerMidlineTools{k}.Available);
    t.verifyFalse(ui.ObjectViewerBoundaryTools{k}.Enabled);
    t.verifyFalse(ui.ObjectViewerOrientationTools{k}.Enabled);
    t.verifyFalse(ui.ObjectViewerMidlineTools{k}.Enabled);
    t.verifyEqual(ui.ObjectViewerBoundaryContents{k}.Color,[0.2 0.4 0.6]);
end

% Orientation sampling remains deferred until one field is requested.
t.verifyEmpty(ui.ObjectViewerOrientationFields{1}.X);
ui.ObjectViewerOrientationTools{1}.enable();
t.verifyEqual(numel(ui.ObjectViewerOrientationFields{1}.X), ...
    numel(region.PixelIdxList));

% The binary-mask quadrant alone uses a black midline for contrast.
t.verifyEqual(ui.ObjectViewerMidlineContents{3}.Color,[0 0 0]);
t.verifyEqual(ui.ObjectViewerMidlineContents{1}.Color,[1 1 1]);
end

function testPrimaryChannelColorFollowsDerivedSources(t)
%TESTPRIMARYCHANNELCOLORFOLLOWSDERIVEDSOURCES Preserve semantic appearance.

ui = t.TestData.GUI;
image = ui.Project.ActiveImage;
component = image.FrameLocations(1,1);
image.Input.Components(component).Color = ...
    matlabx.colors.names.toRGB('green',"Palette","MATLAB");
definition = ui.Project.Channels.add( ...
    'Green primary',matlabx.colors.names.toRGB('green',"Palette","MATLAB"));
image.setPrimaryChannel(definition);

ui.Project.Settings.View.LeftSource = "Mask";
ui.Project.Settings.View.LeftSource = "Input";
t.verifyEqual(string(ui.LeftViewer.ComponentColorMode),"colors");
t.verifyTrue(all(string(ui.LeftViewer.ComponentColors) == "green"));

ui.Project.Settings.View.LeftSource = "Average intensity";
t.verifyEqual(string(ui.LeftViewer.ComponentColorMode),"colors");
t.verifyEqual(string(ui.LeftViewer.ComponentColors{1}),"green");

ui.Project.Settings.View.LeftSource = "Mask";
t.verifyEqual(string(ui.LeftViewer.ComponentColorMode),"luts");
end

function testPrimaryIntensityUsesGrayWithoutMetadataColor(t)
%TESTPRIMARYINTENSITYUSESGRAYWITHOUTMETADATACOLOR Use an explicit fallback.

ui = t.TestData.GUI;
image = ui.Project.ActiveImage;
component = image.FrameLocations(1,1);
image.Input.Components(component).Color = [];

ui.Project.Settings.View.LeftSource = "Mask";
ui.Project.Settings.View.LeftSource = "Average intensity";

t.verifyEqual(string(ui.LeftViewer.ComponentColorMode),"colors");
t.verifyEqual(string(ui.LeftViewer.ComponentColors{1}),"gray");
t.verifyEqual(string(ui.ColormapDomain.Items{1}),"Primary intensity");
t.verifyEqual(string(ui.ColormapDomain.ItemsData{1}),"PrimaryIntensity");
end

function testAuxiliaryChannelViewerUsesProjectSemanticOrder(t)
%TESTAUXILIARYCHANNELVIEWERUSESPROJECTSEMANTICORDER Display stable missing slots.

ui = t.TestData.GUI;
p = ui.Project;
image = p.ActiveImage;
dapi = p.Channels.add('DAPI',[0.2 0.4 1]);
actin = p.Channels.add('Actin',[1 0.2 0.2]);
dapi.markAuxiliary();
source = matlabx.image.Image5D.fromComponents( ...
    {uint16(9*ones(20,30)),uint16(17*ones(20,30))}, ...
    Names=["Actin","DAPI"]);
image.addAuxiliaryChannel(actin.ID,source,1);
p.Settings.View.RightSource = "Auxiliary channels";

t.verifyEqual(ui.RightViewer.ImageData.NumComponents,2);
t.verifyEqual([ui.RightViewer.ImageData.Components.Name],["DAPI" "Actin"]);
t.verifyEqual(ui.RightViewer.ImageData.getPlane(1),zeros(20,30,'uint16'));
t.verifyEqual(ui.RightViewer.ImageData.getPlane(2),uint16(9*ones(20,30)));
t.verifyEqual(ui.RightViewer.ImageData.Components(1).Color,dapi.Color);
t.verifyEqual(ui.RightViewer.ImageData.Components(2).Color,actin.Color);
t.verifyTrue(ui.RightViewer.CanMergeComponents);

% ImageAxes owns native composite display without an OOPS-specific tool.
t.verifyFalse(any(string({ui.RightViewer.ContextMenu.Children.Text}) == ...
    "Show channel composite"));
t.verifyEqual(string(ui.RightViewer.ComponentColorMode),"colors");
ui.RightViewer.ShowComposite = 'on';
t.verifyEqual(ui.RightViewer.ShowComposite,matlab.lang.OnOffSwitchState.on);

% Moving unlike sources between viewers must replace their complete color state.
p.Settings.View.LeftSource = "Auxiliary channels";
p.Settings.View.RightSource = "Mask";
t.verifyEqual(string(ui.LeftViewer.ComponentColorMode),"colors");
t.verifyEqual(string(ui.RightViewer.ComponentColorMode),"luts");
p.Settings.View.LeftSource = "Mask";
p.Settings.View.RightSource = "Auxiliary channels";
t.verifyEqual(string(ui.LeftViewer.ComponentColorMode),"luts");
t.verifyEqual(string(ui.RightViewer.ComponentColorMode),"colors");

% ImageAxes contrast edits persist against the semantic assignment.
ui.RightViewer.C = 2;
ui.RightViewer.CLim = [2 8];
t.verifyEqual(image.getAuxiliaryChannel(actin.ID).DisplayRange,[2 8]);
p.ActiveGroup.setActiveImage(p.ActiveGroup.Images(2));
p.ActiveGroup.setActiveImage(image);
t.verifyEqual(ui.RightViewer.ComponentCLims{2},[2 8]);

fileMenu = findall(ui.Fig,'Type','uimenu','Text','File');
importMenu = findall(fileMenu,'Type','uimenu','Text','Import auxiliary channels...');
t.verifyNumElements(importMenu,1);
end

function testOrientationFieldToolKeepsIndependentVisibility(t)
%TESTORIENTATIONFIELDTOOLKEEPINDEPENDENTVISIBILITY Preserve user state across sources.

ui = t.TestData.GUI;
image = ui.Project.ActiveImage;

% Supply completed analysis images and show the supported intensity source.
image.setResults(struct( ...
    'AverageIntensity',ones(20,30), ...
    'Order',0.5*ones(20,30), ...
    'Azimuth',(pi/6)*ones(20,30)));
ui.Project.Settings.AzimuthDisplay.ScaleDownFactor = 4;
ui.Project.Settings.View.LeftSource = "Average intensity";

tool = ui.OrientationFieldTools{1};
field = ui.OrientationFields{1};
t.verifyFalse(tool.Enabled);
t.verifyTrue(tool.Available);
t.verifyEqual(string(field.Graphic.Parent.Visible),"off");

% Orientation lines are opt-in for each application session.
ui.LeftViewer.enableTool("OrientationField");
t.verifyTrue(tool.Enabled);
t.verifyEqual(string(field.Graphic.Parent.Visible),"on");

% Accordion edits flow through project settings and repaint existing lines.
ui.SettingsUI.AzimuthDisplay.ColorMode.Value = 'Mono';
ui.SettingsUI.AzimuthDisplay.ColorMode.ValueChangedFcn( ...
    ui.SettingsUI.AzimuthDisplay.ColorMode,[]);
ui.SettingsUI.AzimuthDisplay.Color.Value = [0.2 0.4 0.8];
ui.SettingsUI.AzimuthDisplay.Color.ValueChangedFcn( ...
    ui.SettingsUI.AzimuthDisplay.Color,[]);
t.verifyEqual(field.ColorMode,"Mono");
t.verifyEqual(field.Color,[0.2 0.4 0.8]);

% A user-disabled field stays hidden through appearance and source refreshes.
ui.LeftViewer.disableTool("OrientationField");
ui.Project.Settings.AzimuthDisplay.LineScale = 20;
t.verifyFalse(tool.Enabled);
t.verifyTrue(tool.Available);
t.verifyEqual(string(field.Graphic.Parent.Visible),"off");

ui.Project.Settings.View.LeftSource = "Mask";
t.verifyFalse(tool.Available);
ui.Project.Settings.View.LeftSource = "Average intensity";
t.verifyTrue(tool.Available);
t.verifyEqual(string(field.Graphic.Parent.Visible),"off");

% The application tool contributes both toolbar and context-menu controls.
button = findall(ui.LeftViewer.getAxes().Toolbar, ...
    'Tooltip','Show/Hide Orientation Field');
t.verifyNumElements(button,1);
menu = ui.LeftViewer.ContextMenu.Children( ...
    string({ui.LeftViewer.ContextMenu.Children.Text}) == "Show orientation field");
t.verifyNumElements(menu,1);
menu.MenuSelectedFcn(menu,[]);
t.verifyTrue(tool.Enabled);
t.verifyEqual(string(field.Graphic.Parent.Visible),"on");
end

function testLabelHotkeyAppliesToCheckedObjects(t)
%TESTLABELHOTKEYAPPLIESTOCHECKEDOBJECTS Route label commands through model IDs.

ui = t.TestData.GUI;
image = ui.Project.ActiveImage;
ui.Project.addLabel("Object",ID="object",Hotkey="1",Color=[0.2 0.8 0.2]);
image.setSelectedObjects(image.Objects(2));

callback = ui.CommandRouter.HotkeyFcnDict("1");
callback(ui.CommandRouter,"1");

t.verifyEqual(image.Objects(1).LabelID,"unlabeled");
t.verifyEqual(image.Objects(2).LabelID,"object");
t.verifyEqual(ui.Project.Labels.ActiveLabelID,"object");
t.verifyEqual(string(ui.LabelsTree.SelectedNodes.NodeData),"object");

ui.SettingsUI.ObjectSelection.ColorMode.Value = 'Label';
ui.SettingsUI.ObjectSelection.ColorMode.ValueChangedFcn( ...
    ui.SettingsUI.ObjectSelection.ColorMode,[]);
ui.LeftViewer.enableTool("ObjectBoundaries");
overlay = ui.LeftViewer.Overlays.get(image.Objects(2).ID);
t.verifyEqual(overlay.EdgeColor,[0.2 0.8 0.2]);
end

function testLabelCheckTreeAndExpandedMenus(t)
%TESTLABELCHECKTREEANDEXPANDEDMENUS Expose label batches and object commands.

ui = t.TestData.GUI;
project = ui.Project;
project.addLabel("First",ID="first",Hotkey="1",Color=[1 0 0]);
project.addLabel("Second",ID="second",Hotkey="2",Color=[0 1 0]);

nodes = ui.LabelsTree.Children;
ids = string({nodes.NodeData});
t.verifyClass(ui.LabelsTree,'matlab.ui.container.CheckBoxTree');
ui.LabelsTree.CheckedNodes = nodes(ismember(ids,["first","second"]));
ui.LabelsTree.CheckedNodesChangedFcn(ui.LabelsTree,[]);

mergeItems = findall(ui.Fig,'Type','uimenu','Tag','oops.mergeLabels');
t.verifyTrue(all(string({mergeItems.Enable}) == "on"));

first = nodes(ids == "first");
texts = string({first.ContextMenu.Children.Text});
t.verifyTrue(all(ismember(["Edit...","Select objects with this label", ...
    "Apply to current object selection","Delete objects with this label", ...
    "Delete label","New label...","Merge selected labels..."],texts)));

unlabeled = nodes(ids == "unlabeled");
ui.LabelsTree.CheckedNodes = [unlabeled;first];
ui.LabelsTree.CheckedNodesChangedFcn(ui.LabelsTree,[]);
t.verifyFalse(any(string({ui.LabelsTree.CheckedNodes.NodeData}) == "unlabeled"));

objectsMenu = findall(ui.Fig,'Type','uimenu','Text','Objects');
objectsMenu = objectsMenu(arrayfun(@(item) item.Parent == ui.Fig,objectsMenu));
t.verifyNumElements(objectsMenu,1);
top = string({objectsMenu.Children.Text});
t.verifyTrue(all(ismember(["Select objects...","Clear object selection...", ...
    "Invert object selection...","Delete objects...","Select by property...", ...
    "Label by property...","Delete by property..."],top)));
end

function testImportContinuesPastInvalidFourAngleFile(t)
ui = t.TestData.GUI;
folder = tempname; mkdir(folder); cleaner = onCleanup(@() rmdir(folder,'s'));
valid = fullfile(folder,'valid.tif'); invalid = fullfile(folder,'invalid.tif');
for k = 1:4
    if k == 1, imwrite(uint16(k*ones(12,16)),valid);
    else, imwrite(uint16(k*ones(12,16)),valid,'WriteMode','append'); end
end
imwrite(uint16(ones(12,16)),invalid);
group = ui.Project.ActiveGroup; count = numel(group.Images);
imported = ui.addFiles([string(invalid),string(valid)]);
t.verifyEqual(numel(imported),1); t.verifyEqual(numel(group.Images),count+1);
t.verifyEqual(ui.Project.ActiveImage,imported(1));
t.verifyFalse(imported(1).IsLoaded);
t.verifyEqual(imported(1).getFrame(4),uint16(4*ones(12,16)));
t.verifyEqual(ui.LeftViewer.ImageData,imported(1).Input);
end
function testInvalidSettingRestoresBoundControlAndLogs(t)
ui = t.TestData.GUI;
control = ui.SettingsUI.Segmentation.MinimumArea; old = control.Value;
control.Value = -3; control.ValueChangedFcn(control,[]);
t.verifyEqual(control.Value,old);
t.verifyEqual(ui.Project.Settings.Segmentation.MinimumArea,old);
log = oops.Log.asTable();
t.verifyTrue(any(log.level == "ERROR"));
end
function testDropdownsAndHiddenDeveloperSettings(t)
ui = t.TestData.GUI;
t.verifyClass(ui.SettingsUI.Segmentation.Algorithm,'matlab.ui.control.DropDown');
t.verifyClass(ui.SettingsUI.Segmentation.Connectivity,'matlab.ui.control.DropDown');
t.verifyEqual(ui.SettingsUI.Segmentation.Connectivity.ItemsData,[4 8]);
t.verifyEqual(ui.Project.Settings.Segmentation.Connectivity,4);
t.verifyClass(ui.SettingsUI.View.LeftSource,'matlab.ui.control.DropDown');
sources = oops.config.View.sources();
t.verifyEqual(string(ui.SettingsUI.View.LeftSource.Items), ...
    sources(sources ~= "Objects"));
t.verifyEqual(string(ui.SettingsUI.View.RightSource.Items), ...
    sources);
t.verifyTrue(ui.SettingsAccordion.hasItem("Scatterplot"));
t.verifyTrue(ui.SettingsAccordion.hasItem("Swarmplot"));
t.verifyTrue(ui.SettingsAccordion.hasItem("Orientation Lines"));
t.verifyClass(ui.SettingsUI.AzimuthDisplay.ColorMode,'matlab.ui.control.DropDown');
t.verifyEqual(string(ui.SettingsUI.AzimuthDisplay.ColorMode.Items), ...
    ["Direction" "Magnitude" "Mono"]);
t.verifyClass(ui.SettingsUI.AzimuthDisplay.Color,'matlab.ui.control.ColorPicker');
t.verifyClass(ui.SettingsUI.AzimuthDisplay.ObjectMask,'matlab.ui.control.CheckBox');
t.verifyFalse(isprop(ui.Project.Settings,'Analysis'));
t.verifyFalse(ui.SettingsAccordion.hasItem("Analysis"));
t.verifyFalse(ui.SettingsAccordion.hasItem("Object Display"));
t.verifyFalse(ui.SettingsAccordion.hasItem("Local Background"));
end
function testContextDeletionTargetsClickedNode(t)
ui = t.TestData.GUI; p = ui.Project;
active = p.ActiveGroup; target = p.Groups(2);
node = ui.GroupsTree.Children(2);
menus = node.ContextMenu.Children;
item = menus(strcmp(string({menus.Text}),"Delete group"));
item.MenuSelectedFcn(item,[]);
t.verifyEqual(p.ActiveGroup,active); t.verifyEqual(numel(p.Groups),1);
t.verifyFalse(isvalid(target));
activeImage = p.ActiveImage; targetImage = active.Images(3);
node = ui.ImagesTree.Children(3); menus = node.ContextMenu.Children;
item = menus(strcmp(string({menus.Text}),"Delete image")); item.MenuSelectedFcn(item,[]);
t.verifyEqual(p.ActiveImage,activeImage); t.verifyFalse(isvalid(targetImage));
end
function testColormapDomainTree(t)
ui = t.TestData.GUI; settings = ui.Project.Settings.Colormaps;
ui.ColormapDomain.Value = 'Order'; ui.ColormapDomain.ValueChangedFcn(ui.ColormapDomain,[]);
nodes = findall(ui.ColormapTree,'Type','uitreenode'); chosen = [];
for k = 1:numel(nodes)
    data = nodes(k).NodeData;
    if isstruct(data) && data.Category == "MATLAB" && data.Name == "hot", chosen = nodes(k); break; end
end
t.assertNotEmpty(chosen);
ui.ColormapTree.SelectedNodes = chosen;
ui.ColormapTree.SelectionChangedFcn(ui.ColormapTree,[]);
t.verifyEqual(settings.Order,"hot"); t.verifyEqual(settings.Intensity,"gray");
t.verifyEqual(settings.Azimuth,"hsv");
end
function testCalibrationAssignmentAutomaticallyCorrects(t)
ui = t.TestData.GUI; p = ui.Project; g = p.Groups(1);
cal = p.addCalibration(matlabx.image.Image5D.fromComponents( ...
    {ones(20,30),2*ones(20,30),3*ones(20,30),4*ones(20,30)}));
g.setCalibrations(cal.ID);
corrected = oops.analysis.Analyzer.correctedStack(g.Images(1));
t.verifyEqual(corrected(:,:,1),double(g.Images(1).getFrame(1))*4);
t.verifyEmpty(g.Images(1).Mask); t.verifyEmpty(ui.ObjectsTree.Children);
t.verifyFalse(oops.model.internal.hasCurrentCorrection(p.Groups(2).Images(1)));
end
function testGroupContextMenuExposesCalibrationWorkflow(t)
ui = t.TestData.GUI;
node = ui.GroupsTree.Children(1);
menus = node.ContextMenu.Children;
calibration = menus(strcmp(string({menus.Text}),"Calibration"));
t.assertNotEmpty(calibration);
t.verifyEqual(sort(string({calibration.Children.Text})), ...
    sort(["View assignment..." "Assign registered calibrations..." ...
    "Import and assign..." "Clear assignment"]));
end
function testCalibrationFilesApplyOnlyToCheckedGroupsAndAreReused(t)
ui = t.TestData.GUI; p = ui.Project;
folder = tempname; mkdir(folder); cleaner = onCleanup(@() rmdir(folder,'s'));
file = fullfile(folder,'calibration.tif');
for k = 1:4
    if k == 1, imwrite(uint16(k*ones(20,30)),file);
    else, imwrite(uint16(k*ones(20,30)),file,'WriteMode','append'); end
end
p.setSelectedGroups(p.Groups(1)); registered = ui.loadCalibrations(string(file));
t.verifyEqual(p.Groups(1).CalibrationIDs,registered.ID);
t.verifyEmpty(p.Groups(2).CalibrationIDs); t.verifyFalse(oops.model.internal.hasCurrentCorrection(p.Groups(2).Images(1)));
p.setSelectedGroups(p.Groups(2)); reused = ui.loadCalibrations(string(file));
t.verifyEqual(reused.ID,registered.ID); t.verifyEqual(numel(p.Calibrations),1);
t.verifyEqual(p.Groups(2).CalibrationIDs,p.Groups(1).CalibrationIDs);
t.verifyTrue(oops.model.internal.hasCurrentCorrection(p.Groups(2).Images(1)));
end
function testProcessingMenusRunWithoutCalibration(t)
ui = t.TestData.GUI; ui.Fig.Visible = 'on'; drawnow;
menus = findall(ui.Fig,'Type','uimenu');
runMenu = menus(strcmp(string({menus.Text}),"Run"));
runAll = runMenu.Children(strcmp(string({runMenu.Children.Text}),"All"));
runAll.MenuSelectedFcn(runAll,[]);
t.verifyEqual(size(ui.Project.ActiveImage.Mask),[20 30]);
t.verifyEqual(size(ui.Project.ActiveImage.Order),[20 30]);
t.verifyEqual(size(ui.Project.ActiveImage.Azimuth),[20 30]);
logs = oops.Log.asTable(); t.verifyFalse(any(logs.level == "ERROR"));
end
function testSquarePanelInteriorsAfterResize(t)
ui = t.TestData.GUI;
for width = [1400 1600 1200]
    ui.Fig.Position(3) = width;
    drawnow;
    ui.Fig.SizeChangedFcn(ui.Fig,[]); drawnow;
    chrome = matlabx.UICal.uipanelTopChromeHeightPx(12);
    % R2026b's web layout is asynchronous. Wait for the requested allocation,
    % not merely an old square panel left over from the previous figure width.
    expectedWidth = (width-10-300-5-5)/2-2*ui.ViewerPanels(1).BorderWidth;
    started = tic;
    while toc(started) < 3
        drawnow;
        a = ui.ViewerPanels(1).InnerPosition; b = ui.ViewerPanels(2).InnerPosition;
        if abs(a(3)-expectedWidth) <= 1 && abs(b(3)-expectedWidth) <= 1 && ...
                abs(a(4)-a(3)-chrome) <= 2 && abs(b(4)-b(3)-chrome) <= 2
            break;
        end
        pause(.02);
    end
    t.verifyEqual(a(3),expectedWidth,'AbsTol',1);
    t.verifyEqual(a(3),b(3),'AbsTol',1);
    t.verifyEqual(a(4)-a(3),chrome,'AbsTol',2);
    t.verifyEqual(b(4)-b(3),chrome,'AbsTol',2);
end
end
function testMainFigureHelpersAndSingleInstance(t)
ui = t.TestData.GUI;
t.verifyTrue(oops.app.hasMainFigure()); t.verifyEqual(oops.app.getMainFigure(),ui.Fig);
again = oops.launch();
t.verifyEqual(again,ui);
t.verifyEqual(numel(findall(groot,'Type','figure','Tag',oops.Info.MainFigureTag)),1);
delete(ui);
t.verifyFalse(oops.app.hasMainFigure()); t.verifyEmpty(oops.app.getMainFigure());
t.verifyFalse(oops.Log.get().EnableUISink);
t.verifyTrue(isvalid(t.TestData.Project),'An externally supplied project must survive UI closure.');
end

function testMaskControlChronologyAndVisibility(t)
ui = t.TestData.GUI; controls = ui.SettingsUI.Segmentation;
slider = ui.SegmentationUI.Puncta_1.Threshold;
t.verifyEqual(slider.ValueMode,"scalar"); t.verifyEqual(string(slider.Visible),"on");
t.verifyLessThan(controls.Algorithm.Layout.Row,slider.Layout.Row);
t.verifyLessThan(slider.Layout.Row,controls.MinimumArea.Layout.Row);
t.verifyLessThan(controls.MinimumArea.Layout.Row,controls.MaxObjects.Layout.Row);
pane = ui.SettingsAccordion.getItem("Mask").Pane;
labels = findall(pane,'Type','uilabel'); t.verifyTrue(any(string({labels.Text}) == "Object filtering"));
ui.Project.Settings.Segmentation.Algorithm = "Filaments/1";
t.verifyEqual(string(slider.Visible),"off"); t.verifyEqual(pane.RowHeight{slider.Layout.Row},0);
end
function testImageLocalThresholdPreviewAndCommit(t)
ui = t.TestData.GUI; p = ui.Project; image = p.ActiveImage;
p.Settings.Segmentation.BorderWidth = 0; p.Settings.Segmentation.MinimumArea = 1;
oops.analysis.Analyzer.segmentImages(image,p.Settings);
p.Settings.View.RightSource = "Mask";
slider = ui.SegmentationUI.Puncta_1.Threshold;
oldIDs = oops.model.internal.ids(image.Objects); oldMask = image.Mask;
slider.Value = .9; slider.ValueChangingFcn(slider,[]);
t.verifyEqual(image.Mask,oldMask); t.verifyEqual(oops.model.internal.ids(image.Objects),oldIDs);
input = ui.LeftViewer.ImageData; ui.LeftViewer.C = 3;
profile clear; profile on;
profileCleanup = onCleanup(@() profile('off'));
slider.ValueChangedFcn(slider,[]);
profile off; stats = profile('info');
names = string({stats.FunctionTable.FunctionName});
for method = ["GUI>GUI.refreshNavigation","GUI>GUI.refreshViewers"]
    entry = stats.FunctionTable(names == method);
    t.verifyEqual(numel(entry),1);
    if ~isempty(entry), t.verifyEqual(entry.NumCalls,1); end
end
t.verifyFalse(any(names == "readStack"));
t.verifyEqual(ui.LeftViewer.ImageData,input); t.verifyEqual(ui.LeftViewer.C,3);
t.verifyEqual(image.SegmentationParameters.Mode,"Manual");
t.verifyEqual(image.SegmentationParameters.Values.Threshold,.9);
t.verifyEqual(ui.RightViewer.ImageData.getPlane(1,1,1),image.Mask);
reset = ui.SegmentationUI.Reset; reset.ButtonPushedFcn(reset,[]);
t.verifyEqual(image.SegmentationParameters.Mode,"Automatic");
end
function testIndependentDisplayLimitPolicies(t)
ui = t.TestData.GUI; p = ui.Project; image = p.ActiveImage;
t.verifyEqual(ui.DisplayLimitUI.Intensity.ValueDisplayFormat,'%.2f');
t.verifyEqual(ui.DisplayLimitUI.Order.ValueDisplayFormat,'%.2f');
p.Settings.View.LeftSource = "Average intensity";
p.Settings.View.RightSource = "Input";
slider = ui.DisplayLimitUI.Intensity; slider.Value = [.2 .8];
slider.ValueChangingFcn(slider,[]);
t.verifyEmpty(image.IntensityDisplayRange); t.verifyTrue(p.Settings.Display.KeepAutoDisplayIntensity);
slider.ValueChangedFcn(slider,[]);
t.verifyEqual(image.IntensityDisplayRange,[.2 .8]);
t.verifyFalse(p.Settings.Display.KeepAutoDisplayIntensity);
t.verifyTrue(p.Settings.Display.KeepAutoDisplayOrder);
t.verifyEqual(ui.LeftViewer.CLim,[.2 .8]); t.verifyEqual(ui.RightViewer.CLim,[.2 .8]);
ui.LeftViewer.C = 3; t.verifyEqual(ui.LeftViewer.CLim,[.2 .8]);
p.Settings.Display.KeepAutoDisplayIntensity = true;
t.verifyEqual(image.IntensityDisplayRange,[.2 .8]);

lock = ui.DisplayLimitUI.Controls.Intensity.Lock;
lock.Value = true; lock.ValueChangedFcn(lock,[]);
t.verifyTrue(p.Settings.Display.LockDisplayIntensity);
t.verifyFalse(p.Settings.Display.KeepAutoDisplayIntensity);
t.verifyEqual(p.Settings.Display.LockedDisplayRangeIntensity,ui.DisplayLimitUI.Intensity.Value);

% Choose an interior range so this lock test does not invoke slider clipping.
bounds = slider.Limits;
lockedRange = bounds(1)+[.1 .9]*diff(bounds);
slider.Value = lockedRange; slider.ValueChangedFcn(slider,[]);
t.verifyTrue(p.Settings.Display.LockDisplayIntensity);
t.verifyEqual(p.Settings.Display.LockedDisplayRangeIntensity,lockedRange);
p.ActiveGroup.setActiveImage(p.ActiveGroup.Images(2));
t.verifyEqual(ui.LeftViewer.CLim,lockedRange);
t.verifyEqual(ui.RightViewer.CLim,lockedRange);

keepAuto = ui.DisplayLimitUI.Controls.Intensity.KeepAuto;
keepAuto.Value = true; keepAuto.ValueChangedFcn(keepAuto,[]);
t.verifyTrue(p.Settings.Display.KeepAutoDisplayIntensity);
t.verifyFalse(p.Settings.Display.LockDisplayIntensity);

% ImageAxes display-limit edits follow the same model and accordion path.
image = p.ActiveImage;
ui.LeftViewer.CLim = [.25 .75];
t.verifyEqual(image.IntensityDisplayRange,[.25 .75]);
t.verifyFalse(p.Settings.Display.KeepAutoDisplayIntensity);
t.verifyEqual(ui.DisplayLimitUI.Intensity.Value,[.25 .75]);
t.verifyEqual(ui.RightViewer.ComponentCLims, ...
    repmat({[.25 .75]},1,ui.RightViewer.NumComponents));

image.setResults(struct('Order',reshape(linspace(0,1,600),20,30)));
p.Settings.View.LeftSource = "Order";
ui.LeftViewer.CLim = [.1 .6];
t.verifyEqual(image.OrderDisplayRange,[.1 .6]);
t.verifyFalse(p.Settings.Display.KeepAutoDisplayOrder);
t.verifyEqual(ui.DisplayLimitUI.Order.Value,[.1 .6]);
end


function testPlotPresetAndSingletonSourceMovement(t)
%TESTPLOTPRESETANDSINGLETONSOURCEMOVEMENT Reuse one component per plot source.

ui = t.TestData.GUI;
p = ui.Project;

% Make the two user-facing data-tip modes deterministic for this test.
p.Settings.ScatterPlot.DataTipDetail = "Verbose";
p.Settings.SwarmPlot.DataTipDetail = "Verbose";
p.Settings.ScatterPlot.MarkerFaceColorMode = "Auto";
p.Settings.SwarmPlot.MarkerFaceColorMode = "Auto";

% Dropdowns display readable labels while settings retain model property names.
xVariables = ui.SettingsUI.ScatterPlot.XVariable;
orderIndex = find(string(xVariables.ItemsData) == "OrderMean",1);
t.assertNotEmpty(orderIndex);
t.verifyEqual(string(xVariables.Items{orderIndex}),"Order mean");

% Plot-facing group names must display formatting characters literally.
p.Groups(1).setProperties("Group_1",p.Groups(1).Color);

% Supply finite stored measurements so both copied components receive real data.
for group = p.Groups'
    for image = group.Images'
        for k = 1:numel(image.Objects)
            image.Objects(k).setMeasurements(struct( ...
                'SignalToBackgroundRatio',double(k),'OrderMean',double(k)/numel(image.Objects)));
        end
    end
end

viewMenu = findall(ui.Fig,'Type','uimenu','Text','View');
plots = findall(viewMenu,'Type','uimenu','Text','Plots');
plots.MenuSelectedFcn(plots,[]);

t.verifyEqual(p.Settings.View.LeftSource,"Scatterplot");
t.verifyEqual(p.Settings.View.RightSource,"Swarmplot");
t.verifyEqual(ui.LeftPlotAxes.Visible,matlab.lang.OnOffSwitchState.on);
t.verifyEqual(ui.RightPlotAxes.Visible,matlab.lang.OnOffSwitchState.on);
t.verifyEqual(ui.LeftPlotAxes.Content,ui.ScatterRenderer);
t.verifyEqual(ui.RightPlotAxes.Content,ui.SwarmRenderer);
t.verifyEqual(numel(ui.ScatterRenderer.Data.XData),numel(p.Groups));
t.verifyEqual(numel(ui.SwarmRenderer.Data.Values),numel(p.Groups));
t.verifyEqual(ui.ScatterRenderer.Data.SeriesNames(1),"Group\_1");
t.verifyEqual(ui.SwarmRenderer.Data.SeriesNames(1),"Group\_1");
t.verifyEqual(string(ui.LeftPlotAxes.Axes.XLabel.String), ...
    oops.model.ObjectMeasurements.label(p.Settings.ScatterPlot.XVariable));
t.verifyEqual(string(ui.RightPlotAxes.Axes.YLabel.String), ...
    oops.model.ObjectMeasurements.label(p.Settings.SwarmPlot.YVariable));

% Point data tips retain model identity alongside the plotted measurements.
scatterTip = ui.ScatterRenderer.Data.DataTipCells{1};
t.verifyEqual(string(scatterTip{1}), ...
    ["Group","Image","Object","Label","Signal/background ratio","Order mean"]);
t.verifyEqual(string(scatterTip{2}{1}(1)),"Group\_1");
t.verifyEqual(string(scatterTip{2}{3}(1)),"Object 1");
t.verifyEqual(string(scatterTip{3}),["","","","","%.2f","%.2f"]);
t.verifyEqual(numel(scatterTip{2}{1}),numel(ui.ScatterRenderer.Data.XData{1}));

swarmTip = ui.SwarmRenderer.Data.DataTipCells{1};
t.verifyEqual(string(swarmTip{1}), ...
    ["Group","Image","Object","Label","Order mean"]);
t.verifyEqual(string(swarmTip{3}),["","","","","%.2f"]);
t.verifyEqual(numel(swarmTip{2}{1}),numel(ui.SwarmRenderer.Data.Values{1}));
t.verifyTrue(all(cellfun(@isempty,ui.SwarmRenderer.Data.SummaryDataTipCells)));

% Compact mode replaces model names with stable one-based indices.
p.Settings.ScatterPlot.DataTipDetail = "Compact";
p.Settings.SwarmPlot.DataTipDetail = "Compact";

scatterTip = ui.ScatterRenderer.Data.DataTipCells{1};
t.verifyEqual([scatterTip{2}{1}(1),scatterTip{2}{2}(1),scatterTip{2}{3}(1)],[1 1 1]);
t.verifyEqual(string(scatterTip{3}),["%d","%d","%d","","%.2f","%.2f"]);

swarmTip = ui.SwarmRenderer.Data.DataTipCells{1};
t.verifyEqual([swarmTip{2}{1}(1),swarmTip{2}{2}(1),swarmTip{2}{3}(1)],[1 1 1]);
t.verifyEqual(string(swarmTip{3}),["%d","%d","%d","","%.2f"]);

% The UI exposes semantic choices while the renderer receives MATLABX CData mode.
t.verifyEqual(string(ui.SettingsUI.ScatterPlot.DataTipDetail.Items),["Compact","Verbose"]);
t.verifyEqual(string(ui.SettingsUI.ScatterPlot.MarkerFaceColorMode.Items),["Auto","Custom"]);
t.verifyEqual(string(ui.SettingsUI.ScatterPlot.MarkerEdgeColorMode.Items),["Auto","Custom"]);
t.verifyFalse(any(string(ui.SettingsUI.ScatterPlot.MarkerEdgeColorMode.Items) == "CData"));
t.verifyEqual(string(ui.SettingsUI.SwarmPlot.MarkerEdgeColorMode.Items),["Auto","Custom"]);
t.verifyEqual(ui.ScatterRenderer.Style.MarkerFaceColorMode,"CData");
t.verifyEqual(ui.SwarmRenderer.Style.MarkerFaceColorMode,"CData");

% Automatic violin colors follow the partitioning variable, independently
% of the separate point-color setting.
p.Settings.SwarmPlot.ViolinFaceColorMode = "auto";
p.Settings.SwarmPlot.GroupingType = "Label";
p.Settings.SwarmPlot.ColorMode = "Group";
labelColors = reshape([p.Labels.labels().Color],3,[])';
t.verifyEqual(ui.RightPlotAxes.Axes.ColorOrder,labelColors,'AbsTol',1e-12);

p.Settings.SwarmPlot.GroupingType = "Group";
p.Settings.SwarmPlot.ColorMode = "Label";
groupColors = reshape([p.Groups.Color],3,[])';
t.verifyEqual(ui.RightPlotAxes.Axes.ColorOrder,groupColors,'AbsTol',1e-12);

% Paired color pickers share one row and activate only for Custom mode.
faceMode = ui.SettingsUI.ScatterPlot.MarkerFaceColorMode;
faceColor = ui.SettingsUI.ScatterPlot.MarkerFaceColor;
t.verifyEqual(faceMode.Parent,faceColor.Parent);
t.verifyEqual(string(faceColor.Enable),"off");
faceMode.Value = 'Custom';
faceMode.ValueChangedFcn(faceMode,[]);
t.verifyEqual(string(faceColor.Enable),"on");

% Data-tip detail is the last content setting before general axes options.
t.verifyLessThan(ui.SettingsUI.ScatterPlot.DataTipDetail.Layout.Row, ...
    ui.SettingsUI.ScatterPlot.BackgroundColor.Layout.Row);
t.verifyLessThan(ui.SettingsUI.SwarmPlot.DataTipDetail.Layout.Row, ...
    ui.SettingsUI.SwarmPlot.BackgroundColor.Layout.Row);

markerSize = ui.SettingsUI.ScatterPlot.MarkerSize;
markerSize.Value = 31;
markerSize.ValueChangedFcn(markerSize,[]);
t.verifyEqual(p.Settings.ScatterPlot.MarkerSize,31);

% Moving a source transfers its renderer while both panel hosts stay fixed.
scatter = ui.ScatterRenderer;
leftHost = ui.LeftPlotAxes;
rightHost = ui.RightPlotAxes;
p.Settings.View.RightSource = "Scatterplot";
t.verifyEqual(p.Settings.View.LeftSource,"Empty");
t.verifyEqual(string(ui.SettingsUI.View.LeftSource.Value),"Empty");
t.verifyEqual(ui.ScatterRenderer,scatter);
t.verifyEmpty(ui.LeftPlotAxes.Content);
t.verifyEqual(ui.RightPlotAxes.Content,scatter);
t.verifyEqual(scatter.Host,rightHost);
t.verifyEqual(ui.LeftPlotAxes,leftHost);
t.verifyEqual(ui.RightPlotAxes,rightHost);
t.verifyEqual(ui.RightPlotAxes.Axes.XTickMode,'auto');
t.verifyEqual(ui.RightPlotAxes.Axes.XTickLabelMode,'auto');
t.verifyNotEqual(string(ui.RightPlotAxes.Axes.XTickLabel), ...
    ui.SwarmRenderer.Data.SeriesNames);

% Detached MATLABX content removes its primitives from the former host axes.
meanMarkers = findobj(ui.RightPlotAxes.Axes, ...
    'Type','line','Tag','ViolinCentralStatistic');
t.verifyEmpty(meanMarkers);

% Transfer the same primitive-backed renderer to its original host again.
p.Settings.View.LeftSource = "Scatterplot";
t.verifyEqual(p.Settings.View.RightSource,"Empty");
t.verifyEqual(ui.LeftPlotAxes.Content,scatter);
t.verifyEmpty(ui.RightPlotAxes.Content);
t.verifyEqual(scatter.Host,leftHost);
t.verifyNotEmpty(ui.LeftPlotAxes.Axes.Children);
end

function testLaunchHonorsSetupGenerationAndRestoresSessionPaths(t)
t.TestData.SetupHadPreference = oops.Preferences.has("SetupVersion");
t.TestData.SetupPrevious = oops.Preferences.get("SetupVersion","0.0.0");
preferenceCleanup = onCleanup(@() restoreSetupPreference(t.TestData));
delete(t.TestData.GUI);
oops.Preferences.set("SetupVersion","0.3.0");
t.TestData.GUI = oops.launch(Visible='off');
t.verifyEqual(oops.Preferences.get("SetupVersion"),oops.Info.RequiredSetupVersion);
delete(t.TestData.GUI);
% An already newer setup generation must not be downgraded just to launch.
oops.Preferences.set("SetupVersion","9.0.0");
rmpath(oops.Paths.external('matlabx'));
t.TestData.GUI = oops.launch(Visible='off');
t.verifyEqual(oops.Preferences.get("SetupVersion"),"9.0.0");
t.verifyTrue(contains(path,oops.Paths.external('matlabx')));
t.verifyTrue(oops.app.hasMainFigure());
end
function restoreSetupPreference(data)
if data.SetupHadPreference, oops.Preferences.set("SetupVersion",data.SetupPrevious);
else, oops.Preferences.remove("SetupVersion"); end
end

function testMasksAndPolygonsFollowCommittedMembership(t)
%TESTMASKSANDPOLYGONSFOLLOWCOMMITTEDMEMBERSHIP Keep geometry and mask in both viewers.
ui = t.TestData.GUI; image = ui.Project.ActiveImage;
ui.Project.Settings.View.RightSource = "Average intensity";
ui.LeftViewer.enableTool("ObjectBoundaries");
ui.RightViewer.enableTool("ObjectBoundaries");
ids = oops.model.internal.ids(image.Objects);
for viewer = {ui.LeftViewer,ui.RightViewer}
    axes = viewer{1};
    axes.enableTool("Mask");
    t.verifyEqual(axes.Mask,image.Mask);
    actual = axes.Overlays.ids(Type="Polygon");
    t.verifyEqual(sort(actual(:)),sort(ids));
end
survivor = ui.LeftViewer.Overlays.get(ids(2));
image.removeObjects(ids(1));
t.verifyFalse(ui.LeftViewer.Overlays.has(ids(1)));
t.verifyFalse(ui.RightViewer.Overlays.has(ids(1)));
t.verifyEqual(ui.LeftViewer.Overlays.get(ids(2)),survivor);
t.verifyEqual(ui.LeftViewer.Mask,image.Mask);
t.verifyEqual(ui.RightViewer.Mask,image.Mask);
end

function testPolygonActivationAndSelectionStayIndependent(t)
%TESTPOLYGONACTIVATIONANDSELECTIONSTAYINDEPENDENT Sync viewer edits and checkbox edits.
ui = t.TestData.GUI; image = ui.Project.ActiveImage;
ui.Project.Settings.View.RightSource = "Average intensity";
ids = oops.model.internal.ids(image.Objects);

% Generic polygon interaction is installed headlessly. OOPS supplies the
% visible object-facing toolbar and context-menu contributions.
t.verifyEmpty(findall(ui.LeftViewer.getAxes().Toolbar, ...
    'Tooltip','Polygon regions (help)'));
t.verifyNumElements(findall(ui.LeftViewer.getAxes().Toolbar, ...
    'Tooltip','Show/Hide Objects'),1);
t.verifyEmpty(findall(ui.LeftViewer.getAxes().Toolbar, ...
    'Tooltip','Show/Hide Overlays'));
t.verifyFalse(isfield(ui.LeftViewer.Tools,'Overlays'));
texts = string({ui.LeftViewer.ContextMenu.Children.Text});
t.verifyFalse(any(texts == "Polygon"));
t.verifyTrue(any(texts == "Objects"));
objectsMenu = ui.LeftViewer.ContextMenu.Children(texts == "Objects");
showItem = objectsMenu.Children(string({objectsMenu.Children.Text}) == "Show");
t.verifyNumElements(showItem,1);
t.verifyEqual(string(showItem.Checked),"off");

% The application tool toggles native object boundaries without changing
% membership or the independent application-overlay layer.
polygon = findobj(ui.LeftViewer.getAxes(),'Tag','OverlayPolygon');
applicationLayer = findobj(ui.LeftViewer.getAxes(),'Tag','ApplicationOverlayLayer');
t.verifyFalse(ui.LeftViewer.Tools.ObjectBoundaries.Enabled);
t.verifyEqual(string(ui.LeftViewer.OverlaysVisible),"off");
t.verifyEmpty(polygon);
t.verifyEqual(string(applicationLayer.Visible),"on");
showItem.MenuSelectedFcn(showItem,[]);
t.verifyTrue(ui.LeftViewer.Tools.ObjectBoundaries.Enabled);
t.verifyEqual(string(ui.LeftViewer.OverlaysVisible),"on");
polygon = findobj(ui.LeftViewer.getAxes(),'Tag','OverlayPolygon');
t.verifyNotEmpty(polygon);
ui.LeftViewer.enableTool("ObjectBoundaries");
t.verifyEqual(string(ui.LeftViewer.OverlaysVisible),"on");
t.verifyTrue(all(string({polygon.Visible}) == "on"));
ui.LeftViewer.OverlaysVisible = 'off';
t.verifyFalse(ui.LeftViewer.Tools.ObjectBoundaries.Enabled);
ui.LeftViewer.OverlaysVisible = 'on';
t.verifyTrue(ui.LeftViewer.Tools.ObjectBoundaries.Enabled);
ui.RightViewer.enableTool("ObjectBoundaries");

ui.LeftViewer.Tools.ObjectBoundaries.setActiveObjectID(ids(2));
ui.LeftViewer.Tools.ObjectBoundaries.setSelectedObjectIDs(ids(1));
t.verifyEqual(image.ActiveObjectID,ids(2));
t.verifyEqual(image.SelectedObjectIDs,ids(1));
t.verifyEqual(ui.ObjectsTree.SelectedNodes.NodeData,ids(2));
t.verifyEqual(ui.ObjectsTree.CheckedNodes.NodeData,ids(1));
t.verifyEqual(ui.RightViewer.Overlays.getActiveID(Type="Polygon"),ids(2));
selected = ui.RightViewer.Tools.ObjectBoundaries.getSelectedObjectIDs();
t.verifyEqual(selected(:),ids(1));
ui.ObjectsTree.CheckedNodes = ui.ObjectsTree.Children(2);
ui.ObjectsTree.CheckedNodesChangedFcn(ui.ObjectsTree,[]);
t.verifyEqual(image.SelectedObjectIDs,ids(2));
selected = ui.LeftViewer.Tools.ObjectBoundaries.getSelectedObjectIDs();
t.verifyEqual(selected(:),ids(2));
t.verifyEqual(image.ActiveObjectID,ids(2));
end

function testPolygonDeletionRemovesModelObjectAndMaskPixels(t)
%TESTPOLYGONDELETIONREMOVESMODELOBJECTANDMASKPIXELS Commit app-owned tool deletion.
ui = t.TestData.GUI; image = ui.Project.ActiveImage;
ui.Project.Settings.View.RightSource = "Mask";
ui.LeftViewer.enableTool("ObjectBoundaries");
ui.RightViewer.enableTool("ObjectBoundaries");
removed = image.Objects(1); id = removed.ID; pixels = removed.PixelIdxList;
survivor = image.Objects(2); mask = image.Mask; mask(pixels) = false;
image.setActiveObject(removed); image.setSelectedObjects(image.Objects);
ui.LeftViewer.Tools.ObjectBoundaries.removeBoundary(id);
t.verifyFalse(isvalid(removed));
t.verifyEqual(image.Objects,survivor);
t.verifyEqual(image.Mask,mask);
t.verifyEqual(image.SelectedObjectIDs,survivor.ID);
t.verifyEqual(ui.RightViewer.ImageData.getPlane(1,1,1),mask);
t.verifyFalse(ui.LeftViewer.Overlays.has(id));
t.verifyFalse(ui.RightViewer.Overlays.has(id));
t.verifyEqual(numel(ui.ObjectsTree.Children),1);
end

function testPixelEdgePolygonsPreserveExteriorPixels(t)
%TESTPIXELEDGEPOLYGONSPRESERVEEXTERIORPIXELS Enclose hole-free four-connected objects.
warningID = 'MATLAB:polyshape:repairedBySimplify';
previous = warning('query',warningID);
warning('error',warningID);
warningCleanup = onCleanup(@() warning(previous.state,warningID));

ui = t.TestData.GUI;
image = ui.Project.ActiveImage;

mask = false(20,30);
mask(1:5,1:5) = true;
mask(10,10) = true;
mask(11,11) = true;
mask(6:8,14:16) = logical([1 1 0; 1 0 0; 1 1 1]);
image.setMask(mask,oops.analysis.segment.objectsFromMask(mask,4));
[x,y] = meshgrid(1:30,1:20);
for region = image.Objects'
    vertices = oops.geometry.objectBoundary(region); shape = polyshape(vertices);
    expected = false(20,30); expected(region.PixelIdxList) = true;
    t.verifyEqual(reshape(isinterior(shape,x(:),y(:)),size(mask)),expected);
    t.verifyEqual(area(shape),numel(region.PixelIdxList),'AbsTol',1e-10);
    coordinates = vertices(isfinite(vertices));
    t.verifyEqual(mod(coordinates,1),repmat(.5,size(coordinates)));
end
end

function testBatchDeletionRetainsSurvivingNodesAndPolygons(t)
%TESTBATCHDELETIONRETAINSSURVIVINGNODESANDPOLYGONS One request keeps unrelated UI intact.
ui = t.TestData.GUI; image = ui.Project.ActiveImage;
ui.Project.Settings.View.RightSource = "Mask";
ui.LeftViewer.enableTool("ObjectBoundaries");
ui.RightViewer.enableTool("ObjectBoundaries");
mask = false(20,30);
mask(2:3,2:3) = true; mask(2:3,8:9) = true; mask(2:3,14:15) = true;
image.setMask(mask,oops.analysis.segment.objectsFromMask(mask));
ids = oops.model.internal.ids(image.Objects);
removed = image.Objects(1:2); survivor = image.Objects(3);
node = ui.ObjectsTree.Children(3); menu = node.ContextMenu;
left = ui.LeftViewer.Overlays.get(ids(3)); right = ui.RightViewer.Overlays.get(ids(3));
image.setActiveObject(survivor); image.setSelectedObjects(removed);
image.setDisplayRange("Intensity",[.1 .9]);
[events,listener] = observeObjectChanges(image);
cleanup = onCleanup(@() delete(listener));
ui.LeftViewer.Tools.ObjectBoundaries.deleteSelected();
t.verifyEqual(events(),1,'Batch deletion must emit one collection change.');
t.verifyFalse(any(isvalid(removed)));
t.verifyEqual(image.Objects,survivor);
t.verifyEqual(image.ActiveObjectID,ids(3));
t.verifyEmpty(image.SelectedObjectIDs);
t.verifyEqual(ui.ObjectsTree.Children,node);
t.verifyEqual(node.ContextMenu,menu);
t.verifyEqual(ui.LeftViewer.Overlays.get(ids(3)),left);
t.verifyEqual(ui.RightViewer.Overlays.get(ids(3)),right);
t.verifyEmpty(ui.LeftViewer.Mask);
t.verifyEqual(ui.RightViewer.ImageData.getPlane(1,1,1),image.Mask);
t.verifyEqual(image.IntensityDisplayRange,[.1 .9]);
% The retained subscription must still forward measurement updates.
[updates,dataListener] = observeDataChanges(image);
dataCleanup = onCleanup(@() delete(dataListener));
survivor.setMeasurements(struct('Area',4));
t.verifyEqual(updates(),1);
end

function testObjectTreeBatchDeletionUsesSameFlow(t)
%TESTOBJECTTREEBATCHDELETIONUSESSAMEFLOW Tree commands remove a checked set together.
ui = t.TestData.GUI; image = ui.Project.ActiveImage;
image.setSelectedObjects(image.Objects);
[events,listener] = observeObjectChanges(image);
cleanup = onCleanup(@() delete(listener));
menu = findall(ui.ObjectsTree.ContextMenu,'Type','uimenu','Text','Delete selected objects');
menu.MenuSelectedFcn(menu,[]);
t.verifyEqual(events(),1);
t.verifyEmpty(image.Objects); t.verifyEmpty(ui.ObjectsTree.Children);
t.verifyFalse(any(image.Mask,'all'));
t.verifyEmpty(ui.LeftViewer.Overlays.ids(Type="Polygon"));
end

function [read,listener] = observeObjectChanges(image)
%OBSERVEOBJECTCHANGES Count collection notifications without retaining deleted objects.
count = 0;
read = @getCount;
listener = addlistener(image,'ObjectsChanged',@increment);
    function value = getCount(), value = count; end
    function increment(~,~), count = count+1; end
end

function [read,listener] = observeDataChanges(image)
%OBSERVEDATACHANGES Check that survivor subscriptions still forward data events.
count = 0;
read = @getCount;
listener = addlistener(image,'DataChanged',@increment);
    function value = getCount(), value = count; end
    function increment(~,~), count = count+1; end
end
