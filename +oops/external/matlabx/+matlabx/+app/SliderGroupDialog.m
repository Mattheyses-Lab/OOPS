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

classdef SliderGroupDialog < handle
    %SLIDERGROUPDIALOG Small figure containing a mutable vertical slider group.
    %
    %   SliderGroupDialog owns one figure and a stack of matlabx.ui.control.Slider
    %   controls. The slider group can be updated dynamically, including a
    %   change in slider count, without replacing the figure window.

    properties
        Title                   (:,1) char = 'Slider group dialog'
        Name                    (1,:) cell = {'Slider'}
        Limits                  (1,:) cell = {[0 1]}
        Value                   (1,:) cell = {[0 1]}
        RoundValues             (1,:) cell = {"on"}
        RoundDigits             (1,:) cell = {0}
        ValueDisplayFormat      (1,:) cell = {'%d'}
        Colormap                (1,:) cell = {gray(256)}
        ValueChangedFcn         (:,1) function_handle = function_handle.empty
        ValueChangingFcn        (:,1) function_handle = function_handle.empty
        ClosedFcn               (:,1) function_handle = function_handle.empty
    end

    properties (Access=private,Transient,NonCopyable)
        Fig matlab.ui.Figure
        Grid matlab.ui.container.GridLayout
        Slider matlabx.ui.control.Slider
    end

    methods

        function obj = SliderGroupDialog(N,opts)
        %SLIDERGROUPDIALOG Create a slider group dialog.
            arguments
                N                            (1,1) double = 1
                opts.Title                   (:,1) char = 'Slider group dialog'
                opts.Name                    (1,:) cell = {'Slider'}
                opts.Limits                  (1,:) cell = {[0 1]}
                opts.Value                   (1,:) cell = {[0 1]}
                opts.RoundValues             (1,:) cell = {"on"}
                opts.RoundDigits             (1,:) cell = {0}
                opts.ValueDisplayFormat      (1,:) cell = {'%d'}
                opts.Colormap                (1,:) cell = {gray(256)}
                opts.ValueChangedFcn         (:,1) function_handle = function_handle.empty
                opts.ValueChangingFcn        (:,1) function_handle = function_handle.empty
                opts.ClosedFcn               (:,1) function_handle = function_handle.empty
            end

            % apply inputs
            fn = fieldnames(opts);
            for i = 1:numel(fn), obj.(fn{i}) = opts.(fn{i}); end

            % Figure window. The grid and sliders are intentionally created
            % by updateGroup so later count changes can reuse this same figure.
            obj.Fig = uifigure("WindowStyle","alwaysontop",...
                "Name",obj.Title,...
                "Position",[0 0 300 50],...
                "AutoResizeChildren","off",...
                "CloseRequestFcn",@(~,~) obj.onCloseFigure(),...
                "DeleteFcn",@(~,~) obj.delete());

            obj.updateGroup(N, ...
                "Name", obj.Name, ...
                "Limits", obj.Limits, ...
                "Value", obj.Value, ...
                "RoundValues", obj.RoundValues, ...
                "RoundDigits", obj.RoundDigits, ...
                "ValueDisplayFormat", obj.ValueDisplayFormat, ...
                "Colormap", obj.Colormap);

            % Center the figure
            movegui(obj.Fig, "center");

        end

    end





    %% Internal callbacks
    methods (Access=private)

        function onSliderChanging(obj, src, idx)
            % Trigger the value changed callback if set
            if ~isempty(obj.ValueChangingFcn)
                evt = obj.buildEventStruct(src,idx);
                obj.ValueChangingFcn(src, evt);
            end
        end

        function onSliderChanged(obj, src, idx)
            % Trigger the value changed callback if set
            if ~isempty(obj.ValueChangedFcn)
                evt = obj.buildEventStruct(src,idx);
                obj.ValueChangedFcn(src, evt);
            end
        end

        function onCloseFigure(obj)
            % Trigger the closed callback if set
            if ~isempty(obj.ClosedFcn)
                obj.ClosedFcn();
            end
            % delete self
            delete(obj.Fig);
        end

    end


    methods (Access=private)
        function S = buildEventStruct(~,src,idx)
            S = struct('Source',src,'ID',idx);
        end
    end


    methods

        function delete(obj)
            % delete components and figure
            if ~isempty(obj.Slider), delete(obj.Slider(isvalid(obj.Slider))); end
            if ~isempty(obj.Grid), delete(obj.Grid(isvalid(obj.Grid))); end
            if ~isempty(obj.Fig), delete(obj.Fig(isvalid(obj.Fig))); end
        end

        function show(obj)
        %SHOW Bring the dialog figure to the front.
            if isempty(obj.Fig) || ~isvalid(obj.Fig)
                return
            end

            obj.Fig.Visible = "on";
            figure(obj.Fig);
        end

        function updateSlider(obj, idx, opts)
        %UPDATESLIDER Refresh one slider without rebuilding the dialog.
            arguments
                obj
                idx (1,1) double {mustBeInteger, mustBePositive}
                opts.Name {mustBeTextScalar} = ""
                opts.Limits double = []
                opts.Value double = []
                opts.RoundValues (1,1) matlab.lang.OnOffSwitchState = "on"
                opts.RoundDigits double = []
                opts.ValueDisplayFormat {mustBeTextScalar} = ""
                opts.Colormap double = []
            end

            if isempty(obj.Slider) || idx > numel(obj.Slider) || ~isvalid(obj.Slider(idx))
                return
            end

            slider = obj.Slider(idx);

            if strlength(string(opts.Name)) > 0
                obj.Name{idx} = char(opts.Name);
                slider.Title = char(opts.Name);
            end

            if ~isempty(opts.Limits)
                obj.Limits{idx} = opts.Limits;
                slider.Limits = opts.Limits;
            end

            slider.RoundValues = opts.RoundValues;
            obj.RoundValues{idx} = opts.RoundValues;

            if ~isempty(opts.RoundDigits)
                obj.RoundDigits{idx} = opts.RoundDigits;
                slider.RoundDigits = opts.RoundDigits;
            end

            if strlength(string(opts.ValueDisplayFormat)) > 0
                obj.ValueDisplayFormat{idx} = char(opts.ValueDisplayFormat);
                slider.ValueDisplayFormat = char(opts.ValueDisplayFormat);
            end

            if ~isempty(opts.Colormap)
                obj.Colormap{idx} = opts.Colormap;
                slider.Colormap = opts.Colormap;
            end

            if ~isempty(opts.Value)
                obj.Value{idx} = opts.Value;
                slider.Value = opts.Value;
            end
        end

        function updateGroup(obj, N, opts)
        %UPDATEGROUP Update slider count and slider state in the same figure.
            arguments
                obj
                N (1,1) double {mustBeInteger, mustBePositive}
                opts.Name (1,:) cell = obj.Name
                opts.Limits (1,:) cell = obj.Limits
                opts.Value (1,:) cell = obj.Value
                opts.RoundValues (1,:) cell = obj.RoundValues
                opts.RoundDigits (1,:) cell = obj.RoundDigits
                opts.ValueDisplayFormat (1,:) cell = obj.ValueDisplayFormat
                opts.Colormap (1,:) cell = obj.Colormap
            end

            obj.Name = obj.expandCell_(opts.Name, N, {'Slider'});
            obj.Limits = obj.expandCell_(opts.Limits, N, {[0 1]});
            obj.Value = obj.expandCell_(opts.Value, N, {[0 1]});
            obj.RoundValues = obj.expandCell_(opts.RoundValues, N, {"on"});
            obj.RoundDigits = obj.expandCell_(opts.RoundDigits, N, {0});
            obj.ValueDisplayFormat = obj.expandCell_(opts.ValueDisplayFormat, N, {'%d'});
            obj.Colormap = obj.expandCell_(opts.Colormap, N, {gray(256)});

            if obj.sliderCount_() ~= N
                obj.rebuildSliders_(N);
            end

            for idx = 1:N
                obj.updateSlider(idx, ...
                    "Name", obj.Name{idx}, ...
                    "Limits", obj.Limits{idx}, ...
                    "Value", obj.Value{idx}, ...
                    "RoundValues", obj.RoundValues{idx}, ...
                    "RoundDigits", obj.RoundDigits{idx}, ...
                    "ValueDisplayFormat", obj.ValueDisplayFormat{idx}, ...
                    "Colormap", obj.Colormap{idx});
            end

            obj.resizeFigureToSliders_();
        end


    end


    methods (Access=private)
        function rebuildSliders_(obj, N)
        %REBUILDSLIDERS_ Replace grid/sliders while preserving the figure.
            if ~isempty(obj.Slider)
                delete(obj.Slider(isvalid(obj.Slider)));
            end
            obj.Slider = matlabx.ui.control.Slider.empty();

            if ~isempty(obj.Grid) && isvalid(obj.Grid)
                delete(obj.Grid);
            end

            obj.Grid = uigridlayout(obj.Fig,[N 1], ...
                'ColumnWidth',{'1x'}, ...
                'RowHeight',repmat({'fit'},N,1), ...
                'ColumnSpacing',5, ...
                'RowSpacing',5, ...
                'Padding',[5 5 5 5],...
                'BackgroundColor',[0.12 0.12 0.12]);

            for idx = 1:N
                obj.Slider(idx) = matlabx.ui.control.Slider(obj.Grid,...
                    "Title",obj.Name{idx},...
                    "FontColor",[1 1 1],...
                    "BackgroundColor",[0.12 0.12 0.12],...
                    "Limits",obj.Limits{idx},...
                    "Value",obj.Value{idx},...
                    "RoundValues",obj.RoundValues{idx},...
                    "RoundDigits",obj.RoundDigits{idx},...
                    "ValueDisplayFormat",obj.ValueDisplayFormat{idx},...
                    "Colormap",obj.Colormap{idx},...
                    "ValueChangingFcn",@(src,~) obj.onSliderChanging(src,idx),...
                    "ValueChangedFcn",@(src,~) obj.onSliderChanged(src,idx));
            end
        end

        function resizeFigureToSliders_(obj)
        %RESIZEFIGURETOSLIDERS_ Fit figure height to current slider count.
            N = obj.sliderCount_();
            if N == 0 || isempty(obj.Fig) || ~isvalid(obj.Fig)
                return
            end

            obj.Fig.InnerPosition(4) = obj.Slider(1).ComponentHeight*N + 10 + N*5;
        end

        function N = sliderCount_(obj)
        %SLIDERCOUNT_ Return number of valid slider controls.
            if isempty(obj.Slider)
                N = 0;
            else
                N = nnz(isvalid(obj.Slider));
            end
        end

        function out = expandCell_(~, value, N, fallback)
        %EXPANDCELL_ Expand scalar/short cell option values to N entries.
            if isempty(value)
                value = fallback;
            end

            if ~iscell(value)
                value = {value};
            end

            out = cell(1, N);
            for idx = 1:N
                if idx <= numel(value)
                    out{idx} = value{idx};
                elseif isscalar(value)
                    out{idx} = value{1};
                else
                    out{idx} = fallback{1};
                end
            end
        end
    end


end
