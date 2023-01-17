function LabelProportions = FindLabelProportions(ObjectSummary)
% returns the number and relative proportion of each object label found in the object summary table, ObjectSummary
% returns LabelProportions, an nx3 cell array, where each row represents a unique label, each column gives the label name, 
% number found, and relative proportion
% ex: 
%   If there are 100 objects in the summary file, with half labeled 'Cluster #1' and half labeled 'Cluster #2' 
%   then LabelProportions = {'Cluster #1',50,0.5;'Cluster #2',50,0.5}

% cell array of object labels
LabelCell = ObjectSummary.LabelName;

% find unique labels in LabelCell, and the idxs thereof
[UniqueLabels, ~, UniqueIdx] = unique(LabelCell);

% determine how many of each label there are
counts = accumarray(UniqueIdx,ones(size(UniqueIdx)));

% determine how many objects there are so we can calculate relative proportions
nObjects = length(LabelCell);

% calculate the relative proportions of each label
Proportions = counts./nObjects;

% create the output cell array
LabelProportions = [UniqueLabels,num2cell(counts),num2cell(Proportions)];

end