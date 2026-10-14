% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function plan = auxiliaryChannelImportDialog(parent,images,files,registry)
%AUXILIARYCHANNELIMPORTDIALOG Pair files and map components to semantic channels.

arguments
    parent (1,1) matlab.ui.Figure
    images (:,1) oops.model.Image
    files (:,1) string
    registry (1,1) oops.model.AuxiliaryChannelRegistry
end

if numel(images) ~= numel(files)
    error('oops:app:AuxiliaryFileCountMismatch', ...
        'Select exactly one auxiliary file for each target image.');
end

% File-backed sources provide component metadata before their pixels are loaded.
sources = matlabx.image.Image5D.empty(0,1);

try
    for k = 1:numel(files)
        sources(k,1) = matlabx.image.Image5D.fromFile(files(k));
    end
catch ME

    for openedSource = reshape(sources,1,[])
        openedSource.unload();
    end

    rethrow(ME);
end

% File indices paired with images; changing a pairing swaps rather than duplicates files.
fileForImage = (1:numel(images))';

% Editable mapping tables remain attached to files when image/file pairs are swapped.
mappings = cell(numel(files),1);

% ImageAxes color names form the stable categorical choices shown in the table.
allowedColorNames = string(matlabx.ui.axes.ImageAxes.getColorNames());

for k = 1:numel(files)
    source = sources(k);
    sourceNames = strings(source.NumComponents,1);
    sourceColors = strings(source.NumComponents,1);

    for c = 1:source.NumComponents
        sourceNames(c) = strtrim(source.getComponentName(c));

        if sourceNames(c) == ""
            sourceNames(c) = "Channel " + string(c);
        end

        % A registered semantic channel supplies the authoritative project color.
        definition = registry.findByName(sourceNames(c));

        if ~isempty(definition)
            rgb = definition.Color;
        else
            component = source.getComponent(c);
            rgb = component.Color;
        end

        if isempty(rgb)
            sourceColors(c) = allowedColorNames(1+mod(c-1,numel(allowedColorNames)));
        else
            sourceColors(c) = matlabx.ui.axes.ImageAxes.canonicalComponentColorName( ...
                matlabx.colors.names.fromRGB(rgb,"Palette","MATLAB"));
        end
    end

    % Cell data are required because MATLAB ignores uitable ColumnFormat
    % dropdown definitions when the Data property contains a table array.
    mappings{k} = [ ...
        cellstr(sourceNames), ...
        num2cell(false(source.NumComponents,1)), ...
        cellstr(sourceNames), ...
        cellstr(sourceColors)];
end

% Keep exactly the displayed source resident so ImageAxes receives complete
% component data ranges and can use its normal contrast behavior.
previewFileIndex = 1;

try
    sources(previewFileIndex).load();
catch ME

    for sourceToClose = reshape(sources,1,[])
        sourceToClose.unload();
    end

    rethrow(ME);
end

% Dialog geometry leaves a large preview beside the editable component mapping.
mainPosition = parent.Position;
width = min(1100,max(800,mainPosition(3)-80));
height = min(700,max(560,mainPosition(4)-80));
position = [mainPosition(1)+(mainPosition(3)-width)/2 ...
    mainPosition(2)+(mainPosition(4)-height)/2 width height];
dialog = uifigure( ...
    'Name','Import auxiliary channels', ...
    'Position',position, ...
    'WindowStyle','alwaysontop', ...
    'Resize','on', ...
    'CloseRequestFcn',@cancelImport);

layout = uigridlayout(dialog,[3 2], ...
    'RowHeight',{'fit','1x','fit'},'ColumnWidth',{360,'1x'}, ...
    'Padding',10,'RowSpacing',8,'ColumnSpacing',10);

% Pairing controls expose every target and full source path before import.
pairing = uigridlayout(layout,[2 2], ...
    'RowHeight',{'fit','fit'},'ColumnWidth',{'fit','1x'}, ...
    'Padding',0,'RowSpacing',5,'ColumnSpacing',8);
pairing.Layout.Row = 1;
pairing.Layout.Column = [1 2];
uilabel(pairing,'Text','Target image');
target = uidropdown(pairing, ...
    'Items',cellstr([images.Name]), ...
    'ItemsData',cellstr([images.ID]), ...
    'Value',char(images(1).ID), ...
    'ValueChangedFcn',@targetChanged);
uilabel(pairing,'Text','Auxiliary file');
file = uidropdown(pairing, ...
    'Items',cellstr(files), ...
    'ItemsData',num2cell(1:numel(files)), ...
    'Value',1, ...
    'ValueChangedFcn',@fileChanged);

% Per-component import flags and editable project channel names.
mapping = uitable(layout, ...
    'Data',mappings{1}, ...
    'ColumnName',{'Source channel','Import','Project channel','Color'}, ...
    'ColumnEditable',[false true true true], ...
    'ColumnFormat',{'char','logical','char',cellstr(allowedColorNames)}, ...
    'ColumnWidth',{'auto',55,'auto',90}, ...
    'CellEditCallback',@mappingEdited, ...
    'CellSelectionCallback',@componentSelected);
mapping.Layout.Row = 2;
mapping.Layout.Column = 1;

% ImageAxes provides native channel navigation, contrast, and composite preview.
previewPanel = uipanel(layout,'Title','Source preview', ...
    'BackgroundColor',[.12 .12 .12]);
previewPanel.Layout.Row = 2;
previewPanel.Layout.Column = 2;
previewGrid = uigridlayout(previewPanel,[1 1], ...
    'Padding',0,'RowHeight',{'1x'},'ColumnWidth',{'1x'});
preview = matlabx.ui.axes.ImageAxes(previewGrid, ...
    'Name','AuxiliaryChannelPreview', ...
    'ImageData',sources(1), ...
    'Tools',{'Zoom','Colorbar'}, ...
    'Colormap',gray(256));

% Existing project names remind users which semantic identities can be reused.
existingNames = [registry.Channels.Name];

if isempty(existingNames)
    hintText = "Check channels to import and edit their project channel names.";
else
    hintText = "Existing project channels: " + strjoin(existingNames,", ");
end

buttons = uigridlayout(layout,[1 4], ...
    'ColumnWidth',{'1x','fit','fit','fit'},'RowHeight',{'fit'}, ...
    'Padding',0,'ColumnSpacing',8);
buttons.Layout.Row = 3;
buttons.Layout.Column = [1 2];
hint = uilabel(buttons,'Text',char(hintText));
hint.Layout.Column = 1;
applyMatching = uibutton(buttons, ...
    'Text','Apply mappings to matching channels', ...
    'ButtonPushedFcn',@applyMatchingMappings);
applyMatching.Layout.Column = 2;
cancel = uibutton(buttons,'Text','Cancel','ButtonPushedFcn',@cancelImport);
cancel.Layout.Column = 3;
confirm = uibutton(buttons,'Text','Import','ButtonPushedFcn',@confirmImport);
confirm.Layout.Column = 4;

% Empty output distinguishes cancellation from a confirmed import plan.
plan = struct( ...
    'Image',{},'Input',{},'ComponentIndex',{},'ChannelName',{},'ChannelColor',{});
uiwait(dialog);

    function index = currentImageIndex()
    %CURRENTIMAGEINDEX Resolve the target dropdown's stable image ID.

        index = find([images.ID] == string(target.Value),1);
    end

    function targetChanged(~,~)
    %TARGETCHANGED Display the source and mappings paired with the new target.

        imageIndex = currentImageIndex();
        file.Value = fileForImage(imageIndex);
        showFile(fileForImage(imageIndex));
    end

    function fileChanged(~,~)
    %FILECHANGED Swap unique source-file assignments between target images.

        imageIndex = currentImageIndex();
        requested = double(file.Value);
        previous = fileForImage(imageIndex);
        other = find(fileForImage == requested,1);

        if ~isempty(other) && other ~= imageIndex
            fileForImage(other) = previous;
        end

        fileForImage(imageIndex) = requested;
        showFile(requested);
    end

    function showFile(fileIndex)
    %SHOWFILE Keep only the newly selected source loaded for preview.

        if fileIndex ~= previewFileIndex
            nextSource = sources(fileIndex);

            % Load first so a read failure leaves the existing preview intact.
            nextSource.load();
            sources(previewFileIndex).unload();
            previewFileIndex = fileIndex;
        end

        mapping.Data = mappings{fileIndex};
        preview.ImageData = sources(fileIndex);
        preview.C = 1;
        preview.ShowComposite = 'off';
    end

    function mappingEdited(~,~)
    %MAPPINGEDITED Retain table edits with the currently paired source file.

        imageIndex = currentImageIndex();
        mappings{fileForImage(imageIndex)} = mapping.Data;
    end

    function applyMatchingMappings(~,~)
    %APPLYMATCHINGMAPPINGS Copy current choices by exact metadata channel name.

        mappingEdited([],[]);
        imageIndex = currentImageIndex();
        currentFileIndex = fileForImage(imageIndex);
        currentRows = mappings{currentFileIndex};
        updatedRows = 0;
        updatedFiles = 0;

        % Each other source keeps its own row order; only normalized metadata
        % names establish correspondence with the currently displayed source.
        for fileIndex = 1:numel(mappings)

            if fileIndex == currentFileIndex
                continue;
            end

            rows = mappings{fileIndex};
            fileWasUpdated = false;

            for currentRow = 1:size(currentRows,1)
                sourceName = strtrim(string(currentRows{currentRow,1}));
                candidateNames = strtrim(string(rows(:,1)));
                matchingRows = find(strcmpi(candidateNames,sourceName));

                for matchingRow = reshape(matchingRows,1,[])
                    rows(matchingRow,2:4) = currentRows(currentRow,2:4);
                    updatedRows = updatedRows+1;
                    fileWasUpdated = true;
                end
            end

            mappings{fileIndex} = rows;
            updatedFiles = updatedFiles+double(fileWasUpdated);
        end

        if updatedRows == 0
            hint.Text = 'No matching source-channel names were found in other files.';
        else
            hint.Text = sprintf( ...
                'Updated %d matching channel(s) across %d other file(s).', ...
                updatedRows,updatedFiles);
        end
    end

    function componentSelected(~,event)
    %COMPONENTSELECTED Navigate the preview to the selected mapping row.

        if ~isempty(event.Indices)
            preview.C = event.Indices(1);
        end
    end

    function cancelImport(~,~)
    %CANCELIMPORT Release uncommitted sources and close without a plan.

        for openedSource = reshape(sources,1,[])
            openedSource.unload();
        end

        uiresume(dialog);
        delete(dialog);
    end

    function confirmImport(~,~)
    %CONFIRMIMPORT Validate every mapping and return a model-ready import plan.

        mappingEdited([],[]);
        nextPlan = struct( ...
            'Image',{},'Input',{},'ComponentIndex',{},'ChannelName',{},'ChannelColor',{});

        for imageIndex = 1:numel(images)
            fileIndex = fileForImage(imageIndex);
            rows = mappings{fileIndex};
            selected = find(cell2mat(rows(:,2)));
            names = strtrim(string(rows(selected,3)));
            colors = string(rows(selected,4));

            if any(names == "")
                uialert(dialog,'Every imported component needs a project channel name.', ...
                    'Missing channel name','Icon','warning');
                return;
            end

            if numel(unique(lower(names))) ~= numel(names)
                uialert(dialog, ...
                    'A target image cannot map two components to the same project channel.', ...
                    'Duplicate channel mapping','Icon','warning');
                return;
            end

            % Reusing a registered semantic name must also reuse its color.
            for selectedIndex = 1:numel(selected)
                definition = registry.findByName(names(selectedIndex));

                if isempty(definition)
                    continue;
                end

                expected = matlabx.ui.axes.ImageAxes.canonicalComponentColorName( ...
                    matlabx.colors.names.fromRGB(definition.Color,"Palette","MATLAB"));

                if ~strcmpi(colors(selectedIndex),expected)
                    uialert(dialog, ...
                        sprintf('%s is already registered with the color %s.', ...
                        names(selectedIndex),expected), ...
                        'Channel color mismatch','Icon','warning');
                    return;
                end
            end

            for row = reshape(selected,1,[])
                component = sources(fileIndex).getComponent(row);

                if ~component.IsScalar || component.SizeZ ~= 1 || component.SizeT ~= 1
                    uialert(dialog, ...
                        sprintf('%s must resolve to one scalar Z/T plane.',rows{row,1}), ...
                        'Unsupported channel shape','Icon','warning');
                    return;
                end

                if component.SizeY ~= images(imageIndex).Input.SizeY || ...
                        component.SizeX ~= images(imageIndex).Input.SizeX
                    uialert(dialog, ...
                        sprintf('%s does not match the target image dimensions.',rows{row,1}), ...
                        'Image size mismatch','Icon','warning');
                    return;
                end

                nextPlan(end+1) = struct( ... %#ok<AGROW>
                    'Image',images(imageIndex), ...
                    'Input',sources(fileIndex), ...
                    'ComponentIndex',row, ...
                    'ChannelName',strtrim(string(rows{row,3})), ...
                    'ChannelColor',matlabx.colors.names.toRGB( ...
                    string(rows{row,4}),"Palette","MATLAB"));
            end
        end

        % A newly introduced semantic name has one project-wide color even
        % when it is mapped from several files in the same batch.
        plannedNames = lower(string({nextPlan.ChannelName}));

        for plannedName = unique(plannedNames)
            matching = plannedNames == plannedName;
            plannedColors = vertcat(nextPlan(matching).ChannelColor);

            if size(unique(plannedColors,'rows'),1) > 1
                displayName = nextPlan(find(matching,1)).ChannelName;
                uialert(dialog, ...
                    sprintf('%s must use the same color for every target image.',displayName), ...
                    'Channel color mismatch','Icon','warning');
                return;
            end
        end

        % Imported assignments retain file-backed sources, while resident
        % preview pixels are no longer needed after the dialog closes.
        for sourceToClose = reshape(sources,1,[])
            sourceToClose.unload();
        end

        plan = nextPlan;
        uiresume(dialog);
        delete(dialog);
    end
end
