function AverageExcitationProbability = FindAverageExcitationProbability(Dipoles,EField)
    % number of dipoles that we are finding the average excitation probability for
    nDipoles = length(Dipoles);
    % 0 to start
    AverageExcitationProbability = 0;
    for DipoleIdx = 1:nDipoles
        % sum excitation probabilities for all dipoles when excited with given EField (another Dipole object)
        AverageExcitationProbability = AverageExcitationProbability + Dipoles(DipoleIdx).FindExcitationProbability(EField.Alpha);
    end
    AverageExcitationProbability = AverageExcitationProbability/nDipoles;
end