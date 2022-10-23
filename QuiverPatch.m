function hPatch = QuiverPatch(hAx,X,Y,C,LineWidth,LineAlpha)

% space filler colors for the lines we aren't going to draw
filler = ones(length(X),3);

% interleaved array where each odd row idx holds a line color to plot in the final patch
Cnew = Interleave2DArrays(C,filler,'row');

hPatch = patch(hAx,"XData",X,"YData",Y,"FaceVertexCData",Cnew,"EdgeColor","Flat");
hPatch.HitTest = 'Off';
hPatch.PickableParts = 'None';
hPatch.LineWidth = LineWidth;
hPatch.EdgeAlpha = LineAlpha;

end