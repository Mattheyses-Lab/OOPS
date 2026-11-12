classdef ImageAxesExportDialog
%IMAGEAXESEXPORTDIALOG Collect options for exporting an ImageAxes view.
%   OPTIONS = matlabx.ui.axes.ImageAxesExportDialog.prompt() opens a
%   modal accordion dialog. OPTIONS is empty when the dialog is cancelled.

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

        function options = prompt()
        %PROMPT Open the export-options dialog and return accepted settings.
            background = [.12 .12 .12];
            paneColor = [.18 .18 .18];
            controlColor = [.3 .3 .3];
            fontColor = [.85 .85 .85];
            controlFontColor = [.9 .9 .9];
            options = [];

            fig = uifigure(Visible="off",Name="Export Current View", ...
                InnerPosition=[0 0 470 420],Resize="off", ...
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

            optionsPane = addSection("Options",7);
            format = addDropDown(optionsPane,1,"Format", ...
                {'PNG','TIFF','JPEG'},'PNG');
            units = addDropDown(optionsPane,2,"Units", ...
                {'inches','centimeters','pixels','points'},'inches');
            width = addNumeric(optionsPane,3,"Width",3);
            height = addNumeric(optionsPane,4,"Height",3);
            preserveAspect = addCheckBox(optionsPane,5, ...
                "Preserve aspect ratio",true);
            resolution = addNumeric(optionsPane,6,"Resolution (DPI)",600);
            overlaySizing = addDropDown(optionsPane,7,"Overlay sizing", ...
                {'Preserve physical sizes','Scale with output'}, ...
                'Preserve physical sizes');

            buttons = uigridlayout(root,[1 3],Padding=0,RowSpacing=0, ...
                ColumnSpacing=5,ColumnWidth={'1x',80,80},RowHeight={'fit'}, ...
                BackgroundColor=background);
            buttons.Layout.Row = 2;
            cancel = uibutton(buttons,Text="Cancel", ...
                BackgroundColor=controlColor,FontColor=controlFontColor, ...
                ButtonPushedFcn=@(~,~) closeDialog());
            cancel.Layout.Column = 2;
            continueButton = uibutton(buttons,Text="Continue", ...
                BackgroundColor=[.18 .42 .68],FontColor=[1 1 1], ...
                ButtonPushedFcn=@(~,~) acceptDialog());
            continueButton.Layout.Column = 3;

            movegui(fig,"center");
            fig.Visible = "on";
            uiwait(fig);
            if isgraphics(fig), delete(fig); end

            function pane = addSection(title,rowCount)
            %ADDSECTION Add and expand one consistently styled accordion item.
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
            %ADDLABEL Add a standard left-column settings label.
                label = uilabel(pane,Text=text,FontColor=fontColor);
                label.Layout.Row = row;
                label.Layout.Column = 1;
            end

            function control = addDropDown(pane,row,label,items,value)
            %ADDDROPDOWN Add a styled dropdown and its label.
                addLabel(pane,row,label);
                control = uidropdown(pane,Items=items,Value=value, ...
                    BackgroundColor=controlColor,FontColor=controlFontColor);
                control.Layout.Row = row;
                control.Layout.Column = 2;
            end

            function control = addNumeric(pane,row,label,value)
            %ADDNUMERIC Add a styled numeric field and its label.
                addLabel(pane,row,label);
                control = uieditfield(pane,"numeric",Value=value, ...
                    BackgroundColor=controlColor,FontColor=controlFontColor);
                control.Layout.Row = row;
                control.Layout.Column = 2;
            end

            function control = addCheckBox(pane,row,label,value)
            %ADDCHECKBOX Add a checkbox and its separate row label.
                addLabel(pane,row,label);
                control = uicheckbox(pane,Text="",Value=value, ...
                    FontColor=controlFontColor);
                control.Layout.Row = row;
                control.Layout.Column = 2;
            end

            function acceptDialog()
            %ACCEPTDIALOG Validate settings and return normalized options.
                positive = [width.Value,height.Value];
                if any(~isfinite(positive)) || any(positive <= 0)
                    uialert(fig,"Width and height must be positive finite values.", ...
                        "Invalid Export Options");
                    return;
                end
                if ~isfinite(resolution.Value) || resolution.Value <= 0 || ...
                        resolution.Value ~= fix(resolution.Value)
                    uialert(fig,"Resolution must be a positive whole number.", ...
                        "Invalid Export Options");
                    return;
                end

                [extension,formatName] = selectedFormat();
                preserve = "off";
                if preserveAspect.Value, preserve = "on"; end
                sizing = "scale";
                if strcmp(overlaySizing.Value,'Preserve physical sizes')
                    sizing = "physical";
                end
                options = struct( ...
                    "Format",formatName, ...
                    "Extension",extension, ...
                    "Units",string(units.Value), ...
                    "Width",width.Value, ...
                    "Height",height.Value, ...
                    "PreserveAspectRatio",preserve, ...
                    "Resolution",resolution.Value, ...
                    "OverlaySizing",sizing);
                uiresume(fig);
            end

            function [extension,formatName] = selectedFormat()
            %SELECTEDFORMAT Return the selected format's extension and name.
                formatName = string(format.Value);
                switch formatName
                    case "PNG"
                        extension = ".png";
                    case "TIFF"
                        extension = ".tif";
                    case "JPEG"
                        extension = ".jpg";
                end
            end

            function closeDialog()
            %CLOSEDIALOG Cancel the dialog and safely release uiwait.
                options = [];
                if isgraphics(fig)
                    uiresume(fig);
                    delete(fig);
                end
            end
        end

    end

end
