function colornames_GUI_view(palette, order)
% Interactive viewing of COLORNAMES palettes in a UIFIGURE. Sorts colors by name/colorspace.
%
% (c) 2014-2026 Stephen Cobeldick
%
%%% Syntax %%%
%
%   colornames_GUI_view
%   colornames_GUI_view(palette)
%   colornames_GUI_view(palette,order)
%
% Create a uifigure displaying all of the colors from any palette supported
% by the function COLORNAMES. The palette and sort order can be selected
% by drop-down menu or by optional inputs. The colors may be sorted:
%
% * in natural order (i.e. taking into account any numeric values, including leading indices), or
% * alphabetically (ignoring any leading indices), or
% * by colorspace: Lab, LCh, XYZ, YUV, HSV, or RGB.
%
% Color tiles are push buttons: clicking selects/deselects; at most one
% tile is selected at a time. The edit field shows the selected color's
% hex code, decimal RGB triplet, and name, and also accepts typed input.
%
%% Input Arguments %%
%
%   palette = StringScalar or CharRowVector, the name of a palette supported
%             by COLORNAMES, e.g. "MATLAB", "xkcd", or 'Alphabet', etc.
%   order   = StringScalar or CharRowVector, 'Alphabetic' or 'NaturalOrder'
%             or the colorspace dimensions in the desired order, e.g.:
%             'Lab', 'abL', 'bLa', ... 'XYZ', ... 'RGB', 'RBG', ... etc.
%
%% Output Arguments %%
%
% None
%
%% Dependencies %%
%
% * MATLAB R2020b or later.
% * colornames.m <www.mathworks.com/matlabcentral/fileexchange/48155>
%
% See also COLORNAMES MAXDISTCOLOR ARBSORT
% COLORNAMES_GUI_CUBE COLORNAMES_GUI_DELTAE COLORNAMES_GUI_SEARCH
persistent figHnd fnhSetVals
% Release | Feature
% --------|--------
% R2020b  | uigridlayout, uipanel Scrollable property, scroll()
% R2019b  | disableDefaultInteractivity, uibutton, uidropdown, uieditfield
% R2017b  | lsqminnorm
% R2016a  | uifigure, uiaxes
% R2009b  | tilde argument placeholder
%
assert(~verLessThan('matlab','9.9'),...
	'SC:colornames_GUI_cube:ReleaseNotSupported',...
	'This MATLAB release is not supported. Requires R2020b or later.') %#ok<VERLESSMATLAB>
%
%% Input Wrangling %%
%
isChFH = @(s) ischar(s) && ndims(s)==2 && size(s,1)==1; %#ok<ISMAT>
%
[cPalNm,cCSpFn,sDebug] = colornames();
%
if nargin<1
	idxPal = find(strcmpi(cPalNm,'MATLAB'));
	if isempty(idxPal)
		idxPal = 1;
	end
else
	palette = cnv1s2c(palette);
	assert(isChFH(palette), ...
		'SC:colornames_GUI_view:palette:NotText', ...
		'The first input <palette> must be a string scalar or a char row vector.')
	idxPal = find(strcmpi(palette, cPalNm));
	assert(isscalar(idxPal), ...
		'SC:colornames_GUI_view:palette:UnknownPalette', ...
		'Palette "%s" is not supported. Call COLORNAMES() to list all palettes.', palette)
end
%
% Every permutation of each colorspace is a valid sort key:
srtNoA = {'NaturalOrder'; 'Alphabetic'};
srtCSp = {'Lab'; 'XYZ'; 'LCh'; 'YUV'; 'HSV'; 'RGB'};
srtPer = cellfun(@(s) perms(s(end:-1:1)), srtCSp, 'UniformOutput', false);
srtPer = [srtNoA; cellstr(vertcat(srtPer{:}))];
srtAll = [srtNoA; srtCSp];
[srtABC,srtIdx] = cellfun(@sort, srtAll, 'UniformOutput', false);
%
if nargin<2
	idxOrd = 1;
else
	order = cnv1s2c(order);
	assert(isChFH(order), ...
		'SC:colornames_GUI_view:order:NotText', ...
		'The second input <order> must be a string scalar or a char row vector.')
	idvOrd = strcmpi(order, srtPer);
	errTxt = sprintf(', %s', srtAll{:});
	assert(any(idvOrd), ...
		'SC:colornames_GUI_view:order:UnknownOption', ...
		'The second input <order> must be one of:%s (or any permutation thereof).', errTxt(2:end))
	idxOrd = find(idvOrd);
end
%
%% Ensure Figure %%
%
if isempty(figHnd) || ~ishghandle(figHnd)
	[figHnd,fnhSetVals] = cnvNewFig(cPalNm,cCSpFn,sDebug,srtPer,srtAll,srtNoA,srtABC,srtIdx);
else
	figure(figHnd);
end
%
fnhSetVals(idxPal,idxOrd);
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%colornames_GUI_view
function [figHnd,setHnd] = cnvNewFig(cPalNm,cCSpFn,sDebug,srtPer,srtAll,srtNoA,srtABC,srtIdx)
% Create the graphics objects. Define all callback functions in one workspace.
%
%% Layout Parameters %%
%
% Gap between objects (pixels):
objGap = 4;
% Button internal padding, each side (pixels):
btnMrg = 5;
% Button height (pixels):
btnHgt = 24;
% Scrollbar width reserved from panel width at all times (not measurable,
% empirically ~18px; a small safety margin is included):
scbWid = 23;
%
%% Shared State Variables %%
%
lumThr = 0.54; % luminance threshold
iniTxt = 'Initializing... please wait.';
idxPal = 1;
idxOrd = 1;
idxBtn = 0;
ptType = 'arrow';
txtDim = cell(size(cPalNm));
widChM = [];
btnHnd = gobjects(0);
cClrNm = {};
rgbMap = nan(0,3);
bgClrV = nan(0,3);
fgClrV = nan(0,3);
srtOrd = [];
%
%% Create Figure %%
%
figHnd = uifigure('Name','ColorNames 2D View GUI');
figHnd.Tag = mfilename();
figHnd.Visible = 'on';
figHnd.CloseRequestFcn = @cnvCloseReq;
%
uiGrL0 = uigridlayout(figHnd, [2,3]);
uiGrL0.RowHeight = {'fit','1x'};
uiGrL0.ColumnWidth = {'1x','1x','2x'};
uiGrL0.Padding = [objGap,objGap,objGap,objGap];
uiGrL0.RowSpacing = objGap;
uiGrL0.ColumnSpacing = objGap;
%
dDnPal = uidropdown(uiGrL0);
dDnPal.Items = cPalNm;
dDnPal.Tooltip = 'Color Palette';
dDnPal.ValueChangedFcn = @cnvPalClBk;
dDnPal.Layout.Row = 1;
dDnPal.Layout.Column = 1;
%
dDnSrt = uidropdown(uiGrL0);
dDnSrt.Items = srtPer;
dDnSrt.Tooltip = 'Sort Order';
dDnSrt.ValueChangedFcn = @cnvSrtClBk;
dDnSrt.Layout.Row = 1;
dDnSrt.Layout.Column = 2;
%
eFdInp = uieditfield(uiGrL0, 'text');
eFdInp.Value = iniTxt;
eFdInp.Placeholder = 'Enter a color name or RGB here, or click on a tile...';
eFdInp.Tooltip = 'Color name, hex #RRGGBB, or [R,G,B] triplet';
eFdInp.HorizontalAlignment = 'left';
eFdInp.ValueChangedFcn = @cnvEditClBk;
eFdInp.Layout.Row = 1;
eFdInp.Layout.Column = 3;
%
panHnd = uipanel(uiGrL0, 'Scrollable','on', 'BorderType','none');
panHnd.Layout.Row = 2;
panHnd.Layout.Column = [1,3];
panHnd.AutoResizeChildren = 'off';
panHnd.SizeChangedFcn = @cnvReflow;
%
overAx = uiaxes(panHnd, 'Units','pixels', 'Position',[0,0,1,1]);
overAx.XLim = [0,1];
overAx.YLim = [0,1];
overAx.XTick = [];
overAx.YTick = [];
overAx.XColor = 'none';
overAx.YColor = 'none';
overAx.Color = 'none';
overAx.LooseInset = [0,0,0,0];
overAx.Clipping = 'off';
overAx.Visible = 'off';
overAx.HitTest = 'off';
overAx.PickableParts = 'none';
disableDefaultInteractivity(overAx);
overRe = rectangle(overAx, 'Position',[0,0,1,1], 'LineWidth',7, 'Visible','off', ...
	'FaceColor','none', 'EdgeColor',1-panHnd.BackgroundColor);
%
% Persistent hidden measurement axes — created once, reuse for all
% Extent calls; kept invisible and non-interactive:
hideAx = uiaxes(figHnd, 'Visible','off', 'Units','pixels');
disableDefaultInteractivity(hideAx);
%
% Read font size from a UI control (uifigure itself has no FontSize property).
% Set once at figure creation; font/DPI do not change during a session:
fontSz = dDnPal.FontSize;
%
setHnd = @cnvSetVals;
%
%% Get & Set Functions %%
%
	function cnvSetVals(varargin)
		idxPal = varargin{1};
		idxOrd = varargin{2};
		ptType = figHnd.Pointer;
		figHnd.Pointer = 'watch';
		dDnPal.Value = cPalNm{idxPal};
		dDnSrt.Value = srtPer{idxOrd};
		overRe.Visible = 'off';
		overAx.Position = [0,0,1,1];
		eFdInp.Value = iniTxt;
		drawnow();
		cnvBuildButtons();
		cnvSortBy();
		cnvReflow();
		eFdInp.Value = '';
	end
%
%% Callback Functions %%
%
	function cnvDeselect() % button
		overRe.Visible = 'off';
		overAx.Position = [0,0,1,1];
		idxBtn = 0;
	end
%
	function cnvSelect(idc) % button
		%
		cnvDeselect();
		idxBtn = idc;
		%
		overAx.Position = btnHnd(idc).Position;
		overRe.EdgeColor = cnvPickEdge(bgClrV(idc,:));
		overRe.Visible = 'on';
		%
		% Update edit field with hex code, decimal triplet, and color name:
		hexStr = sprintf('%02X', round(bgClrV(idc,:)*255));
		decStr = sprintf(',%.5f', bgClrV(idc,:));
		eFdInp.Value = sprintf('#%s [%s] %s', hexStr, decStr(2:end), cClrNm{idc});
	end
%
	function edgRGB = cnvPickEdge(butRGB)
		[R,G,B] = ndgrid(0:0.25:1);
		cnrRGB = [R(:),G(:),B(:)];
		panRGB = panHnd.BackgroundColor;
		funLab = @(c) cCSpFn.cnXYZ2OKLab(cCSpFn.cnRGB2XYZ(c));
		cnrLab = funLab(cnrRGB);
		dE_but = sum((cnrLab-funLab(butRGB)).^2, 2);
		dE_pan = sum((cnrLab-funLab(panRGB)).^2, 2);
		[~,best] = max(min(dE_but,dE_pan));
		edgRGB = cnrRGB(best,:);
	end
%
	function cnvBtnClBk(~,~,idc) % Button Press callback
		if idxBtn==idc
			cnvDeselect();
			eFdInp.Value = '';
		else
			cnvSelect(idc);
		end
	end
%
	function cnvEditClBk(src,~) % Edit Field callback
		%
		% Accept a typed color name, hex #RRGGBB, or numeric triplet:
		srcVal = src.Value;
		[hexVal,~,~,idxNxt] = sscanf(srcVal, '#%2x%2x%2x');
		decVal = sscanf(regexprep(srcVal(idxNxt:end), '[^.0-9]+', ' '), '%f');
		decVal = reshape([hexVal./255; decVal], 1, []);
		if numel(decVal)==3
			srcVal = decVal;
		end
		outCNm = [];
		try %#ok<TRYNC>
			outCNm = colornames(cPalNm{idxPal}, srcVal);
		end
		if isempty(outCNm)
			cnvDeselect();
			eFdInp.Value = '';
		else
			idxCNm = find(strcmp(cClrNm, outCNm), 1);
			if isempty(idxCNm)
				idxBtn = 0;
			else
				cnvSelect(idxCNm);
				scroll(panHnd,btnHnd(idxBtn));
			end
		end
	end
%
	function cnvPalClBk(src,~) % Palette Dropdown callback
		%
		figHnd.Pointer = 'watch';
		overRe.Visible = 'off';
		overAx.Position = [0,0,1,1];
		%
		idxPal = find(strcmp(cPalNm, src.Value), 1);
		eFdInp.Value = iniTxt;
		%
		drawnow();
		%
		cnvBuildButtons();
		cnvSortBy();
		cnvReflow();
		eFdInp.Value = '';
	end
%
	function cnvSrtClBk(src,~) % Sort Order Dropdown callback
		%
		figHnd.Pointer = 'watch';
		%
		idxOrd = find(strcmp(srtPer, src.Value), 1);
		eFdInp.Value = iniTxt;
		%
		drawnow();
		%
		cnvSortBy();
		%
		cnvReflow();
		eFdInp.Value = '';
	end
%
	function cnvCloseReq(~,~)
		try %#ok<TRYNC>
			eFdInp.Value = 'Deleting all graphics objects...';
			eFdInp.FontColor = [1,0,0];
		end
		try %#ok<TRYNC>
			figHnd.Pointer = 'watch';
		end
		drawnow
		delete(figHnd);
	end
%
%% Button Array Callbacks %%
%
	function cnvBuildButtons()
		%
		% Delete any existing buttons:
		delete(btnHnd(ishghandle(btnHnd)));
		btnHnd = gobjects(0);
		idxBtn = 0;
		%
		% Fetch color names and RGB values for the current palette:
		[cClrNm,rgbMap] = colornames(cPalNm{idxPal});
		srtOrd = 1:numel(cClrNm);
		%
		% Compute black/white button text color from luminance:
		lumVec = rgbMap * [0.298936; 0.587043; 0.114021];
		bgClrV = rgbMap;
		fgClrV = double(repmat(lumVec<lumThr,1,3));
		%
		% Build per-character dimensionless width LUT if not yet cached.
		% The LUT stores each character's width as a fraction of 'M' so that
		% cached values remain valid across font size or DPI changes:
		if isempty(txtDim{idxPal})
			uniChV = unique(['M',cClrNm{:}]);
			% Build overdetermined system:
			nSmpls = max(5*numel(uniChV),69);
			lsqMat = zeros(nSmpls,numel(uniChV));
			extWid = zeros(nSmpls,1);
			tmpTxt = text('Parent',hideAx, 'Position',[10,30,0], ...
				'Units','pixels', 'FontSize',fontSz, 'Visible','off');
			%
			for ii = 1:nSmpls
				rndChV = ['M',uniChV(randi(numel(uniChV),1,randi([17,47])))];
				tmpTxt.String = rndChV;
				txtExt = tmpTxt.Extent;
				extWid(ii) = txtExt(3);
				for jj = 1:numel(uniChV)
					lsqMat(ii,jj) = nnz(rndChV==uniChV(jj));
				end
			end
			%
			delete(tmpTxt);
			%
			% Solve to find each character's width:
			lsqMat = [ones(nSmpls,1),lsqMat];
			lsqSol = lsqminnorm(lsqMat,extWid); % A\E
			widChs = lsqSol(2:end); % ignore margin==1st element.
			%
			idxChM = find(uniChV=='M',1);
			widChM = widChs(idxChM);
			%
			lutChW = zeros(1,max(double(uniChV))+1);
			lutChW(double(uniChV)) = widChs / widChM;
			%
			txtDim{idxPal} = cellfun(@(s)sum(lutChW(double(s))), cClrNm);
		end
		%
		% Button width = dimensionless text width * 'M'width + 2*margin.
		% Margin is a text-object property and does not apply to uibuttons:
		btnWid = ceil(widChM .* txtDim{idxPal}(:) + 2*btnMrg);
		%
		% Available layout width: always reserve for the scrollbar so
		% that its appearance never causes a reflow:
		panWid = panHnd.InnerPosition(3) - scbWid;
		rowHgt = btnHgt + objGap;
		%
		% Pre-pass (pure arithmetic, no graphics): compute total content
		% height in natural (creation) order before the creation loop, so
		% each button can be placed at its correct bottom-up Y immediately:
		xPos = objGap;
		yRow = 1;
		for kk = 1:numel(cClrNm)
			if (xPos + btnWid(kk) + objGap)>panWid && xPos>objGap
				yRow = yRow + 1;
				xPos = objGap;
			end
			xPos = xPos + btnWid(kk) + objGap;
		end
		% Ensure small palettes fill from the top of the visible panel:
		useHgt = max(yRow * rowHgt + objGap, panHnd.InnerPosition(4));
		%
		% Create buttons and place each one immediately at its correct
		% bottom-up position, so the user sees progressive top-down filling:
		btnHnd = gobjects(numel(cClrNm),1);
		xPos = objGap;
		yRow = 1;
		for kk = 1:numel(cClrNm)
			if (xPos + btnWid(kk) + objGap)>panWid && xPos>objGap
				yRow = yRow + 1;
				xPos = objGap;
			end
			yPos = useHgt - yRow * rowHgt;
			uibH = uibutton(panHnd, 'push');
			uibH.Text = cClrNm{kk};
			uibH.BackgroundColor = bgClrV(kk,:);
			uibH.FontColor = fgClrV(kk,:);
			uibH.FontSize = fontSz;
			uibH.Position = [xPos, yPos, btnWid(kk), btnHgt];
			uibH.ButtonPushedFcn = {@cnvBtnClBk, kk};
			btnHnd(kk) = uibH;
			xPos = xPos + btnWid(kk) + objGap;
			drawnow limitrate
		end
	end
%
	function cnvSortBy()
		% Determine button sort order.
		%
		[srtTmp,dimOrd] = sort(srtPer{idxOrd});
		srtMsk = strcmp(srtTmp,srtABC);
		[~,invOrd] = sort(dimOrd);
		dimOrd = srtIdx{srtMsk}(invOrd);
		%
		switch srtAll{srtMsk}
			case srtNoA{1} % NaturalOrder
				srtOrd = cCSpFn.cnNatSort(cClrNm);
				return
			case srtNoA{2} % Alphabetic
				rawInd = sDebug(idxPal).index;
				if numel(rawInd)
					rgxInd = sprintf('^(%s)\\s*',rawInd);
					[~,srtOrd] = sort(lower(regexprep(cClrNm(:), rgxInd, '')));
				else
					[~,srtOrd] = sort(lower(cClrNm(:)));
				end
				return
			case 'RGB'
				tmpMap = rgbMap;
			case 'HSV'
				tmpMap = cCSpFn.cnRGB2HSV(rgbMap);
			case 'XYZ'
				tmpMap = cCSpFn.cnRGB2XYZ(rgbMap);
			case 'Lab'
				tmpMap = cCSpFn.cnXYZ2Lab(cCSpFn.cnRGB2XYZ(rgbMap));
			case 'LCh'
				tmpMap = cCSpFn.cnLab2LCh(cCSpFn.cnXYZ2Lab(cCSpFn.cnRGB2XYZ(rgbMap)));
			case 'YUV'   % BT.709
				tmpMap = cCSpFn.cnGammaInv(rgbMap) * [...
					+0.2126, -0.19991, +0.61500; ...
					+0.7152, -0.33609, -0.55861; ...
					+0.0722, +0.43600, -0.05639];
			otherwise
				error('SC:colornames_GUI_view:space:UnknownOption', ...
					'Colorspace "%s" is not supported.', srtPer{idxOrd})
		end
		%
		[~, srtOrd] = sortrows(tmpMap, dimOrd);
	end
%
	function cnvReflow(~,~)
		% Reposition all Buttons according to the requested sort order
		%
		if isempty(widChM) || isempty(btnHnd) || ~all(ishghandle(btnHnd)) || strcmp(figHnd.BeingDeleted,'on')
			return
		end
		%
		figHnd.Pointer = 'watch';
		%
		% Use cached 'M'width — no Extent calls here. Font and DPI do not
		% change during a figure resize, so the cached value is correct:
		btnWid = ceil(widChM .* txtDim{idxPal}(:) + 2*btnMrg);
		%
		% Reserve scrollbar width so layout is stable whether or not
		% the scrollbar is currently visible:
		panWid = panHnd.InnerPosition(3) - scbWid;
		rowHgt = btnHgt + objGap;
		%
		% Flow layout pass in current sort order. The button x-position
		% button-row are indexed by color index, not sort position:
		btnXPx = zeros(numel(btnHnd),1);
		btnRow = btnXPx;
		xPos = objGap;
		yRow = 1;
		for kk = 1:numel(btnHnd)
			clrPos = srtOrd(kk);
			if (xPos + btnWid(clrPos) + objGap)>panWid && xPos>objGap
				yRow = yRow + 1;
				xPos = objGap;
			end
			btnXPx(clrPos) = xPos;
			btnRow(clrPos) = yRow;
			xPos = xPos + btnWid(clrPos) + objGap;
		end
		%
		% Use max(content height, panel height) so short palettes
		% appear anchored to the top of the visible panel:
		useHgt = max(yRow * rowHgt + objGap, panHnd.InnerPosition(4));
		%
		% Reposition buttons one-by-one in sort order so that the user sees
		% progressive movement rather than a single delayed bulk update:
		btnYPx = useHgt - btnRow .* rowHgt;
		for kk = 1:numel(btnHnd)
			xx = srtOrd(kk);
			btnHnd(xx).Position = [btnXPx(xx),btnYPx(xx),btnWid(xx),btnHgt];
			drawnow limitrate
		end
		%
		if idxBtn
			overAx.Position = btnHnd(idxBtn).Position;
			scroll(panHnd,btnHnd(idxBtn));
		else
			overAx.Position = [0,0,1,1];
			scroll(panHnd,'top');
		end
		%
		figHnd.Pointer = ptType;
	end
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnvNewFig
function arr = cnv1s2c(arr)
% If scalar string then extract the character vector, otherwise data is unchanged.
if isa(arr, 'string') && isscalar(arr)
	arr = arr{1};
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnv1s2c
