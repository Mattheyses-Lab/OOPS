classdef PlotAxesExportDialog
%PLOTAXESEXPORTDIALOG Collect PlotAxes file and host-style export options.
%
%   OPTIONS = matlabx.ui.axes.PlotAxesExportDialog.prompt(HOST) opens a
%   compact accordion dialog. Vector and raster output types expose only
%   compatible formats, and raster resolution is enabled only for images.
%   Host styling is returned as export-scoped data; the dialog does not
%   permanently modify HOST.
%
% The dialog intentionally owns only host-level and file options. A future
% content contribution contract can add a third accordion section without
% requiring PlotAxes to reflect arbitrary renderer style properties.

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

    methods (Static)

        function options = prompt(host)
        %PROMPT Open the modal export dialog and return accepted options.

            arguments
                host (1,1) matlabx.ui.axes.PlotAxes
            end

            background = [.12 .12 .12];
            paneColor = [.18 .18 .18];
            controlColor = [.3 .3 .3];
            fontColor = [.85 .85 .85];
            controlFontColor = [.9 .9 .9];
            options = [];

            fig = uifigure(Visible="off",Name="Export Plot", ...
                InnerPosition=[0 0 470 600],Resize="off", ...
                WindowStyle="modal",Color=background, ...
                CloseRequestFcn=@(~,~) closeDialog());
            root = uigridlayout(fig,[2 1],Padding=[10 10 10 10], ...
                RowSpacing=10,ColumnSpacing=0,BackgroundColor=background, ...
                RowHeight={'1x','fit'},ColumnWidth={'1x'});

            accordionHost = uigridlayout(root,[1 1],Padding=0, ...
                RowSpacing=0,ColumnSpacing=0,BackgroundColor=background, ...
                RowHeight={'fit'},ColumnWidth={'1x'},Scrollable="on");
            accordionHost.Layout.Row = 1;
            accordion = matlabx.ui.container.Accordion(accordionHost, ...
                ItemSpacing=5,BorderWidth=0,BorderColor=paneColor, ...
                Padding=0,BackgroundColor=background);

            filePane = addSection("File Options",8);
            outputType = addDropDown(filePane,1,"Output type", ...
                {'Vector','Image'},'Vector');
            format = addDropDown(filePane,2,"Format",{'PDF','SVG'},'SVG');
            units = addDropDown(filePane,3,"Units", ...
                {'inches','centimeters','pixels','points'},'inches');
            width = addNumeric(filePane,4,"Width",7);
            height = addNumeric(filePane,5,"Height",5);
            preserveAspect = addCheckBox(filePane,6,"Preserve aspect ratio",false);
            resolution = addNumeric(filePane,7,"Resolution (DPI)",300);
            [useExportBackground,exportBackground] = addOptionalColor( ...
                filePane,8,"Background color",host.BackgroundColor,false);

            stylePane = addSection("Axes Styling",10);
            [useAxesColor,axesColorPicker] = addOptionalColor( ...
                stylePane,1,"Axes color", ...
                pickerColor(host.Color,host.BackgroundColor),false);
            foregroundPicker = addColor(stylePane,2,"Foreground",host.ForegroundColor);
            fontNames = string(listfonts);
            if ~any(fontNames == host.FontName)
                fontNames = [host.FontName;fontNames(:)];
            end
            fontName = addDropDown(stylePane,3,"Font name", ...
                cellstr(fontNames),char(host.FontName));
            fontUnits = addDropDown(stylePane,4,"Font units", ...
                {'points','pixels'},char(host.FontUnits));
            fontSize = addNumeric(stylePane,5,"Tick-label font size",host.FontSize);
            labelMultiplier = addNumeric(stylePane,6,"Label size multiplier", ...
                host.LabelFontSizeMultiplier);
            titleMultiplier = addNumeric(stylePane,7,"Title size multiplier", ...
                host.TitleFontSizeMultiplier);
            gridVisible = addCheckBox(stylePane,8,"Show grid",logical(host.GridVisible));
            boxVisible = addCheckBox(stylePane,9,"Show box",logical(host.BoxVisible));
            titleVisible = addCheckBox(stylePane,10,"Show title", ...
                logical(host.TitleVisible));

            outputType.ValueChangedFcn = @(~,~) updateOutputType();
            useExportBackground.ValueChangedFcn = ...
                @(~,~) updateColorPicker(useExportBackground,exportBackground);
            useAxesColor.ValueChangedFcn = ...
                @(~,~) updateColorPicker(useAxesColor,axesColorPicker);
            updateOutputType();
            updateColorPicker(useExportBackground,exportBackground);
            updateColorPicker(useAxesColor,axesColorPicker);

            buttons = uigridlayout(root,[1 3],Padding=0,RowSpacing=0, ...
                ColumnSpacing=5,ColumnWidth={'1x',80,80},RowHeight={'fit'}, ...
                BackgroundColor=background);
            buttons.Layout.Row = 2;
            cancel = uibutton(buttons,Text="Cancel", ...
                BackgroundColor=controlColor,FontColor=controlFontColor, ...
                ButtonPushedFcn=@(~,~) closeDialog());
            cancel.Layout.Column = 2;
            export = uibutton(buttons,Text="Continue", ...
                BackgroundColor=[.18 .42 .68],FontColor=[1 1 1], ...
                ButtonPushedFcn=@(~,~) acceptDialog());
            export.Layout.Column = 3;

            movegui(fig,"center");
            fig.Visible = "on";
            uiwait(fig);
            if isgraphics(fig), delete(fig); end

            function pane = addSection(title,rowCount)
                accordion.addItem(Title=title,BorderColor=[.49 .49 .49], ...
                    TitleBackgroundColor=background, ...
                    HoverTitleBackgroundColor=controlColor, ...
                    PaneBackgroundColor=paneColor,FontColor=fontColor, ...
                    BorderWidth=1,ExpandedBorderWidth=1,TitlePadding=1);
                item = accordion.getItem(title);
                item.expand();
                pane = item.Pane;
                set(pane,ColumnWidth={'fit','1x'}, ...
                    RowHeight=repmat({'fit'},1,rowCount), ...
                    Padding=[5 5 5 5],ColumnSpacing=5,RowSpacing=5, ...
                    BackgroundColor=paneColor);
            end

            function label = addLabel(pane,row,text)
                label = uilabel(pane,Text=text,FontColor=fontColor);
                label.Layout.Row = row;
                label.Layout.Column = 1;
            end

            function control = addDropDown(pane,row,label,items,value)
                addLabel(pane,row,label);
                control = uidropdown(pane,Items=items,Value=value, ...
                    BackgroundColor=controlColor,FontColor=controlFontColor);
                control.Layout.Row = row;
                control.Layout.Column = 2;
            end

            function control = addNumeric(pane,row,label,value)
                addLabel(pane,row,label);
                control = uieditfield(pane,"numeric",Value=value, ...
                    BackgroundColor=controlColor,FontColor=controlFontColor);
                control.Layout.Row = row;
                control.Layout.Column = 2;
            end

            function control = addCheckBox(pane,row,label,value)
                addLabel(pane,row,label);
                control = uicheckbox(pane,Text="",Value=value, ...
                    FontColor=controlFontColor);
                control.Layout.Row = row;
                control.Layout.Column = 2;
            end

            function control = addColor(pane,row,label,value)
                addLabel(pane,row,label);
                control = uicolorpicker(pane,Value=value);
                control.Layout.Row = row;
                control.Layout.Column = 2;
            end

            function [toggle,picker] = addOptionalColor(pane,row,label,value,enabled)
            %ADDOPTIONALCOLOR Add a checkbox and color picker in one form row.
                addLabel(pane,row,label);
                colorGrid = uigridlayout(pane,[1 2], ...
                    ColumnWidth={'fit','1x'},RowHeight={'fit'}, ...
                    Padding=0,RowSpacing=0,ColumnSpacing=5, ...
                    BackgroundColor=paneColor);
                colorGrid.Layout.Row = row;
                colorGrid.Layout.Column = 2;
                toggle = uicheckbox(colorGrid,Text="",Value=enabled, ...
                    FontColor=controlFontColor);
                toggle.Layout.Column = 1;
                picker = uicolorpicker(colorGrid,Value=value);
                picker.Layout.Column = 2;
            end

            function updateOutputType()
                if string(outputType.Value) == "Vector"
                    format.Items = {'PDF','SVG'};
                    format.Value = 'SVG';
                    resolution.Enable = 'off';
                else
                    format.Items = {'PNG','TIFF'};
                    format.Value = 'PNG';
                    resolution.Enable = 'on';
                end
            end

            function updateColorPicker(toggle,picker)
                picker.Enable = matlab.lang.OnOffSwitchState(toggle.Value);
            end

            function acceptDialog()
                positive = [width.Value,height.Value,fontSize.Value, ...
                    labelMultiplier.Value,titleMultiplier.Value];
                if any(~isfinite(positive)) || any(positive <= 0)
                    uialert(fig,"Sizes and font multipliers must be positive finite values.", ...
                        "Invalid Export Options");
                    return;
                end
                if string(outputType.Value) == "Image" && ...
                        (~isfinite(resolution.Value) || resolution.Value <= 0 || ...
                        resolution.Value ~= fix(resolution.Value))
                    uialert(fig,"Resolution must be a positive whole number.", ...
                        "Invalid Export Options");
                    return;
                end
                [extension,contentType] = selectedFormat();
                preserve = "off";
                if preserveAspect.Value, preserve = "on"; end
                backgroundColor = "none";
                if useExportBackground.Value
                    backgroundColor = exportBackground.Value;
                end
                axesColor = "none";
                if useAxesColor.Value
                    axesColor = axesColorPicker.Value;
                end
                options = struct( ...
                    "ContentType",contentType, ...
                    "Format",string(format.Value), ...
                    "Extension",extension, ...
                    "Units",string(units.Value), ...
                    "Width",width.Value, ...
                    "Height",height.Value, ...
                    "PreserveAspectRatio",preserve, ...
                    "Resolution",resolution.Value, ...
                    "BackgroundColor",backgroundColor, ...
                    "Color",axesColor, ...
                    "ForegroundColor",foregroundPicker.Value, ...
                    "FontName",string(fontName.Value), ...
                    "FontUnits",string(fontUnits.Value), ...
                    "FontSize",fontSize.Value, ...
                    "LabelFontSizeMultiplier",labelMultiplier.Value, ...
                    "TitleFontSizeMultiplier",titleMultiplier.Value, ...
                    "GridVisible",matlab.lang.OnOffSwitchState(gridVisible.Value), ...
                    "BoxVisible",matlab.lang.OnOffSwitchState(boxVisible.Value), ...
                    "TitleVisible",matlab.lang.OnOffSwitchState(titleVisible.Value));
                uiresume(fig);
            end


            function tf = isNoneColor(value)
                tf = (ischar(value) || isstring(value)) && ...
                    strcmpi(string(value),"none");
            end

            function value = pickerColor(color,fallback)
                value = color;
                if isNoneColor(color), value = fallback; end
            end

            function [extension,contentType] = selectedFormat()
                switch string(format.Value)
                    case "PDF"
                        extension = ".pdf";
                        contentType = "vector";
                    case "SVG"
                        extension = ".svg";
                        contentType = "vector";
                    case "PNG"
                        extension = ".png";
                        contentType = "image";
                    case "TIFF"
                        extension = ".tif";
                        contentType = "image";
                end
            end

            function closeDialog()
                options = [];
                if isgraphics(fig)
                    uiresume(fig);
                    delete(fig);
                end
            end
        end

    end

end
