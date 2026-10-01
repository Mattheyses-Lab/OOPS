function colornames_GUI_cube(palette,space)
% Plot COLORNAMES palettes in a color cube (e.g. RGB, OKLab). With DataCursor labels.
%
% (c) 2014-2026 Stephen Cobeldick
%
%%% Syntax %%%
%
%   colornames_GUI_cube()
%   colornames_GUI_cube(palette)
%   colornames_GUI_cube(palette,space)
%
% Plot COLORNAMES palettes in an RGB/DIN99/OKLab/CIELab/LCh/HSV/XYZ cube.
% The data-cursor of the plotted points gives the color-names.
%
% Two vertical colorbars are displayed on the figure's right hand side,
% showing the colormap in sequence (in full color and as grayscale).
%
%% Examples %%
%
%   colornames_GUI_cube()
%
%   colornames_GUI_cube('CSS')
%
%   colornames_GUI_cube('HTML4','HSV')
%
%% Input Arguments %%
%
%   palette = StringScalar or CharRowVector, the name of a palette supported
%             by COLORNAMES, e.g. "MATLAB", "xkcd", or 'Alphabet', etc.
%   space   = StringScalar or CharRowVector, the colorspace to plot the
%             palette in, must be one of: 'RGB', 'OKLab', 'DIN99',
%             'Lab', 'LCh', 'HSV', or 'XYZ'. By default a random space.
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
% COLORNAMES_GUI_DELTAE COLORNAMES_GUI_SEARCH COLORNAMES_GUI_VIEW
persistent figHnd fnhSetVals
% Release | Feature
% --------|--------
% R2009b  | tilde argument placeholder
% R2007a  | bsxfun
%
assert(~verLessThan('matlab','7.9'),...
	'SC:colornames_GUI_cube:ReleaseNotSupported',...
	'This MATLAB release is not supported. Requires R2009b or later.')
%
%% Input Wrangling %%
%
isChRo = @(s)ischar(s)&&ndims(s)==2&&size(s,1)==1; %#ok<ISMAT>
%
% Get palette names and colorspace functions:
[cPalNm,sSpcFn] = colornames();
%
cSpcNm = {'RGB','OKLab','DIN99','Lab','LCh','HSV','XYZ'};
%
if nargin<1
	idxPal = 1+rem(round(now*1e7),numel(cPalNm)); %#ok<TNOW1>
else
	palette = cnc1s2c(palette);
	assert(isChRo(palette),...
		'SC:colornames_GUI_cube:palette:NotText',...
		'The first input <palette> must be a string scalar or a char row vector.')
	idxPal = find(strcmpi(palette,cPalNm));
	assert(isscalar(idxPal),...
		'SC:colornames_GUI_cube:palette:UnknownPalette',...
		'Palette "%s" is not supported. Call COLORNAMES() to list all palettes.',palette)
end
%
if nargin<2
	idxSpc = 1+rem(round(now*1e7),numel(cSpcNm)); %#ok<TNOW1>
else
	space = cnc1s2c(space);
	assert(isChRo(space),...
		'SC:colornames_GUI_cube:space:NotText',...
		'The second input <space> must be a scalar string or a char row vector.')
	idxSpc = strcmpi(space,cSpcNm);
	errTxt = sprintf(', %s',cSpcNm{:});
	assert(any(idxSpc),...
		'SC:colornames_GUI_cube:space:UnknownOption',...
		'The second input must be one of:%s.',errTxt(2:end))
	idxSpc = find(idxSpc);
end
%
%% Ensure Figure %%
%
if isempty(figHnd) || ~ishghandle(figHnd)
	[figHnd,fnhSetVals] = cncNewFig(cPalNm,sSpcFn,cSpcNm);
else
	figure(figHnd);
end
%
fnhSetVals(idxPal,idxSpc);
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%colornames_GUI_cube
function [figHnd,svFHnd] = cncNewFig(cPalNm,sSpcFn,cSpcNm)
% Create the graphics objects. Define all callback functions in one workspace.
%
%% Axes Configuration Tables %%
%
cAxLim = {... % axes limits
	{[0,1],[0,1],[0,1]},... RGB
	{[0,1],[-Inf,+Inf],[-Inf,+Inf]},... OKLab
	{[0,100],[-Inf,+Inf],[-Inf,+Inf]},... DIN99
	{[0,100],[-Inf,+Inf],[-Inf,+Inf]},... Lab
	{[0,100],[0,+Inf],[0,360]},... LCh
	{[0,360],[0,1],[0,1]},... HSV
	{[0,1],[0,1],[0,1]}}; % XYZ
cAxLbl = {... % axes labels
	{'Red','Green','Blue'},... RGB
	{'L','a','b'},... OKLab
	{'L_{99}','a_{99}','b_{99}'},...  DIN99
	{'L*','a*','b*'},...  Lab
	{'Lightness','Chroma','Hue'},... LCh
	{'Hue','Saturation','Value'},... HSV
	{'X','Y','Z'}}; % XYZ
aAxRat = [  false,   false,   false,  false,   true,   true,  false]; % automatic axes ratio.
cAxXYZ = {[3,2,1], [3,2,1], [3,2,1],[3,2,1],[3,2,1],[1,2,3],[1,2,3]}; % axis order.
%
%% Shared State Variables %%
%
% These are shared across all nested functions via this workspace.
idxPal = 1;
idxSpc = 1;
rgbMap = [];
cClrNm = {};
vLnHnd = [];
% Animation / timer state:
tmrObj = [];
stSize = 2;
itrCnt = 0;
incThe = 0;
incPhi = 0;
% Axes orientation:
camPos = [];
camUpV = [];
%
%% Create Figure %%
%
figHnd = figure('HandleVisibility','callback', 'IntegerHandle','off',...
	'NumberTitle','off', 'Toolbar','figure', ...
	'Name','ColorNames 3D Cube GUI', 'Tag',mfilename());
ax0Hnd = axes('Parent',figHnd, 'NextPlot','replacechildren', 'View',[55,32],...
	'Projection','orthographic');
grid(ax0Hnd,'on')
% Create colorbars:
ax1Hnd = axes('Parent',figHnd, 'Units','normalized', 'Position',[0.96,0,0.02,1],...
	'Visible','off', 'YLim',[0,1], 'HitTest','off');
ax2Hnd = axes('Parent',figHnd, 'Units','normalized', 'Position',[0.98,0,0.02,1],...
	'Visible','off', 'YLim',[0,1], 'HitTest','off');
im1Hnd = image('CData',[0.25;0.5;0.75], 'Parent',ax1Hnd);
im2Hnd = image('CData',[0.75;0.5;0.25], 'Parent',ax2Hnd);
txtHnd = uicontrol(figHnd, 'Units','Pixels', 'Position',[0,0,30,15], 'Style','text');
uicontrol(figHnd, 'Units','Normalized', 'Position',[0.88,0.96,0.08,0.04],...
	'Style','togglebutton', 'Callback',@cncDemoClBk, 'String','Rotate');
% Create colorspace and palette menus:
palHnd = uicontrol(figHnd, 'Units','normalized', 'Position',[0,0.95,0.15,0.05],...
	'Style','popupmenu', 'Callback',@cncScmClBk, 'String',cPalNm);
spcHnd = uicontrol(figHnd, 'Units','normalized', 'Position',[0,0.90,0.10,0.05],...
	'Style','popupmenu', 'Callback',@cncSpcClBk, 'String',cSpcNm);
% Add DataCursor labels:
dcm = datacursormode(figHnd);
set(dcm,'UpdateFcn',@(o,e)get(get(e,'Target'),'UserData'));
datacursormode(figHnd,'on')
%
svFHnd = @cncSetVals;
%
%% Initialize the Figure %%
%
cncMapPlot()
cncClrSpace()
%
%% Get & Set Functions %%
%
	function cncSetVals(varargin)
		% Called by the main function on every invocation (new figure or existing).
		% Updates the shared state variables and redraws.
		idxPal = varargin{1};
		idxSpc = varargin{2};
		set(palHnd,'Value',idxPal);
		set(spcHnd,'Value',idxSpc);
		cncMapPlot()
		cncClrSpace()
	end
%
%% Callback Functions %%
%
	function cncScmClBk(src,~) % Palette Callback
		idxPal = get(src,'Value');
		cncMapPlot()
		cncClrSpace()
	end
%
	function cncSpcClBk(src,~) % Colorspace Callback
		idxSpc = get(src,'Value');
		cncClrSpace()
	end
%
%% Re/Draw Points in 3D Plot %%
%
	function cncMapPlot()
		% Delete any existing colors:
		try %#ok<TRYNC>
			cla(ax0Hnd)
		end
		drawnow
		% Get new colors:
		[cClrNm,rgbMap] = colornames(cPalNm{idxPal});
		N = numel(cClrNm);
		vGray = rgbMap*[0.298936;0.587043;0.114021];
		% Update main axes:
		set(ax0Hnd, 'ColorOrder',rgbMap, 'NextPlot','replacechildren');
		%set(axh, 'ClippingStyle','rectangle', 'Clipping','off')
		% Update colorbars:
		set(ax1Hnd, 'YLim',[0,N]+0.5)
		set(ax2Hnd, 'YLim',[0,N]+0.5)
		set(im1Hnd, 'CData',permute(rgbMap,[1,3,2]))
		set(im2Hnd, 'CData',repmat(vGray,[1,1,3]))
		set(txtHnd, 'String',num2str(N))
		% Plot each node:
		idxXYZ = cAxXYZ{idxSpc};
		tmpMap = rgbMap;
		tmpMap(:,:,2) = NaN;
		tmpMap = permute(tmpMap,[3,1,2]);
		vLnHnd = plot3(tmpMap(:,:,idxXYZ(1)),tmpMap(:,:,idxXYZ(2)),tmpMap(:,:,idxXYZ(3)),...
			'.','MarkerSize',36, 'Parent',ax0Hnd);
		try %#ok<TRYNC>
			set(vLnHnd, 'Clipping','off');
		end
		% Add DataCursor labels:
		arrayfun(@(h,n)set(h,'UserData',n{1}), vLnHnd, cClrNm(:));
	end
%
	function cncClrSpace()
		% Plot the data in the requested colorspace.
		switch cSpcNm{idxSpc}
			case 'RGB'
				map = rgbMap;
			case 'HSV'
				map = sSpcFn.cnRGB2HSV(rgbMap);
			case 'XYZ'
				map = sSpcFn.cnRGB2XYZ(rgbMap);
			case 'Lab'
				map = sSpcFn.cnXYZ2Lab(sSpcFn.cnRGB2XYZ(rgbMap));
			case 'LCh'
				map = sSpcFn.cnLab2LCh(sSpcFn.cnXYZ2Lab(sSpcFn.cnRGB2XYZ(rgbMap)));
			case 'OKLab'
				map = sSpcFn.cnXYZ2OKLab(sSpcFn.cnRGB2XYZ(rgbMap));
			case 'DIN99'
				map = sSpcFn.cnLab2DIN99(sSpcFn.cnXYZ2Lab(sSpcFn.cnRGB2XYZ(rgbMap)));
			otherwise
				error('Sorry, the colorspace "%s" is not recognized.',cSpcNm{idxSpc})
		end
		%
		tmpXYZ = cAxXYZ{idxSpc};
		tmpLbl = cAxLbl{idxSpc};
		tmpLim = cAxLim{idxSpc};
		%
		set(vLnHnd, {'XData','YData','ZData'},num2cell(map(:,tmpXYZ)))
		%
		xlabel(ax0Hnd,tmpLbl{tmpXYZ(1)})
		ylabel(ax0Hnd,tmpLbl{tmpXYZ(2)})
		zlabel(ax0Hnd,tmpLbl{tmpXYZ(3)})
		%
		xlim(ax0Hnd,tmpLim{tmpXYZ(1)})
		ylim(ax0Hnd,tmpLim{tmpXYZ(2)})
		zlim(ax0Hnd,tmpLim{tmpXYZ(3)})
		%
		if aAxRat(idxSpc)
			set(ax0Hnd, 'DataAspectRatioMode','auto')
		else
			set(ax0Hnd, 'DataAspectRatio',[1,1,1])
		end
		%
		drawnow()
	end
%
%% Demonstration Function %%
%
	function cncDemoClBk(src,~)
		if get(src,'Value')
			if isempty(tmrObj) || ~isvalid(tmrObj)
				% Button pressed: initialise state and start the timer.
				stSize = 2;
				itrCnt = 0;
				incThe = 0;
				incPhi = 0;
				camPos = get(ax0Hnd, 'CameraPosition');
				camUpV = get(ax0Hnd, 'CameraUpVector');
				tmrObj = timer('ExecutionMode','fixedRate', 'Period',0.07,...
					'TimerFcn',@cncTimerFcn, 'StopFcn',@(t,~) delete(t));
				start(tmrObj);
			end
		else
			% Button pressed again: stop (StopFcn will delete the object).
			try %#ok<TRYNC>
				stop(tmrObj);
			end
		end
		drawnow
	end
%
	function cncTimerFcn(~,~)
		% Called every 0.07 s by the timer. Performs one orbit step.
		% Stops itself cleanly if the axes have been deleted.
		if ~ishghandle(ax0Hnd)
			stop(tmrObj);
			return
		end
		if itrCnt <= 0
			itrCnt = randi([45,360]) / stSize;
			newAng = 360 * rand(1);
			incThe = stSize * sind(newAng);
			incPhi = stSize * cosd(newAng);
		end
		[camPos,camUpV] = cncOrbit(ax0Hnd, incThe,incPhi, camPos,camUpV);
		itrCnt = itrCnt - 1;
	end
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cncNewFig
function [newPos,newUpV] = cncOrbit(axHnd, dTh,dPh, camPos,camUpV)
% Rotate camera around the center of the axes.
% Avoids the numeric instability of CAMROTATE after thousands of calls.
%
C = get(axHnd, {'CameraTarget','DataAspectRatio'});
camTgt = C{1};
aspRat = C{2};
%
% Work in aspect-corrected space:
caDirV = (camTgt - camPos) ./ aspRat;
caDist = norm(caDirV);
caDirV = caDirV / caDist;
%
% Build initial local frame:
axSide = cross(caDirV, camUpV ./ aspRat);
axSide = axSide / norm(axSide);
axUp   = cross(axSide, caDirV);
axUp   = axUp / norm(axUp);
%
% Rodrigues rotations:
cosAng = cosd(dTh);
sinAng = sind(dTh);
verAng = 1 - cosAng;
rotH = [...
	cosAng+axUp(1)^2*verAng, axUp(1)*axUp(2)*verAng-axUp(3)*sinAng, axUp(1)*axUp(3)*verAng+axUp(2)*sinAng;...
	axUp(1)*axUp(2)*verAng+axUp(3)*sinAng, cosAng+axUp(2)^2*verAng, axUp(2)*axUp(3)*verAng-axUp(1)*sinAng;...
	axUp(1)*axUp(3)*verAng-axUp(2)*sinAng, axUp(2)*axUp(3)*verAng+axUp(1)*sinAng, cosAng+axUp(3)^2*verAng]';
%
cosAng = cosd(-dPh);
sinAng = sind(-dPh);
verAng = 1 - cosAng;
rotV = [...
	cosAng+axSide(1)^2*verAng, axSide(1)*axSide(2)*verAng-axSide(3)*sinAng, axSide(1)*axSide(3)*verAng+axSide(2)*sinAng;...
	axSide(1)*axSide(2)*verAng+axSide(3)*sinAng, cosAng+axSide(2)^2*verAng, axSide(2)*axSide(3)*verAng-axSide(1)*sinAng;...
	axSide(1)*axSide(3)*verAng-axSide(2)*sinAng, axSide(2)*axSide(3)*verAng+axSide(1)*sinAng, cosAng+axSide(3)^2*verAng]';
%
rotM = rotV * rotH;
%
% Rotate direction:
newDir = (-caDirV * rotM);
newDir = newDir / norm(newDir);
%
%%% Rebuild orthonormal frame (continuous, stable) %%%
%
% Start from previous up (already close):
tmpUp = camUpV ./ aspRat;
%
% Remove any component along newDir (Gram-Schmidt):
tmpUp = tmpUp - dot(tmpUp,newDir)*newDir;
tmpUp = tmpUp ./ norm(tmpUp);
%
% Recompute side:
tmpSide = cross(newDir, tmpUp);
tmpSide = tmpSide ./ norm(tmpSide);
%
% Recompute up (ensures perfect orthogonality):
newUp = cross(tmpSide, newDir);
%
% Restore aspect:
newPos = aspRat .* newDir .* caDist + camTgt;
newUpV = aspRat .* newUp;
%
set(axHnd, 'CameraPosition',newPos, 'CameraUpVector',newUpV);
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cncOrbit
function arr = cnc1s2c(arr)
% If scalar string then extract the character vector, otherwise data is unchanged.
if isa(arr,'string') && isscalar(arr)
	arr = arr{1};
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnc1s2c