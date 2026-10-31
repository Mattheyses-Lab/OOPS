% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function options = imageExportDialog(parent)
%IMAGEEXPORTDIALOG Collect an editable set of image-export recipes.

arguments
    parent (1,1) matlab.ui.Figure
end

options = [];
dialog = uifigure(Name="Export images",WindowStyle="modal", ...
    Visible="off",AutoResizeChildren="off",Position=[100 100 900 520],Color=[.12 .12 .12], ...
    CloseRequestFcn=@cancel);
main = uigridlayout(dialog,[4 1],ColumnWidth={'1x'}, ...
    RowHeight={'1x',30,72,30},Padding=5,RowSpacing=5, ...
    BackgroundColor=[.12 .12 .12]);

% ControlTable retains its content height while this one-cell grid supplies
% the scrolling viewport.
host = uigridlayout(main,[1 1],ColumnWidth={'1x'},RowHeight={'fit'}, ...
    Padding=0,Scrollable='on',BackgroundColor=[.12 .12 .12]);
columns = recipeColumns();
recipes = defaultRecipes();
recipeTable = matlabx.ui.control.ControlTable(host,Columns=columns,Data=recipes);
recipeTable.CellEditedFcn = @edited;

rowButtons = uigridlayout(main,[1 4],ColumnWidth={90,90,90,'1x'}, ...
    RowHeight={30},Padding=0,ColumnSpacing=5,BackgroundColor=[.12 .12 .12]);
uibutton(rowButtons,Text="Add",ButtonPushedFcn=@addRecipe);
uibutton(rowButtons,Text="Duplicate",ButtonPushedFcn=@duplicateRecipe);
uibutton(rowButtons,Text="Remove",ButtonPushedFcn=@removeRecipe);

policy = uigridlayout(main,[2 4], ...
    ColumnWidth={'fit','1x','fit','1x'},RowHeight={30,30}, ...
    Padding=0,RowSpacing=5,ColumnSpacing=5,BackgroundColor=[.12 .12 .12]);
uilabel(policy,Text="Existing files",FontColor=[.9 .9 .9]);
existing = uidropdown(policy,Items=["Stop","Overwrite","Skip"], ...
    ItemsData=["stop","overwrite","skip"],Value="stop");
embed = uicheckbox(policy,Text="Embed LUTs where supported",Value=true, ...
    FontColor=[.9 .9 .9]);
folders = uicheckbox(policy,Text="One folder per project image",Value=false, ...
    FontColor=[.9 .9 .9]);
uilabel(policy,Text="OME-TIFF LUTs are embedded only for supported integer data.", ...
    FontColor=[.65 .65 .65]);

footer = uigridlayout(main,[1 3],ColumnWidth={'1x',90,90}, ...
    RowHeight={30},Padding=0,ColumnSpacing=5,BackgroundColor=[.12 .12 .12]);
uilabel(footer,Text="");
uibutton(footer,Text="Cancel",ButtonPushedFcn=@cancel);
uibutton(footer,Text="Continue...",ButtonPushedFcn=@accept);

oops.app.centerDialog(dialog);
dialog.Visible = 'on';
uiwait(dialog);

    function edited(~,event)
        row = recipeTable.Data(event.Row,:);
        normalized = normalizeRecipe(row);
        if ~isequaln(row,normalized)
            recipeTable.replaceRow(event.Row,normalized);
        end
    end

    function addRecipe(~,~)
        recipeTable.addRow(defaultRecipe());
        recipeTable.ActiveRow = height(recipeTable.Data);
    end

    function duplicateRecipe(~,~)
        index = recipeTable.ActiveRow;
        if index == 0, return; end
        recipeTable.insertRow(index+1,recipeTable.Data(index,:));
        recipeTable.ActiveRow = index+1;
    end

    function removeRecipe(~,~)
        index = recipeTable.ActiveRow;
        if index == 0, return; end
        recipeTable.removeRow(index);
    end

    function accept(~,~)
        data = recipeTable.Data;
        if isempty(data)
            uialert(dialog,"Add at least one export recipe.","No export recipes");
            return
        end
        methodKey = repmat("",height(data),1);
        methodKey(data.Scaling == "auto") = data.AutoMethod(data.Scaling == "auto");
        keys = data.ImageType+"|"+data.Format+"|"+data.Scaling+"|"+methodKey;
        if numel(unique(keys)) ~= numel(keys)
            uialert(dialog,"Remove duplicate export recipes before continuing.", ...
                "Duplicate recipes");
            return
        end
        options = struct(Recipes=data,EmbedLUTs=embed.Value, ...
            ImageFolders=folders.Value,ExistingFiles=string(existing.Value));
        uiresume(dialog);
        delete(dialog);
    end

    function cancel(~,~)
        options = [];
        uiresume(dialog);
        delete(dialog);
    end
end

function columns = recipeColumns()
columns = [ ...
    matlabx.ui.control.ControlTableColumn(Name="ImageType",Label="Image type", ...
        Width="2x",ControlType="dropdown",Items=imageTypeLabels(), ...
        ItemsData=imageTypeValues()) ...
    matlabx.ui.control.ControlTableColumn(Name="Format",Label="Format", ...
        Width=125,ControlType="dropdown",ItemsFcn=@formatChoices) ...
    matlabx.ui.control.ControlTableColumn(Name="Scaling",Label="Scaling", ...
        Width=125,ControlType="dropdown",ItemsFcn=@scalingChoices) ...
    matlabx.ui.control.ControlTableColumn(Name="AutoMethod",Label="Auto method", ...
        Width=150,ControlType="dropdown", ...
        Items=["Light contrast","Medium contrast","Strong contrast", ...
            "Zero to max","Data range"],EnabledFcn=@autoEnabled)];
end

function data = defaultRecipes()
types = ["average-intensity";"mask";"order";"azimuth"; ...
    "auxiliary-individual";"auxiliary-combined"];
n = numel(types);
data = table(types,repmat("ome-tiff",n,1),repmat("unscaled",n,1), ...
    repmat("Light contrast",n,1),VariableNames= ...
    ["ImageType","Format","Scaling","AutoMethod"]);
end

function row = defaultRecipe()
row = table("average-intensity","ome-tiff","unscaled","Light contrast", ...
    VariableNames=["ImageType","Format","Scaling","AutoMethod"]);
end

function row = normalizeRecipe(row)
[~,formats] = formatChoices(row,1,row);
if ~ismember(row.Format,formats), row.Format = formats(1); end
[~,scales] = scalingChoices(row,1,row);
if ~ismember(row.Scaling,scales), row.Scaling = scales(1); end
end

function [items,data] = formatChoices(row,~,~)
if isDerived(row.ImageType)
    items = "PNG"; data = "png";
else
    items = ["OME-TIFF","PNG"]; data = ["ome-tiff","png"];
end
end

function [items,data] = scalingChoices(row,~,~)
if row.Format == "ome-tiff" || ismember(row.ImageType,["mask","azimuth"])
    items = "Unscaled"; data = "unscaled";
else
    items = ["Unscaled","User scaled","Auto scaled"];
    data = ["unscaled","user","auto"];
end
end

function tf = autoEnabled(row,~,~)
tf = row.Scaling == "auto";
end

function tf = isDerived(type)
tf = ismember(type,["intensity-weighted-order", ...
    "intensity-weighted-azimuth","azimuth-order-intensity-hsv"]);
end

function values = imageTypeValues()
values = ["average-intensity","mask","order","azimuth", ...
    "auxiliary-individual","auxiliary-combined", ...
    "intensity-weighted-order","intensity-weighted-azimuth", ...
    "azimuth-order-intensity-hsv"];
end

function labels = imageTypeLabels()
labels = ["Average intensity","Mask","Order","Azimuth", ...
    "Individual auxiliary channels","Combined auxiliary channels", ...
    "Intensity-weighted order","Intensity-weighted azimuth", ...
    "Azimuth-order-intensity HSV"];
end
