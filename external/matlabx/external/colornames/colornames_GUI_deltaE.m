function colornames_GUI_deltaE(palette,bGdMap)
% Create a figure comparing the color difference (deltaE) calculations used in COLORNAMES.
%
% (c) 2014-2026 Stephen Cobeldick
%
%%% Syntax %%%
%
%   colornames_GUI_deltaE()
%   colornames_GUI_deltaE(palette)
%   colornames_GUI_deltaE(palette,map)
%
% Create a figure showing the supplied colormap as horizontal color bands,
% overlaid with columns of the closest named colors from the selected
% palette. Each column shows one color difference (deltaE) calculation.
%
% For more information on color difference concepts and formulae:
% https://en.wikipedia.org/wiki/Color_difference
% http://www.colorwiki.com/wiki/Delta_E:_The_Color_Difference
%
%% Examples %%
%
%   colornames_GUI_deltaE()
%
%   colornames_GUI_deltaE('x11')
%
%   colornames_GUI_deltaE('matlab',summer(18))
%
%% Input Arguments %%
%
%   palette = StringScalar or CharRowVector, the name of a palette supported
%             by COLORNAMES, e.g. "MATLAB", "xkcd", or 'Alphabet', etc.
%   map     = Numeric Array, size Nx3, each row is an RGB triple (0<=RGB<=1).
%             If not provided uses the default axes colormap.
%
%% Output Arguments %%
%
% None
%
%% Dependencies %%
%
% * MATLAB R2009b or later.
% * colornames.m <www.mathworks.com/matlabcentral/fileexchange/48155>
%
% See also COLORNAMES MAXDISTCOLOR ARBSORT
% COLORNAMES_GUI_CUBE COLORNAMES_GUI_SEARCH COLORNAMES_GUI_VIEW
persistent figHnd axeHnd
% Release | Feature
% --------|--------
% R2009b  | tilde argument placeholder
% R2007a  | bsxfun
%
assert(~verLessThan('matlab','7.9'),...
	'SC:colornames_GUI_deltaE:ReleaseNotSupported',...
	'This MATLAB release is not supported. Requires R2009b or later.')
%
%% Input Wrangling %%
%
isChFH = @(s)ischar(s)&&ndims(s)==2&&size(s,1)==1; %#ok<ISMAT>
%
% Get palette names and deltaE names:
[cPalNm,~,~,cDtENm] = colornames();
%
if nargin<2
	N = 15;
	bGdMap = cmDefaultCM();
	bGdMap = interp1(linspace(1,N,size(bGdMap,1)),bGdMap,1:N);
end
%
if nargin<1
	idxPal = 1+rem(round(now*1e7),numel(cPalNm)); %#ok<TNOW1>
else
	palette = cnd1s2c(palette);
	assert(isChFH(palette),...
		'SC:colornames_GUI_deltaE:palette:NotText',...
		'The first input <palette> must be a scalar string or a char row vector.')
	idxPal = find(strcmpi(palette,cPalNm));
	assert(isscalar(idxPal),...
		'SC:colornames_GUI_deltaE:palette:UnknownPalette',...
		'Palette "%s" is not supported. Call COLORNAMES() to list all palettes.',palette)
end
%
lumThr = 0.54; % luminance threshold
%
if isempty(figHnd)||~ishghandle(figHnd)
	figHnd = figure('HandleVisibility','callback', 'IntegerHandle','off',...
		'NumberTitle','off', 'Toolbar','none',...
		'Name', 'ColorNames Color-Difference Demo GUI', 'Tag',mfilename);
	axeHnd = axes('Parent',figHnd, 'Visible','off', 'XTick',[], 'YTick',[],...
		'Units','normalized', 'Position',[0,0,1,1]);
else
	figure(figHnd);
	try %#ok<TRYNC>
		cla(axeHnd)
	end
end
%
set(figHnd,'Name',sprintf('%s (palette = "%s")',mfilename,cPalNm{idxPal}))
%
assert(ndims(bGdMap)==2&&size(bGdMap,2)==3,...
	'SC:colornames_GUI_deltaE:RGB:NotColormapMatrix',...
	'If the 2nd input is numeric it must be an Nx3 colormap') %#ok<ISMAT>
assert(isreal(bGdMap)&&all(bGdMap(:)>=0&bGdMap(:)<=1),...
	'SC:colornames_GUI_deltaE:RGB:OutOfRangeOrComplex',...
	'If the 2nd input is numeric all values must be 0<=RGB<=1')
%
%% Display Colors and Names %%
%
colormap(axeHnd,bGdMap);
%
N = size(bGdMap,1);
xPatV = [0;0;1;1];
yPatV = [0;1;1;0];
xPatM = repmat(xPatV,1,N);
yPatM = bsxfun(@plus,yPatV,N-1:-1:0);%0:N-1);
patch(xPatM,yPatM,1:N, 'Parent',axeHnd, 'EdgeColor','none', 'FaceColor','flat', 'CDataMapping','direct');
%
nDtENm = numel(cDtENm);
[ccCNm,cRGB] = cellfun(@(t)colornames(cPalNm{idxPal},bGdMap,t),cDtENm, 'uni',false);
cBaW = cellfun(@(c)(c*[0.298936;0.587043;0.114021])<lumThr,cRGB, 'uni',false);
%
fnHd1 = @(s,n) text((2*n-1)*ones(1,N)/(2*nDtENm), mean(yPatM,1).', zeros(1,N),...
	s, 'Parent',axeHnd, 'HorizontalAlignment','center');
cTxHd = cellfun(fnHd1, ccCNm, num2cell(1:nDtENm), 'uni',false);
fnHd2 = @(h,c,b) set(h(:), {'BackgroundColor'},num2cell(c,2), {'Color'},num2cell(b(:,[1,1,1]),2));
cellfun(fnHd2, cTxHd, cRGB, cBaW)
%
set(axeHnd,'YLim',[0,N+1]);
text((1:2:2*nDtENm)/(2*nDtENm), N+ones(1,nDtENm)/2, zeros(1,nDtENm), cDtENm(:),...
	'Parent',axeHnd, 'HorizontalAlignment','center');
%
drawnow()
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%colornames_GUI_deltaE
function M = cmDefaultCM()
% Get the default colormap.
try
	M = get(groot,'DefaultFigureColormap');
catch %#ok<CTCH> pre HG2
	M = get(0,'defaultFigureColormap');
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cmDefaultCM
function arr = cnd1s2c(arr)
% If scalar string then extract the character vector, otherwise data is unchanged.
if isa(arr,'string') && isscalar(arr)
	arr = arr{1};
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnd1s2c