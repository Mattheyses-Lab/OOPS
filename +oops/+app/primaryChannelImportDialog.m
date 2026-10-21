% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function plan = primaryChannelImportDialog(parent,inputs,imageNames,registry)
%PRIMARYCHANNELIMPORTDIALOG Map polarization inputs to semantic channels.

arguments
    parent (1,1) matlab.ui.Figure
    inputs (:,1) matlabx.image.Image5D
    imageNames (:,1) string
    registry (1,1) oops.model.ChannelRegistry
end

if numel(inputs) ~= numel(imageNames)
    error('oops:app:PrimaryChannelInputCountMismatch', ...
        'Every primary input needs one image name.');
end

% ImageAxes categorical colors and existing semantic identities constrain
% the editable table values without coupling the model to UI controls.
allowedColors = string(matlabx.ui.axes.ImageAxes.getColorNames());
existingDefinitions = registry.Channels;
existingNames = string({existingDefinitions.Name});
channelChoices = ["New channel..." existingNames];

% One mapping row belongs to each selected input and survives list navigation.
mappings = cell(numel(inputs),1);

for inputIndex = 1:numel(inputs)
    [sourceName,sourceColor] = sourceChannelMetadata(inputs(inputIndex));
    definition = registry.findByName(sourceName);

    if isempty(definition)
        selectedChannel = "New channel...";
        projectName = sourceName;
        projectColor = sourceColor;
    else
        selectedChannel = definition.Name;
        projectName = definition.Name;
        projectColor = canonicalColor(definition.Color,"gray");
    end

    mappings{inputIndex} = table( ...
        sourceName, ...
        categorical(selectedChannel,channelChoices,'Ordinal',true), ...
        projectName, ...
        categorical(projectColor,allowedColors,'Ordinal',true), ...
        'VariableNames',{'SourceChannel','ProjectChannel','Name','Color'});
end

% The single-column figure mirrors one half of the auxiliary import dialog.
screen = get(groot,'ScreenSize');
mainPadding = 5;
mainRowSpacing = 5;
fixedRowHeight = 110+190+24;
initialChrome = 2*matlabx.UICal.uipanelTopChromeHeightPx(12);
fixedWidth = 2*mainPadding;
fixedHeight = 2*mainPadding+3*mainRowSpacing+fixedRowHeight;
viewerSize = floor(min([500,screen(3)-80-fixedWidth, ...
    screen(4)-120-fixedHeight-initialChrome]));
viewerSize = max(1,viewerSize);

dialog = uifigure( ...
    'Name','Assign primary channels', ...
    'Color',parent.Color, ...
    'Position',[0 0 viewerSize+fixedWidth ...
        viewerSize+initialChrome+fixedHeight], ...
    'WindowStyle','alwaysontop', ...
    'Visible','off', ...
    'Resize','on', ...
    'AutoResizeChildren','off', ...
    'CloseRequestFcn',@cancelImport);
oops.app.centerDialog(dialog);

layout = uigridlayout(dialog,[4 1], ...
    'RowHeight',{110,'1x',190,24},'ColumnWidth',{'1x'}, ...
    'Padding',mainPadding,'RowSpacing',mainRowSpacing,'ColumnSpacing',5);

% Input navigation remains separate from editable semantic channel identity.
listPanel = uipanel(layout,'Title','Primary input images');
listPanel.Layout.Row = 1;
listGrid = uigridlayout(listPanel,[1 1], ...
    'Padding',0,'RowSpacing',5,'ColumnSpacing',5);
inputList = uilistbox(listGrid, ...
    'Items',cellstr(imageNames), ...
    'ItemsData',num2cell(1:numel(inputs)), ...
    'Value',1, ...
    'ValueChangedFcn',@inputChanged);

% A centered square host reserves the same panel and ImageAxes chrome used
% by the main viewers and auxiliary import dialog.
viewerHost = uigridlayout(layout,[3 3], ...
    'RowHeight',{0,1,0},'ColumnWidth',{0,1,0}, ...
    'Padding',0,'RowSpacing',0,'ColumnSpacing',0, ...
    'BackgroundColor',[.12 .12 .12]);
viewerHost.Layout.Row = 2;

viewerPanel = uipanel(viewerHost, ...
    'Title','Primary intensity preview', ...
    'BackgroundColor',[.12 .12 .12], ...
    'FontSize',12);
viewerPanel.Layout.Row = 2;
viewerPanel.Layout.Column = 2;
viewerGrid = uigridlayout(viewerPanel,[1 1], ...
    'Padding',0,'RowSpacing',5,'ColumnSpacing',5);
preview = matlabx.ui.axes.ImageAxes(viewerGrid, ...
    'Name','PrimaryChannelPreview', ...
    'Tools',{'Zoom','Colorbar'}, ...
    'ComponentColorMode','colors', ...
    'ComponentColors',{char(string(mappings{1}.Color(1)))}, ...
    'Colormap',gray(256));

% A panel parent lets the table fill its complete allocation on every resize.
mappingHost = uigridlayout(layout,[1 1], ...
    'RowHeight',{'1x'},'ColumnWidth',{'1x'}, ...
    'Padding',0,'RowSpacing',0,'ColumnSpacing',0);
mappingHost.Layout.Row = 3;
mappingPanel = uipanel(mappingHost,'BorderType','none');
mapping = uitable(mappingPanel, ...
    'Units','normalized', ...
    'Position',[0 0 1 1], ...
    'Data',mappings{1}, ...
    'ColumnName',{'Source channel','Project channel','Name','Color'}, ...
    'RowName',{}, ...
    'ColumnEditable',[false true true true], ...
    'ColumnWidth','auto', ...
    'CellEditCallback',@mappingEdited);

footer = uigridlayout(layout,[1 4], ...
    'ColumnWidth',{'1x','fit','fit','fit'},'RowHeight',{'1x'}, ...
    'Padding',0,'RowSpacing',5,'ColumnSpacing',5);
footer.Layout.Row = 4;
hint = uilabel(footer, ...
    'Text','Map each primary input to a project channel.');
applyMatching = uibutton(footer, ...
    'Text','Apply mapping to matching channels', ...
    'ButtonPushedFcn',@applyMatchingMappings);
cancel = uibutton(footer,'Text','Cancel','ButtonPushedFcn',@cancelImport);
confirm = uibutton(footer,'Text','Import','ButtonPushedFcn',@confirmImport);
hint.Layout.Column = 1;
applyMatching.Layout.Column = 2;
cancel.Layout.Column = 3;
confirm.Layout.Column = 4;

resizeUpdatePending = false;
dialog.SizeChangedFcn = @(src,~) resizeDialogContent(src);

% Empty output distinguishes cancellation from a confirmed mapping plan.
plan = struct('Input',{},'ImageName',{},'ChannelName',{},'ChannelColor',{});
showInput(1);
drawnow;
resizeDialogContent(dialog);
dialog.Visible = 'on';
uiwait(dialog);

    function inputChanged(~,~)
    %INPUTCHANGED Show the selected input and its retained mapping row.

        showInput(double(inputList.Value));
    end

    function showInput(index)
    %SHOWINPUT Build one raw average preview without caching analytical output.

        mapping.Data = mappings{index};
        preview.ImageData = averagePreview(inputs(index));
        preview.ComponentColorMode = 'colors';
        preview.ComponentColors = {char(string(mappings{index}.Color(1)))};
    end

    function mappingEdited(~,event)
    %MAPPINGEDITED Keep shared definitions immutable during import mapping.

        index = double(inputList.Value);
        rows = mapping.Data;

        if ~isempty(event) && ~isempty(event.Indices)
            column = event.Indices(2);

            if column == 2
                selected = string(rows.ProjectChannel(1));

                if selected ~= "New channel..."
                    definition = registry.findByName(selected);
                    rows.Name(1) = definition.Name;
                    rows.Color(1) = categorical( ...
                        canonicalColor(definition.Color,"gray"), ...
                        allowedColors,'Ordinal',true);
                end
            elseif ismember(column,[3 4]) && ...
                    string(rows.ProjectChannel(1)) ~= "New channel..."
                rows.ProjectChannel(1) = categorical( ...
                    "New channel...",channelChoices,'Ordinal',true);
            end
        end

        mappings{index} = rows;
        mapping.Data = rows;
        preview.ComponentColors = {char(string(rows.Color(1)))};
    end

    function applyMatchingMappings(~,~)
    %APPLYMATCHINGMAPPINGS Copy the current mapping by source metadata name.

        mappingEdited([],[]);
        currentIndex = double(inputList.Value);
        current = mappings{currentIndex};
        matches = 0;

        for mappingIndex = 1:numel(mappings)
            if mappingIndex == currentIndex || ~strcmpi( ...
                    strtrim(mappings{mappingIndex}.SourceChannel(1)), ...
                    strtrim(current.SourceChannel(1)))
                continue;
            end

            mappings{mappingIndex}.ProjectChannel(1) = current.ProjectChannel(1);
            mappings{mappingIndex}.Name(1) = current.Name(1);
            mappings{mappingIndex}.Color(1) = current.Color(1);
            matches = matches+1;
        end

        hint.Text = sprintf('Updated %d matching primary input(s).',matches);
    end

    function confirmImport(~,~)
    %CONFIRMIMPORT Validate definitions and return one mapping per input.

        mappingEdited([],[]);
        nextPlan = repmat(struct( ...
            'Input',matlabx.image.Image5D.empty(0,1), ...
            'ImageName',"",'ChannelName',"",'ChannelColor',[0 0 0]), ...
            numel(inputs),1);

        for inputIndex = 1:numel(inputs)
            rows = mappings{inputIndex};
            name = strtrim(rows.Name(1));

            if name == ""
                uialert(dialog,'Every primary channel needs a name.', ...
                    'Missing channel name','Icon','warning');
                return;
            end

            selected = string(rows.ProjectChannel(1));
            [~,color] = matlabx.image.normalizeComponentColor( ...
                string(rows.Color(1)));

            if selected ~= "New channel..."
                definition = registry.findByName(selected);
                name = definition.Name;
                color = definition.Color;
            else
                % Typing an existing unique name is an explicit reuse request,
                % even if the dropdown was left on New channel.
                definition = registry.findByName(name);

                if ~isempty(definition)
                    name = definition.Name;
                    color = definition.Color;
                end
            end

            nextPlan(inputIndex) = struct( ...
                'Input',inputs(inputIndex), ...
                'ImageName',imageNames(inputIndex), ...
                'ChannelName',name, ...
                'ChannelColor',color);
        end

        % A new semantic name has one color throughout the complete batch.
        names = lower(string({nextPlan.ChannelName}));

        for name = unique(names)
            colors = vertcat(nextPlan(names == name).ChannelColor);

            if size(unique(colors,'rows'),1) > 1
                uialert(dialog, ...
                    sprintf('%s must use one project color.', ...
                    nextPlan(find(names == name,1)).ChannelName), ...
                    'Channel color mismatch','Icon','warning');
                return;
            end
        end

        plan = nextPlan;
        uiresume(dialog);
        delete(dialog);
    end

    function cancelImport(~,~)
    %CANCELIMPORT Close without transferring ownership of staged inputs.

        for input = reshape(inputs,1,[])
            input.unload();
        end

        uiresume(dialog);
        delete(dialog);
    end

    function resizeDialogContent(sourceFigure)
    %RESIZEDIALOGCONTENT Center one square viewer in the flexible row.

        if isempty(sourceFigure) || ~isvalid(sourceFigure) || ...
                ~isvalid(viewerHost) || resizeUpdatePending
            return;
        end

        resizeUpdatePending = true;
        cleanup = onCleanup(@() releaseResizeGuard());
        figureWidth = round(sourceFigure.InnerPosition(3));
        figureHeight = round(sourceFigure.InnerPosition(4));
        hostWidth = max(1,figureWidth-sum(layout.Padding([1 3])));
        hostHeight = max(1,figureHeight-sum(layout.Padding([2 4]))- ...
            layout.RowHeight{1}-layout.RowHeight{3}-layout.RowHeight{4}- ...
            3*layout.RowSpacing);
        chrome = 2*matlabx.UICal.uipanelTopChromeHeightPx(preview.FontSize);
        panelWidth = max(1,min(hostWidth,hostHeight-chrome));
        panelHeight = panelWidth+chrome;
        horizontal = max(0,floor((hostWidth-panelWidth)/2));
        vertical = max(0,floor((hostHeight-panelHeight)/2));
        set(viewerHost, ...
            'RowHeight',{vertical,panelHeight,vertical}, ...
            'ColumnWidth',{horizontal,panelWidth,horizontal});
    end

    function releaseResizeGuard()
    %RELEASERESIZEGUARD Permit the next figure resize update.

        resizeUpdatePending = false;
    end
end

function [name,color] = sourceChannelMetadata(input)
%SOURCECHANNELMETADATA Read the first polarization frame's acquisition metadata.

locations = oops.io.fourAngleLocations(input);
component = input.getComponent(locations(1,1));
name = strtrim(string(component.Name));

if name == ""
    name = "Primary channel";
end

color = canonicalColor(component.Color,"gray");
end

function color = canonicalColor(value,fallback)
%CANONICALCOLOR Convert metadata RGB to an ImageAxes-supported color name.

color = oops.render.canonicalComponentColor(value);

if color == ""
    color = string(fallback);
end
end

function data = averagePreview(input)
%AVERAGEPREVIEW Average the four raw polarization frames for display only.

locations = oops.io.fourAngleLocations(input);
frames = cell(1,size(locations,1));

for k = 1:size(locations,1)
    frames{k} = input.getPlane( ...
        locations(k,1),locations(k,2),locations(k,3));
end

stack = cat(3,frames{:});
values = mean(stack,3);

if isinteger(stack)
    values = cast(round(values),'like',stack);
end

data = matlabx.image.Image5D.fromComponents(values,Names="Average intensity");
end
