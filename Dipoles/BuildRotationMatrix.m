function RotationMatrix = BuildRotationMatrix(RotationAxis,Theta)
    switch RotationAxis
        case 'X'
            RotationMatrix = [1 0 0;0 cosd(Theta) -sind(Theta);0 sind(Theta) cosd(Theta)];
        case 'Y'
            RotationMatrix = [cosd(Theta) 0 sind(Theta);0 1 0;-sind(Theta) 0 cosd(Theta)];
        case 'Z'
            RotationMatrix = [cosd(Theta) -sind(Theta) 0;sind(Theta) cosd(Theta) 0;0 0 1];
    end
end