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

classdef ParamsDialog < handle
    %PARAMSDIALOG Simple Fiji-style parameter dialog built with uifigure.
    %
    % Example
    % -------
    % params = matlabx.app.ParamsDialog.prompt( ...
    %     'Enter parameter values', ...
    %     {'Name','Enter your name','char','', ...
    %         @(x) ~contains(x,'_'), 'Name cannot contain underscores'}, ...
    %     {'Age','Enter your age','double',25, ...
    %         @(x) x>=0 && x<=100, 'Age must be between 0 and 100'}, ...
    %     {'Method','Threshold method','choice','otsu',{'otsu','triangle','manual'}}, ...
    %     {'IsStudent','Are you a student?','logical',false});
    %
    % if isempty(params)
    %     return
    % end
    %
    % name   = params.Name;
    % age    = params.Age;
    % method = params.Method;

    properties (SetAccess=private)
        Title (1,1) string
        Specs cell = {}
        Values struct = struct()
        Cancelled (1,1) logical = true
    end

    properties (Access=private)
        Figure matlab.ui.Figure
        Grid matlab.ui.container.GridLayout
        Controls struct = struct()
    end

    methods (Access=private)
        function self = ParamsDialog(title, specs)
            self.Title = string(title);
            self.Specs = specs;
        end
    end

    methods (Static)
        function params = prompt(title, varargin)
            dlg = matlabx.app.ParamsDialog(title, varargin);
            params = dlg.run();
        end
    end

    methods
        function params = run(self)
            self.buildUI();
            uiwait(self.Figure);

            if ~isvalid(self)
                params = [];
                return
            end

            if self.Cancelled
                params = [];
            else
                params = self.Values;
            end

            if ~isempty(self.Figure) && isvalid(self.Figure)
                delete(self.Figure);
            end
        end
    end

    methods (Access=private)
        function buildUI(self)
            n = numel(self.Specs);

            % flag to track whether the form includes any dropdowns/colorpicker/etc.
            hasDropDown = false;

            figW = 420;
            rowH = 20;
            pad = 10;
            buttonH = 20;
            rowSpacing = 10;
            figH = 2*pad + n*rowH + n*rowSpacing + buttonH;

            self.Figure = uifigure( ...
                'Visible', 'off', ...
                'Name', char(self.Title), ...
                'InnerPosition', [0 0 figW figH], ...
                'Resize', 'off', ...
                'WindowStyle', 'modal', ...
                'CloseRequestFcn', @(src,evt) self.onCancel());

            self.Grid = uigridlayout(self.Figure, [n+1 2]);
            self.Grid.Padding = [pad pad pad pad];
            self.Grid.RowHeight = [repmat({rowH},1,n), {buttonH}];
            self.Grid.ColumnWidth = {140, '1x'};
            self.Grid.RowSpacing = rowSpacing;
            self.Grid.ColumnSpacing = 10;

            for i = 1:n
                S = matlabx.app.ParamsDialog.parseSpec_(self.Specs{i}, i);

                lbl = uilabel(self.Grid, ...
                    'Text', char(S.Label), ...
                    'HorizontalAlignment', 'right');
                lbl.Layout.Row = i;
                lbl.Layout.Column = 1;

                ctrl = self.makeControl_(S);
                ctrl.Layout.Row = i;
                ctrl.Layout.Column = 2;

                self.Controls.(S.Name) = ctrl;

                % take note if we have any dropdowns
                if ~hasDropDown && isa(ctrl,'matlab.ui.control.DropDown') || isa(ctrl,'matlab.ui.control.ColorPicker')
                    hasDropDown = true;
                end
            end

            % if there is at least one dropdown, make sure the figure is tall enough
            if hasDropDown
                self.Figure.InnerPosition(4) = max(figH,400);
            end

            % setup grid for OK and Cancel buttons
            btnGrid = uigridlayout(self.Grid, [1 2]);
            btnGrid.Layout.Row = n + 1;
            btnGrid.Layout.Column = [1 2];
            btnGrid.Padding = [0 0 0 0];
            btnGrid.RowSpacing = 0;
            btnGrid.ColumnSpacing = 10;
            btnGrid.RowHeight = {'1x'};
            btnGrid.ColumnWidth = {'1x','1x'};

            % OK button
            uibutton(btnGrid, ...
                'Text', 'OK', ...
                'ButtonPushedFcn', @(src,evt) self.onOK());

            % Cancel button
            uibutton(btnGrid, ...
                'Text', 'Cancel', ...
                'ButtonPushedFcn', @(src,evt) self.onCancel());

            movegui(self.Figure, "center");
            self.Figure.Visible = 'on';
        end

        function ctrl = makeControl_(self, S)
            switch S.Type
                case {"char","string","double"}
                    ctrl = uieditfield(self.Grid, 'text', ...
                        'Value', matlabx.app.ParamsDialog.toDisplayText_(S.Default));

                case "logical"
                    ctrl = uicheckbox(self.Grid, ...
                        'Value', logical(S.Default), ...
                        'Text', '');

                case "choice"
                    items = string(S.Choices);
                    ctrl = uidropdown(self.Grid, ...
                        'Items', cellstr(items), ...
                        'Value', char(string(S.Default)));

                case "color"
                    ctrl = uicolorpicker(self.Grid, ...
                        'Value', S.Default);

                otherwise
                    error('ParamsDialog:UnsupportedType', ...
                        'Unsupported parameter type "%s".', S.Type);
            end
        end

        function onOK(self)
            values = struct();

            try
                for i = 1:numel(self.Specs)
                    S = matlabx.app.ParamsDialog.parseSpec_(self.Specs{i}, i);
                    ctrl = self.Controls.(S.Name);
                    value = self.readControlValue_(ctrl, S);
                    self.validateValue_(value, S);
                    values.(S.Name) = value;
                end
            catch ME
                uialert(self.Figure, ME.message, 'Invalid Input');
                return
            end

            self.Values = values;
            self.Cancelled = false;
            uiresume(self.Figure);
        end

        function onCancel(self)
            self.Cancelled = true;
            if ~isempty(self.Figure) && isvalid(self.Figure)
                uiresume(self.Figure);
            end
        end

        function value = readControlValue_(self, ctrl, S)
            switch S.Type
                case "string"
                    value = string(ctrl.Value);

                case {"char","choice"}
                    value = char(ctrl.Value);

                case "double"
                    value = str2double(ctrl.Value);
                    if isnan(value)
                        error('ParamsDialog:ConversionFailed', ...
                            'Parameter "%s" must be a valid number.', char(S.Label));
                    end

                case "logical"
                    value = logical(ctrl.Value);

                case "color"
                    value = ctrl.Value;

                otherwise
                    error('ParamsDialog:UnsupportedType', ...
                        'Unsupported parameter type "%s".', S.Type);
            end
        end

        function validateValue_(self, value, S)
            if isempty(S.Validator)
                return
            end

            try
                ok = S.Validator(value);
            catch ME
                error('ParamsDialog:ValidatorError', ...
                    'Validator failed for parameter "%s": %s', ...
                    char(S.Label), ME.message);
            end

            if ~(isscalar(ok) && islogical(ok))
                error('ParamsDialog:ValidatorReturnType', ...
                    'Validator for parameter "%s" must return a scalar logical.', ...
                    char(S.Label));
            end

            if ~ok
                if strlength(S.ValidatorMessage) > 0
                    error('ParamsDialog:ValidationFailed', '%s', char(S.ValidatorMessage));
                else
                    error('ParamsDialog:ValidationFailed', ...
                        'Parameter "%s" failed validation.', char(S.Label));
                end
            end
        end
    end

    methods (Static, Access=private)
        function S = parseSpec_(spec, idx)
            if ~iscell(spec) || numel(spec) < 3
                error('ParamsDialog:InvalidSpec', ...
                    'Spec %d must contain at least {name,label,type}.', idx);
            end

            name = string(spec{1});
            label = string(spec{2});
            type = lower(string(spec{3}));

            if ~isvarname(char(name))
                error('ParamsDialog:InvalidName', ...
                    'Parameter name "%s" is not a valid MATLAB variable name.', char(name));
            end

            validTypes = ["char","string","double","logical","choice","color"];
            if ~any(type == validTypes)
                error('ParamsDialog:InvalidType', ...
                    'Spec %d type must be one of: %s.', ...
                    idx, strjoin(cellstr(validTypes), ', '));
            end

            S = struct( ...
                'Name', char(name), ...
                'Label', label, ...
                'Type', type, ...
                'Default', [], ...
                'Choices', {{}}, ...
                'Validator', [], ...
                'ValidatorMessage', "" );

            switch type
                case "choice"
                    S = matlabx.app.ParamsDialog.parseChoiceSpec_(S, spec, idx);
                otherwise
                    S = matlabx.app.ParamsDialog.parseStandardSpec_(S, spec, idx);
            end
        end

        function S = parseStandardSpec_(S, spec, idx)
            n = numel(spec);

            if n >= 4
                S.Default = spec{4};
            else
                S.Default = matlabx.app.ParamsDialog.defaultValueForType_(S.Type);
            end

            if n >= 5
                if ~isempty(spec{5}) && ~isa(spec{5}, 'function_handle')
                    error('ParamsDialog:InvalidValidator', ...
                        'Spec %d validator must be a function handle.', idx);
                end
                S.Validator = spec{5};
            end

            if n >= 6
                S.ValidatorMessage = string(spec{6});
            end
        end

        function S = parseChoiceSpec_(S, spec, idx)
            n = numel(spec);

            if n < 5
                error('ParamsDialog:InvalidChoiceSpec', ...
                    'Choice spec %d must be at least {name,label,''choice'',default,choices}.', idx);
            end

            S.Default = spec{4};
            S.Choices = spec{5};

            if ~(iscell(S.Choices) || isstring(S.Choices) || ischar(S.Choices))
                error('ParamsDialog:InvalidChoices', ...
                    'Choices for spec %d must be a cell array, char array, or string array.', idx);
            end

            choices = string(S.Choices);
            if isempty(choices)
                error('ParamsDialog:EmptyChoices', ...
                    'Choice parameter "%s" must have at least one choice.', char(S.Name));
            end

            if ~any(choices == string(S.Default))
                error('ParamsDialog:DefaultNotInChoices', ...
                    'Default value for choice parameter "%s" must be one of the provided choices.', ...
                    char(S.Name));
            end

            if n >= 6
                if ~isempty(spec{6}) && ~isa(spec{6}, 'function_handle')
                    error('ParamsDialog:InvalidValidator', ...
                        'Spec %d validator must be a function handle.', idx);
                end
                S.Validator = spec{6};
            end

            if n >= 7
                S.ValidatorMessage = string(spec{7});
            end
        end

        function value = defaultValueForType_(type)
            switch type
                case {"char","string"}
                    value = '';
                case "double"
                    value = '';
                case "logical"
                    value = false;
                case "color"
                    value = [1 1 1];
                otherwise
                    value = [];
            end
        end

        function txt = toDisplayText_(value)
            if isstring(value)
                txt = char(value);
            elseif ischar(value)
                txt = value;
            elseif isempty(value)
                txt = '';
            elseif isnumeric(value) && isscalar(value)
                txt = num2str(value);
            elseif isnumeric(value) && ~isscalar(value)
                txt = mat2str(value);
            else
                error('ParamsDialog:InvalidDefault', ...
                    'Default value could not be converted to display text.');
            end
        end
    end
end