function hPatch = QuiverPatch(hAx,X,Y,C,LineWidth,LineAlpha)

nVertices = length(X)*2;

Cnew = zeros(nVertices,3);

LineCounter = 1;

for i = 1:nVertices
    if rem(i,2) % if is odd
        Cnew(i,:) = C(LineCounter,:);
        LineCounter = LineCounter+1;
    else
        Cnew(i,:) = [1 1 1];
    end
end

hPatch = patch(hAx,"XData",X,"YData",Y,"FaceVertexCData",Cnew,"EdgeColor","Flat");
hPatch.HitTest = 'Off';
hPatch.PickableParts = 'None';
hPatch.LineWidth = LineWidth;
hPatch.EdgeAlpha = LineAlpha;

end