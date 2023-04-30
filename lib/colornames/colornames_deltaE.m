function colornames_deltaE(palette,map)
% Create a figure comparing the color difference (deltaE) calculations used in COLORNAMES.
%
% (c) 2014-2022 Stephen Cobeldick
%
%%% Syntax:
%  colornames_deltaE(palette,map)
%
% Creates a figure showing the supplied colormap as horizontal color bands,
% overlaid with columns of the closest named colors from the selected
% palette. Each column shows one color difference (deltaE) calculation.
%
% Note: Requires the function COLORNAMES and its associated MAT file (FEX 48155).
%
% For more information on color difference concepts and formulae:
% https://en.wikipedia.org/wiki/Color_difference
% http://www.colorwiki.com/wiki/Delta_E:_The_Color_Difference
%
%% Examples %%
%
% colornames_deltaE('html4',jet(18))
%
% colornames_deltaE('x11',summer(18))
%
% colornames_deltaE('matlab',jet(18))
%
%% Input and Output Arguments %%
%
%%% Inputs (all inputs are optional):
% palette = CharRowVector, the name of a palette supported by COLORNAMES.
% map     = Numeric Array, size Nx3, each row is an RGB triple (0<=RGB<=1).
%
%%% Outputs:
% none
%
% See also COLORNAMES COLORNAMES_CUBE COLORNAMES_VIEW MAXDISTCOLOR COLORMAP

%% Input Wrangling %%
%
persistent fgh axh txh
%
isChRo = @(s)ischar(s)&&ndims(s)==2&&size(s,1)==1; %#ok<ISMAT>
%
% Get palette names and deltaE names:
[pnc,~,dtE] = colornames();
%
% Define default values:
if nargin<2
	N = 16;
	map = cmDefaultCM();
	map = interp1(linspace(1,N,size(map,1)),map,1:N);
end
if nargin<1
	palette = pnc{1+rem(round(now*1e7),numel(pnc))};
end
%
% Text lightness threshold:
thr = 0.54;
%
if isempty(fgh)||~ishghandle(fgh)
	fgh = figure('HandleVisibility','callback', 'IntegerHandle','off',...
		'NumberTitle','off', 'Name',mfilename, 'Color','white', 'Toolbar','none');
	axh = axes('Parent',fgh, 'Visible','off', 'XTick',[], 'YTick',[],...
		'Units','normalized', 'Position',[0,0,1,1]);
else
	try %#ok<TRYNC>
		cla(axh)
	end
end
%
assert(isChRo(palette),...
    'SC:colornames_deltaE:palette:NotCharRowVector',...
    'The first input <palette> must be a 1xN character vector')
idp = strcmpi(palette,pnc);
assert(any(idp),...
    'SC:colornames_deltaE:palette:UnknownPalette',...
    'Palette ''%s'' is not supported. Call COLORNAMES() to list all palettes',palette)
%
set(fgh,'Name',sprintf('%s (palette = ''%s'')',mfilename,pnc{idp}))
%
assert(ndims(map)==2&&size(map,2)==3,...
    'SC:colornames:RGB:NotColormapMatrix',...
    'If the 2nd input is numeric it must be an Nx3 colormap') %#ok<ISMAT>
assert(isreal(map)&&all(map(:)>=0&map(:)<=1),...
    'SC:colornames:RGB:OutOfRangeOrComplex',...
    'If the 2nd input is numeric all values must be 0<=RGB<=1')
%
%% Display Colors and Names %%
%
colormap(axh,map);
%
N = size(map,1);
x = [0;0;1;1];
y = [0;1;1;0];
X = repmat(x,1,N);
Y = bsxfun(@plus,y,N-1:-1:0);%0:N-1);
patch(X,Y,1:N, 'Parent',axh, 'EdgeColor','none', 'FaceColor','flat', 'CDataMapping','direct');
%
dEn = numel(dtE);
[cnc,RGB] = cellfun(@(t)colornames(palette,map,t),dtE, 'uni',false);
BAW = cellfun(@(c)(c*[0.298936;0.587043;0.114021])<thr,RGB, 'uni',false);
%
tmp = @(s,n) text((2*n-1)*ones(1,N)/(2*dEn), mean(Y.',2), zeros(1,N),...
	s, 'Parent',axh, 'HorizontalAlignment','center');
txh = cellfun(tmp, cnc, num2cell(1:dEn), 'uni',false);
tmp = @(h,c,b) set(h(:), {'BackgroundColor'},num2cell(c,2), {'Color'},num2cell(b(:,[1,1,1]),2));
cellfun(tmp, txh, RGB, BAW)
%
set(axh,'YLim',[0,N+1]);
text((1:2:2*dEn)/(2*dEn), N+ones(1,dEn)/2, zeros(1,dEn), dtE(:),...
	'Parent',axh, 'HorizontalAlignment','center', 'Color','black');
%
drawnow()
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%colornames_deltaE
function M = cmDefaultCM()
% Get the colormap size from the current figure or default colormap.
try
	M = get(groot,'DefaultFigureColormap');
catch %#ok<CTCH> pre HG2
	M = get(0,'defaultFigureColormap');
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnDefaultCM