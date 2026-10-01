function colornames_GUI_search(palette,name)
% Interactive real-time COLORNAMES colorname-matching in a UIFIGURE.
%
% (c) 2024-2026 Stephen Cobeldick
%
%%% Syntax %%%
%
%   colornames_GUI_search
%   colornames_GUI_search(palette)
%   colornames_GUI_search(palette,name)
%
%% Examples %%
%
%   colornames_GUI_search()
%
%   colornames_GUI_search('xkcd')
%
%   colornames_GUI_search('HTML4','blue')
%
%% Input Arguments %%
%
%   palette = StringScalar or CharRowVector, the name of a palette supported
%             by COLORNAMES, e.g. "MATLAB", "xkcd", or 'Alphabet', etc.
%   name    = StringScalar or CharRowVector, a color name to be matched
%             to the palette color names.
%
%% Output Arguments %%
%
% None
%
%% Dependencies %%
%
% * MATLAB R2023b or later.
% * colornames.m <www.mathworks.com/matlabcentral/fileexchange/48155>
%
% See also COLORNAMES MAXDISTCOLOR ARBSORT
% COLORNAMES_GUI_CUBE COLORNAMES_GUI_DELTAE COLORNAMES_GUI_VIEW
persistent uifHnd fnhSetVals
% Release | Feature
% --------|--------
% R2023b  | uidropdown ValueIndex property, evt.ValueIndex
% R2021a  | uitextarea & uieditfield placeholder text
% R2020b  | uitextarea WordWrap
% R2019b  | uidropdown, uieditfield, ValueChangingFcn
% R2018b  | uigridlayout
% R2016a  | uifigure, uilabel, uidropdown, uitextarea, uieditfield
% R2009b  | tilde argument placeholder
%
assert(~verLessThan('matlab','23.2'),...
    'SC:colornames_GUI_cube:ReleaseNotSupported',...
    'This MATLAB release is not supported. Requires R2023b or later.')
%
%% Input Wrangling %%
%
isChFH = @(s) ischar(s) && ndims(s)==2 && size(s,1)==1; %#ok<ISMAT>
cPalNm = colornames();
%
% Resolve palette index:
if nargin<1 || isequal(palette,[])
	idxPal = 1+rem(round(now*1e7),numel(cPalNm)); %#ok<TNOW1>
else
	palette = cns1s2c(palette);
	assert(isChFH(palette),...
		'SC:colornames_GUI_search:palette:NotText',...
		'The 1st input <palette> must be a string scalar or a char row vector.')
	idxPal = find(strcmpi(palette,cPalNm));
	assert(isscalar(idxPal),...
		'SC:colornames_GUI_search:palette:UnknownPalette',...
		'Palette "%s" is not supported. Call COLORNAMES() to list all palettes.',palette)
end
%
% Resolve color name string:
if nargin<2 || isequal(name,[])
	inpChV = 'gee';
else
	inpChV = cns1s2c(name);
	assert(isChFH(inpChV),...
		'SC:colornames_GUI_search:name:NotText',...
		'The 2nd input <name> must be a string scalar or a char row vector.')
end
%
%% Ensure Figure %%
%
if isempty(uifHnd) || ~ishghandle(uifHnd)
	[uifHnd,fnhSetVals] = cnsNewFig(cPalNm);
else
	figure(uifHnd);
end
%
fnhSetVals(idxPal,inpChV);
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%colornames_GUI_search
function [uifHnd,svFHnd] = cnsNewFig(pnc)
% Create the graphics objects. Define all callback functions in one workspace.
%
%% Shared State Variables %%
%
lumThr = 0.54; % luminance threshold
idxPal = 1;
clrNm0 = '';
%
%% Create Figure %%
%
uifHnd = uifigure();
uifHnd.Name = 'ColorNames Interactive Name Matching GUI';
uifHnd.Tag              = mfilename();
uifHnd.Visible          =  'on';
uifHnd.NumberTitle      = 'off';
uifHnd.HandleVisibility = 'off';
uifHnd.IntegerHandle    = 'off';
%
uiGrL0 = uigridlayout(uifHnd, [6,2]);
uiGrL0.ColumnWidth = {'1x','1x'};
uiGrL0.RowHeight = {'fit','fit','fit','fit','fit','1x'};
uiGrL0.ColumnSpacing = 3;
uiGrL0.RowSpacing    = 3;
%
lblPal = uilabel(uiGrL0);
lblPal.Visible = 'on';
lblPal.Text = 'Palette';
lblPal.FontWeight = 'bold';
lblPal.HorizontalAlignment = 'center';
lblPal.Layout.Row = 1;
lblPal.Layout.Column = 1;
%
dDnPal = uidropdown(uiGrL0);
dDnPal.Visible = 'on';
dDnPal.Tag = 'Palette';
dDnPal.Tooltip = 'Select the palette to search';
dDnPal.Items = pnc;
dDnPal.ValueIndex = idxPal;
dDnPal.ValueChangedFcn = @cnsPallClBk;
dDnPal.Layout.Row = 2;
dDnPal.Layout.Column = 1;
%
lblInp = uilabel(uiGrL0);
lblInp.Visible = 'on';
lblInp.Text = 'Input Text';
lblInp.FontWeight = 'bold';
lblInp.HorizontalAlignment = 'center';
lblInp.Layout.Row = 1;
lblInp.Layout.Column = 2;
%
eFdInp = uieditfield(uiGrL0, 'text');
eFdInp.Visible = 'on';
eFdInp.Tag = 'ColorName';
eFdInp.Placeholder = 'Enter text to match here';
eFdInp.Tooltip = 'Enter the color name (partial or full), index, or initial to match';
eFdInp.HorizontalAlignment = 'center';
eFdInp.Value = clrNm0;
eFdInp.ValueChangedFcn  = @cnsEditClBk;
eFdInp.ValueChangingFcn = @cnsEditClBk;
eFdInp.Layout.Row = 2;
eFdInp.Layout.Column = 2;
%
lblArr = uilabel(uiGrL0);
lblArr.Visible = 'on';
lblArr.Text = '';
lblArr.FontWeight = 'normal';
lblArr.HorizontalAlignment = 'right';
lblArr.Layout.Row = 3;
lblArr.Layout.Column = [1,2];
%
lblOut = uilabel(uiGrL0);
lblOut.Visible = 'on';
lblOut.Text = 'Color Name Match';
lblOut.FontWeight = 'bold';
lblOut.HorizontalAlignment = 'center';
lblOut.Layout.Row = 3;
lblOut.Layout.Column = [1,2];
%
eFdOut = uieditfield(uiGrL0, 'text');
eFdOut.Visible  = 'on';
eFdOut.Enable   = 'on';
eFdOut.Editable = 'off';
eFdOut.Tag = 'Color Name Match';
eFdOut.Placeholder = 'No color names matched the input text!';
eFdOut.Tooltip = 'The filtered color name with the smallest Levenshtein distance to the input text. This is the output returned by COLORNAMES().';
eFdOut.HorizontalAlignment = 'center';
eFdOut.Layout.Row = 4;
eFdOut.Layout.Column = [1,2];
%
lblFlt = uilabel(uiGrL0);
lblFlt.Visible = 'on';
lblFlt.Text = 'Filtered Palette Color Names';
lblFlt.FontWeight = 'bold';
lblFlt.HorizontalAlignment = 'center';
lblFlt.Layout.Row = 5;
lblFlt.Layout.Column = [1,2];
%
txtFlt = uitextarea(uiGrL0, 'WordWrap','off');
txtFlt.Visible  = 'on';
txtFlt.Enable   = 'on';
txtFlt.Editable = 'off';
txtFlt.Tag = 'Filtered Palette Color Names';
txtFlt.Placeholder = 'No color names matched the input text!';
txtFlt.Tooltip = 'Either 1) one palette color name/index/initial which exactly matches the input text or 2) all palette color names that contain the same characters in the same order as the input text (the characters do not need to be consecutive). The closest match is selected from this list.';
txtFlt.HorizontalAlignment = 'center';
txtFlt.Layout.Row = 6;
txtFlt.Layout.Column = [1,2];
%
% Capture default colors for reset-on-no-match:
fgClrV = eFdOut.FontColor;
bgClrV = eFdOut.BackgroundColor;
%
svFHnd = @cnsSetVals;
%
%% Initialize the Figure %%
%
cnsUpdateTxt()
%
%% Get & Set Functions %%
%
	function cnsSetVals(varargin)
		idxPal = varargin{1};
		clrNm0 = varargin{2};
		dDnPal.ValueIndex = idxPal;
		eFdInp.Value = clrNm0;
		cnsUpdateTxt()
	end
%
%% Callback Functions %%
%
	function cnsEditClBk(~,vcd) % Edit Change CallBack
		clrNm0 = vcd.Value;
		cnsUpdateTxt()
	end
%
	function cnsPallClBk(~,evt) % Palette Menu CallBack
		idxPal = evt.ValueIndex;
		cnsUpdateTxt()
	end
%
	function cnsUpdateTxt() % Update Displayed Text
		try
			[clrNm1,clrRGB,sDebug] = colornames(pnc{idxPal},clrNm0);
		catch
			clrNm1 = [];
		end
		if numel(clrNm1)
			lumVec = clrRGB * [0.298936;0.587043;0.114021];
			idxOne = sDebug(idxPal).match{1};
			cFltNm = sDebug(idxPal).names(abs(idxOne));
			typLbl = ["exact","closest"];
			eFdOut.FontColor = double(repmat(lumVec<lumThr,1,3));
			eFdOut.BackgroundColor = clrRGB;
			eFdOut.Value = clrNm1{1};
			txtFlt.Value = cFltNm(:);
			lblArr.Text = sprintf('%s \x2195',typLbl{1+all(idxOne>0)});
		else
			eFdOut.FontColor = fgClrV;
			eFdOut.BackgroundColor = bgClrV;
			eFdOut.Value = '';
			txtFlt.Value = '';
			lblArr.Text = '';
		end
	end
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnsNewFig
function arr = cns1s2c(arr)
% If scalar string then extract the character vector, otherwise data is unchanged.
if isa(arr,'string') && isscalar(arr)
	arr = arr{1};
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cns1s2c