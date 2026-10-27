% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Exporter
%EXPORTER Collect user export choices and dispatch concrete writers.

    methods (Static)
        function result = exportSummaryTables(project,opts)
        %EXPORTSUMMARYTABLES Choose and write the project summary workbook.
            arguments
                project (1,1) oops.model.Project
                opts.Progress = []
            end
            result = false;
            folder = pwd;
            if project.SourcePath ~= ""
                candidate = fileparts(project.SourcePath);
                if isfolder(candidate), folder = candidate; end
            end
            base = regexprep(strtrim(project.Name),'[<>:"/\\|?*]+','-');
            base = strip(base,"both","-");
            if base == "", base = "OOPS-project"; end
            defaultName = fullfile(folder,base+"_summary-tables.xlsx");
            [file,path] = uiputfile({'*.xlsx','Excel workbook (*.xlsx)'}, ...
                'Export summary tables',char(defaultName));
            if isequal(file,0), return; end
            filename = string(fullfile(path,file));
            oops.Log.INFO("Exporting project summary tables to " + filename + ".");
            oops.export.summaryTablesXlsx(project,filename,Progress=opts.Progress);
            oops.Log.INFO("Project summary table export complete: " + filename + ".");
            result = true;
        end
    end
end
