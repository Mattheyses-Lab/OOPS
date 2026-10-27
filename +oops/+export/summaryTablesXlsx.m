% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function summaryTablesXlsx(project,filename,opts)
%SUMMARYTABLESXLSX Write an all-project summary workbook.
arguments
    project (1,1) oops.model.Project
    filename (1,1) string
    opts.Progress = []
end
groups = project.Groups;
sheetCount = 5+numel(groups);
tables = cell(sheetCount,1);
names = strings(sheetCount,1);
oops.runtime.updateProgress(opts.Progress,"Building project summary...",0);
tables{1} = oops.export.projectSummaryTable(project); names(1) = "Project Summary";
oops.runtime.updateProgress(opts.Progress,"Collecting calibration information...",1/(2*sheetCount));
tables{2} = oops.export.calibrationTable(project); names(2) = "Calibrations";
oops.runtime.updateProgress(opts.Progress,"Collecting channel information...",2/(2*sheetCount));
tables{3} = oops.export.channelTable(project); names(3) = "Channels";
oops.runtime.updateProgress(opts.Progress,"Collecting image information...",3/(2*sheetCount));
tables{4} = oops.export.imageTable(project); names(4) = "Images";
oops.runtime.updateProgress(opts.Progress,"Collecting auxiliary-file information...",4/(2*sheetCount));
tables{5} = oops.export.auxiliaryFileTable(project); names(5) = "Auxiliary Files";
for k = 1:numel(groups)
    oops.runtime.updateProgress(opts.Progress,sprintf( ...
        'Collecting objects for group %d of %d: %s',k,numel(groups),groups(k).Name), ...
        (4+k)/(2*sheetCount));
    tables{5+k} = oops.export.objectTable(groups(k));
    names(5+k) = objectSheetName(groups(k).Name,k);
end
for k = 1:sheetCount
    oops.runtime.updateProgress(opts.Progress,sprintf( ...
        'Writing sheet %d of %d: %s',k,sheetCount,names(k)), ...
        .5+.5*(k-1)/sheetCount);
    oops.Log.DEBUG(sprintf('Writing export sheet %d/%d: %s (%d rows).', ...
        k,sheetCount,names(k),height(tables{k})));
    if k == 1, mode = "replacefile"; else, mode = "overwritesheet"; end
    writetable(tables{k},filename,'Sheet',names(k),'WriteMode',mode, ...
        'WriteVariableNames',true);
end
oops.runtime.updateProgress(opts.Progress,"Summary-table export complete.",1);
end

function name = objectSheetName(groupName,index)
%OBJECTSHEETNAME Produce a unique Excel-safe object sheet name.
name = sprintf('Objects %d - %s',index,groupName);
name = regexprep(name,'[:\\/?*\[\]]','-');
name = strip(string(name),"both","'");
if strlength(name) > 31, name = extractBefore(name,32); end
end
