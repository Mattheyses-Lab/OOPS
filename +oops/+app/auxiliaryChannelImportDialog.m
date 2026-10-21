% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function plan = auxiliaryChannelImportDialog(parent,images,files,registry)
%AUXILIARYCHANNELIMPORTDIALOG Pair files and map components to semantic channels.

arguments
    parent (1,1) matlab.ui.Figure
    images (:,1) oops.model.Image
    files (:,1) string
    registry (1,1) oops.model.ChannelRegistry
end

if numel(images) ~= numel(files)
    error('oops:app:AuxiliaryFileCountMismatch', ...
        'Select exactly one auxiliary file for each target image.');
end

% Immediate feedback while Bio-Formats opens metadata and the first preview.
oops.Log.INFO(sprintf('Preparing auxiliary import for %d image(s).',numel(files)));
progress = uiprogressdlg(parent, ...
    'Title','Import auxiliary channels', ...
    'Message','Preparing auxiliary sources...', ...
    'Value',0);
progressCleanup = onCleanup(@() closeProgress(progress));

% File-backed sources provide component metadata before their pixels are loaded.
sources = matlabx.image.Image5D.empty(0,1);

try
    for k = 1:numel(files)
        oops.runtime.updateProgress(progress,sprintf( ...
            'File %d/%d: %s\nReading image metadata...', ...
            k,numel(files),files(k)),.6*(k-1)/max(1,numel(files)));
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
    oops.runtime.updateProgress(progress,sprintf( ...
        'File %d/%d: %s\nPreparing channel mappings...', ...
        k,numel(files),files(k)),.6+.2*(k-1)/max(1,numel(files)));
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

    % Categorical color values render as constrained dropdown cells with a
    % visible disclosure arrow. Project names remain free text by design.
    colorChoices = categorical(sourceColors,allowedColorNames,'Ordinal',true);
    mappings{k} = table( ...
        sourceNames, ...
        false(source.NumComponents,1), ...
        sourceNames, ...
        colorChoices, ...
        'VariableNames',{'SourceChannel','Import','ProjectChannel','Color'});
end

% Keep exactly the displayed source resident so ImageAxes receives complete
% component data ranges and can use its normal contrast behavior.
previewFileIndex = 1;

try
    oops.runtime.updateProgress(progress, ...
        "Loading the first auxiliary preview...",.85);
    sources(previewFileIndex).load();
catch ME

    for sourceToClose = reshape(sources,1,[])
        sourceToClose.unload();
    end

    rethrow(ME);
end

% Initial geometry gives each viewer host exactly one square image area plus
% its two title bars, leaving no centering padding on any side of either host.
screen = get(groot,'ScreenSize');
mainPadding = 5;
mainRowSpacing = 5;
mainColumnSpacing = 5;
fixedRowHeight = 110+190+24;
initialChrome = 2*matlabx.UICal.uipanelTopChromeHeightPx(12);
fixedWidth = 2*mainPadding+mainColumnSpacing;
fixedHeight = 2*mainPadding+3*mainRowSpacing+fixedRowHeight;
viewerSize = floor(min([ ...
    500, ...
    (screen(3)-80-fixedWidth)/2, ...
    screen(4)-120-fixedHeight-initialChrome]));
viewerSize = max(1,viewerSize);
width = 2*viewerSize+fixedWidth;
height = viewerSize+initialChrome+fixedHeight;
dialog = uifigure( ...
    'Name','Import auxiliary channels', ...
    'Position',[0 0 width height], ...
    'WindowStyle','alwaysontop', ...
    'Visible','off', ...
    'Resize','on', ...
    'CloseRequestFcn',@cancelImport, ...
    'AutoResizeChildren','off');
oops.app.centerDialog(dialog);

layout = uigridlayout(dialog,[4 2], ...
    'RowHeight',{110,'1x',190,24},'ColumnWidth',{'1x','1x'}, ...
    'Padding',mainPadding, ...
    'RowSpacing',mainRowSpacing, ...
    'ColumnSpacing',mainColumnSpacing);

% Parallel lists make the complete one-to-one source assignment visible.
targetPanel = uipanel(layout,'Title','Target images');
targetPanel.Layout.Row = 1;
targetPanel.Layout.Column = 1;
targetGrid = uigridlayout(targetPanel,[1 1], ...
    'Padding',0,'RowSpacing',5,'ColumnSpacing',5, ...
    'RowHeight',{'1x'},'ColumnWidth',{'1x'});
targetList = uilistbox(targetGrid, ...
    'Items',cellstr([images.Name]), ...
    'ItemsData',cellstr([images.ID]), ...
    'Value',char(images(1).ID), ...
    'ValueChangedFcn',@targetChanged);

sourcePanel = uipanel(layout,'Title','Pending auxiliary sources');
sourcePanel.Layout.Row = 1;
sourcePanel.Layout.Column = 2;
sourceGrid = uigridlayout(sourcePanel,[1 1], ...
    'Padding',0,'RowSpacing',5,'ColumnSpacing',5, ...
    'RowHeight',{'1x'},'ColumnWidth',{'1x'});

% Short display names keep the list readable; ItemsData retains source identity.
[~,sourceBaseNames,sourceExtensions] = fileparts(files);
sourceDisplayNames = sourceBaseNames+sourceExtensions;
sourceList = uilistbox(sourceGrid, ...
    'Items',cellstr(sourceDisplayNames), ...
    'ItemsData',num2cell(1:numel(files)), ...
    'Value',1, ...
    'ValueChangedFcn',@fileChanged);

% The target viewer shows the corrected average used throughout the project.
targetHost = uigridlayout(layout,[3 3], ...
    'RowHeight',{0,1,0},'ColumnWidth',{0,1,0}, ...
    'Padding',0,'RowSpacing',0,'ColumnSpacing',0, ...
    'BackgroundColor',[.12 .12 .12]);
targetHost.Layout.Row = 2;
targetHost.Layout.Column = 1;

targetViewerPanel = uipanel(targetHost, ...
    'Title','Average intensity', ...
    'BackgroundColor',[.12 .12 .12], ...
    'FontSize',12);
targetViewerPanel.Layout.Row = 2;
targetViewerPanel.Layout.Column = 2;
targetViewerGrid = uigridlayout(targetViewerPanel,[1 1], ...
    'Padding',0,'RowSpacing',5,'ColumnSpacing',5, ...
    'RowHeight',{'1x'},'ColumnWidth',{'1x'});
targetPreview = matlabx.ui.axes.ImageAxes(targetViewerGrid, ...
    'Name','AuxiliaryTargetPreview', ...
    'Tools',{'Zoom','Colorbar'}, ...
    'ComponentColorMode','luts', ...
    'Colormap',gray(256));

% A separate centered host preserves a square auxiliary image beside the target.
auxiliaryHost = uigridlayout(layout,[3 3], ...
    'RowHeight',{0,1,0},'ColumnWidth',{0,1,0}, ...
    'Padding',0,'RowSpacing',0,'ColumnSpacing',0, ...
    'BackgroundColor',[.12 .12 .12]);
auxiliaryHost.Layout.Row = 2;
auxiliaryHost.Layout.Column = 2;

% ImageAxes provides native channel navigation, contrast, and composite preview.
auxiliaryViewerPanel = uipanel(auxiliaryHost, ...
    'Title','Auxiliary source', ...
    'BackgroundColor',[.12 .12 .12], ...
    'FontSize',12);
auxiliaryViewerPanel.Layout.Row = 2;
auxiliaryViewerPanel.Layout.Column = 2;
auxiliaryViewerGrid = uigridlayout(auxiliaryViewerPanel,[1 1], ...
    'Padding',0,'RowSpacing',5,'ColumnSpacing',5, ...
    'RowHeight',{'1x'},'ColumnWidth',{'1x'});
auxiliaryPreview = matlabx.ui.axes.ImageAxes(auxiliaryViewerGrid, ...
    'Name','AuxiliaryChannelPreview', ...
    'ImageData',sources(1), ...
    'Tools',{'Zoom','Colorbar'}, ...
    'ComponentColorMode','colors', ...
    'Colormap',gray(256));
syncPreviewColors(1);
oops.runtime.updateProgress(progress,"Preparing the target preview...",.92);
showTarget(1);

% A full-width panel lets the table fill its allocation without manual sizing.
mappingHost = uigridlayout(layout,[1 1], ...
    'RowHeight',{'1x'},'ColumnWidth',{'1x'}, ...
    'Padding',0,'RowSpacing',0,'ColumnSpacing',0);
mappingHost.Layout.Row = 3;
mappingHost.Layout.Column = [1 2];

mappingPanel = uipanel(mappingHost,'BorderType','none');
mappingPanel.Layout.Row = 1;
mappingPanel.Layout.Column = 1;

% Per-component import flags and editable project channel names span the dialog.
mapping = uitable(mappingPanel, ...
    'Units','normalized', ...
    'Position',[0 0 1 1], ...
    'Data',mappings{1}, ...
    'ColumnName',{'Source channel','Import','Project channel','Color'}, ...
    'RowName',{}, ...
    'ColumnEditable',[false true true true], ...
    'ColumnWidth','auto', ...
    'CellEditCallback',@mappingEdited, ...
    'CellSelectionCallback',@componentSelected);

% Existing project names remind users which semantic identities can be reused.
existingNames = [registry.Channels.Name];

if isempty(existingNames)
    hintText = "Check channels to import and edit their project channel names.";
else
    hintText = "Existing project channels: " + strjoin(existingNames,", ");
end

buttons = uigridlayout(layout,[1 4], ...
    'ColumnWidth',{'1x','fit','fit','fit'},'RowHeight',{'1x'}, ...
    'Padding',0,'RowSpacing',5,'ColumnSpacing',5);
buttons.Layout.Row = 4;
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

% Resize state prevents nested updates while shared viewer geometry is applied.
resizeUpdatePending = false;

% Size after all children exist so web-control positions are current.
dialog.SizeChangedFcn = @(src,~) resizeDialogContent(src);
drawnow;
resizeDialogContent(dialog);
oops.runtime.updateProgress(progress,"Auxiliary import dialog ready.",1);
delete(progressCleanup);
closeProgress(progress);
dialog.Visible = 'on';
drawnow;
resizeDialogContent(dialog);
oops.Log.INFO("Auxiliary channel import dialog ready.");

% Empty output distinguishes cancellation from a confirmed import plan.
plan = struct( ...
    'Image',{},'Input',{},'ComponentIndex',{},'ChannelName',{},'ChannelColor',{});
uiwait(dialog);

    function index = currentImageIndex()
    %CURRENTIMAGEINDEX Resolve the target list's stable image ID.

        index = find([images.ID] == string(targetList.Value),1);
    end

    function targetChanged(~,~)
    %TARGETCHANGED Display the source and mappings paired with the new target.

        imageIndex = currentImageIndex();
        sourceList.Value = fileForImage(imageIndex);
        showTarget(imageIndex);
        showFile(fileForImage(imageIndex));
    end

    function fileChanged(~,~)
    %FILECHANGED Swap unique source-file assignments between target images.

        imageIndex = currentImageIndex();
        requested = double(sourceList.Value);
        previous = fileForImage(imageIndex);
        other = find(fileForImage == requested,1);

        if ~isempty(other) && other ~= imageIndex
            fileForImage(other) = previous;
        end

        fileForImage(imageIndex) = requested;
        showFile(requested);
    end

    function showTarget(imageIndex)
    %SHOWTARGET Display the selected target's durable average intensity.

        image = images(imageIndex);

        % Average intensity is normally resident; saved projects reconstruct it
        % on demand from the same correction path used by the main application.
        values = oops.analysis.Analyzer.ensureAverageIntensity(image);
        values = oops.render.intensityDisplayValues(image,values);
        targetPreview.ImageData = matlabx.image.Image5D.fromComponents( ...
            values,Names="Average intensity");
        targetViewerPanel.Title = 'Average intensity';
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
        auxiliaryPreview.ImageData = sources(fileIndex);
        auxiliaryPreview.C = 1;
        auxiliaryPreview.ShowComposite = 'off';
        syncPreviewColors(fileIndex);
    end

    function mappingEdited(~,event)
    %MAPPINGEDITED Retain table edits with the currently paired source file.

        imageIndex = currentImageIndex();
        fileIndex = fileForImage(imageIndex);
        mappings{fileIndex} = mapping.Data;

        % A color edit updates the matching component without replacing data.
        if ~isempty(event) && ~isempty(event.Indices) && event.Indices(2) == 4
            row = event.Indices(1);
            auxiliaryPreview.setComponentColor(string(mapping.Data.Color(row)),row);
        end
    end

    function syncPreviewColors(fileIndex)
    %SYNCPREVIEWCOLORS Apply the current mapping colors in component order.

        rows = mappings{fileIndex};
        auxiliaryPreview.ComponentColorMode = 'colors';
        auxiliaryPreview.ComponentColors = cellstr(string(rows.Color))';
    end

    function resizeDialogContent(sourceFigure)
    %RESIZEDIALOGCONTENT Preserve square geometry for both preview viewers.

        if isempty(sourceFigure) || ~isvalid(sourceFigure) || ...
                ~isvalid(mapping) || ...
                ~isvalid(targetHost) || ~isvalid(auxiliaryHost)
            return;
        end

        if resizeUpdatePending
            return;
        end

        resizeUpdatePending = true;
        pendingCleanup = onCleanup(@() clearResizeUpdatePending());

        % The figure reports its new inner size before child layout positions
        % necessarily catch up, so derive the viewer allocation directly from it.
        figureWidth = round(sourceFigure.InnerPosition(3));
        figureHeight = round(sourceFigure.InnerPosition(4));

        % Subtract the main grid's fixed horizontal and vertical allocations.
        availableWidth = figureWidth-sum(layout.Padding([1 3]))-layout.ColumnSpacing;
        hostWidth = max(1,floor(availableWidth/2));
        hostHeight = max(1,figureHeight-sum(layout.Padding([2 4]))- ...
            layout.RowHeight{1}-layout.RowHeight{3}-layout.RowHeight{4}- ...
            3*layout.RowSpacing);

        % Both viewers use the same chrome and future host allocation, so one
        % calculation produces one shared panel size.
        chrome = matlabx.UICal.uipanelTopChromeHeightPx(targetPreview.FontSize) * 2;

        % if width+chrome>height -> set width based on height
        if hostWidth + chrome > hostHeight
            panelHeight = max(chrome+1,hostHeight);
            panelWidth = max(1,panelHeight-chrome);

            top = 0;
            bottom = 0;
            left = floor((hostWidth-panelWidth)/2);
            right = left;
        else % set height based on width
            panelWidth = max(1,hostWidth);
            panelHeight = max(chrome+1,panelWidth+chrome);

            left = 0;
            right = 0;
            top = floor((hostHeight-panelHeight)/2);
            bottom = top;
        end

        % Apply the complete 3-by-3 layout to both hosts atomically.
        set([targetHost auxiliaryHost], ...
            'RowHeight',{top,panelHeight,bottom}, ...
            'ColumnWidth',{left,panelWidth,right});
    end

    function clearResizeUpdatePending()
    %CLEARRESIZEUPDATEPENDING Release the resize coalescing guard.

        resizeUpdatePending = false;
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
                sourceName = strtrim(currentRows.SourceChannel(currentRow));
                candidateNames = strtrim(rows.SourceChannel);
                matchingRows = find(strcmpi(candidateNames,sourceName));

                for matchingRow = reshape(matchingRows,1,[])
                    rows.Import(matchingRow) = currentRows.Import(currentRow);
                    rows.ProjectChannel(matchingRow) = currentRows.ProjectChannel(currentRow);
                    rows.Color(matchingRow) = currentRows.Color(currentRow);
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
            auxiliaryPreview.C = event.Indices(1);
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
            selected = find(rows.Import);
            names = strtrim(rows.ProjectChannel(selected));
            colors = string(rows.Color(selected));

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
                        sprintf('%s must resolve to one scalar Z/T plane.',rows.SourceChannel(row)), ...
                        'Unsupported channel shape','Icon','warning');
                    return;
                end

                if component.SizeY ~= images(imageIndex).Input.SizeY || ...
                        component.SizeX ~= images(imageIndex).Input.SizeX
                    uialert(dialog, ...
                        sprintf('%s does not match the target image dimensions.',rows.SourceChannel(row)), ...
                        'Image size mismatch','Icon','warning');
                    return;
                end

                [~,channelColor] = matlabx.image.normalizeComponentColor( ...
                    string(rows.Color(row)));
                nextPlan(end+1) = struct( ... %#ok<AGROW>
                    'Image',images(imageIndex), ...
                    'Input',sources(fileIndex), ...
                    'ComponentIndex',row, ...
                    'ChannelName',strtrim(rows.ProjectChannel(row)), ...
                    'ChannelColor',channelColor);
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

function closeProgress(progress)
%CLOSEPROGRESS Close a still-valid preparation dialog during every exit path.

if ~isempty(progress) && isvalid(progress)
    close(progress);
end
end
