function [OrderFactor,Azimuth] = SimulateOrderFactor3(DipoleSet)
    % starting EField dipole, an x-axis unit vector centered at origin
    EField = Dipole3(0,90);
    % vector to hold excitation probabilities for each analysis angle
    ExcitationProb = zeros(4,1);
    for i = 1:4
        % find average excitation probability for full set of dipoles
        ExcitationProb(i) = FindAverageExcitationProbability(DipoleSet,EField);
        % rotate the EField 45 degrees CCW, as in FPM
        EField.RotateDipole('Z',45);
        % note: there is some degree of error involved with rotating the dipole
        % this should be updated to set the angle to the desired position instead of 
        % rotating to it. However, the error is quite small and negligible for most applications
    end
    % find difference in the two orthogonal sets of probabilities (~intensities)
    a = ExcitationProb(1) - ExcitationProb(3);
    b = ExcitationProb(2) - ExcitationProb(4);
    % determine the OF and azimuth from those differences
    OrderFactor = sqrt(a^2+b^2);
    Azimuth = round(0.5*atan2(b,a),5);
end