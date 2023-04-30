function MapOut = MakeCircularColormap(MapIn)
    
%     C1 = MapIn(32,:);
%     C2 = MapIn(224,:);
% 
%     Rbar = linspace(C2(1),C1(1),66)';
%     Gbar = linspace(C2(2),C1(2),66)';
%     Bbar = linspace(C2(3),C1(3),66)';
% 
%     RGBbar = [Rbar,Gbar,Bbar];
% 
%     Segment1 = RGBbar(33:end,:);
%     MidSegment = MapIn(33:224,:);
%     Segment2 = RGBbar(1:32,:);
% 
%     MapOut = vertcat(Segment1,MidSegment);
%     MapOut = vertcat(MapOut,Segment2);

    C1 = MapIn(32,:);
    C2 = MapIn(224,:);

    Rbar = linspace(C2(1),C1(1),64)';
    Gbar = linspace(C2(2),C1(2),64)';
    Bbar = linspace(C2(3),C1(3),64)';

    RGBbar = [Rbar,Gbar,Bbar];

    Segment1 = RGBbar(33:end,:);
    MidSegment = MapIn(33:224,:);
    Segment2 = RGBbar(1:32,:);

    MapOut = vertcat(Segment1,MidSegment);
    MapOut = vertcat(MapOut,Segment2);


end