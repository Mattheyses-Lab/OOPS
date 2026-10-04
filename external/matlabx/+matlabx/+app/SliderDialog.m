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

classdef SliderDialog < handle

    properties
        Title                   (:,1) char = 'Slider dialog'
        Name                    (:,1) char = 'Slider'
        Limits                  (1,2) = [0 1]
        Value                   (1,2) = [0 1]
        RoundValues             (1,1) matlab.lang.OnOffSwitchState = "on"
        RoundDigits             (1,1) double = 0
        ValueDisplayFormat      (1,:) char = '%d'
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

        function obj = SliderDialog(opts)
            arguments
                opts.Title                  (1,:) char = 'Slider dialog'
                opts.Name                   (1,:) char = 'Slider'
                opts.Limits                 (1,2) = [0 1]
                opts.Value                  (1,2) = [0 1]
                opts.RoundValues            (1,1) matlab.lang.OnOffSwitchState = "on"
                opts.RoundDigits            (1,1) double = 0
                opts.ValueDisplayFormat     (1,:) char = '%d'
                opts.ValueChangedFcn        (:,1) function_handle = function_handle.empty
                opts.ValueChangingFcn       (:,1) function_handle = function_handle.empty
                opts.ClosedFcn              (:,1) function_handle = function_handle.empty
            end

            % apply inputs
            fn = fieldnames(opts);
            for i = 1:numel(fn), obj.(fn{i}) = opts.(fn{i}); end

            % Figure window
            obj.Fig = uifigure("WindowStyle","alwaysontop",...
                "Name",obj.Title,...
                "Position",[0 0 300 50],...
                "CloseRequestFcn",@(~,~) obj.onCloseFigure(),...
                "DeleteFcn",@(~,~) obj.delete());

            % Main Grid
            obj.Grid = uigridlayout(obj.Fig,[1 1], ...
                'ColumnWidth',{'1x'}, ...
                'RowHeight',{'fit'}, ...
                'ColumnSpacing',5, ...
                'RowSpacing',5, ...
                'Padding',[5 5 5 5],...
                'BackgroundColor',[0.12 0.12 0.12]);

            % Slider
            obj.Slider = matlabx.ui.control.Slider(obj.Grid,...
                "Title",obj.Name,...
                "FontColor",[1 1 1],...
                "BackgroundColor",[0.12 0.12 0.12],...
                "Limits",obj.Limits,...
                "Value",obj.Value,...
                "RoundValues",obj.RoundValues,...
                "RoundDigits",obj.RoundDigits,...
                "ValueDisplayFormat",obj.ValueDisplayFormat,...
                "ValueChangingFcn",@(src,evt) obj.onSliderChanging(src,evt),...
                "ValueChangedFcn",@(src,evt) obj.onSliderChanged(src,evt));

            obj.Fig.InnerPosition(4) = obj.Slider.ComponentHeight + 10;

            % Center the figure
            movegui(obj.Fig, "center");

        end

    end





    %% Internal callbacks
    methods (Access=private)

        function onSliderChanging(obj, src, evt)
            % Trigger the value changed callback if set
            if ~isempty(obj.ValueChangingFcn)
                obj.ValueChangingFcn(src, evt);
            end
        end

        function onSliderChanged(obj, src, evt)
            % Trigger the value changed callback if set
            if ~isempty(obj.ValueChangedFcn)
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


    methods

        function delete(obj)
            % delete components and figure
            if ~isempty(obj.Slider), delete(obj.Slider(isvalid(obj.Slider))); end
            if ~isempty(obj.Grid), delete(obj.Grid(isvalid(obj.Grid))); end
            if ~isempty(obj.Fig), delete(obj.Fig(isvalid(obj.Fig))); end
        end


    end


end