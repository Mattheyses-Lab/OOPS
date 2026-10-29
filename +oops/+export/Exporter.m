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

        function result = exportNativeImages(project,opts)
        %EXPORTNATIVEIMAGES Collect options and export native OME-TIFF products.
            arguments
                project (1,1) oops.model.Project
                opts.Progress = []
            end
            result = false;
            options = matlabx.app.ParamsDialog.prompt( ...
                'Native image export options', ...
                {'AverageIntensity','Average intensity','logical',true}, ...
                {'Mask','Mask','logical',true}, ...
                {'Order','Order','logical',true}, ...
                {'Azimuth','Azimuth','logical',true}, ...
                {'AuxiliaryIndividual','Individual auxiliary channels','logical',true}, ...
                {'AuxiliaryCombined','Combined auxiliary channels','logical',true}, ...
                {'EmbedLUTs','Embed channel lookup tables','logical',true}, ...
                {'ImageFolders','One folder per model image','logical',false}, ...
                {'ExistingFiles','Existing files','choice','stop', ...
                    {'stop','overwrite','skip'}});
            if isempty(options), return; end

            folder = pwd;
            if project.SourcePath ~= ""
                candidate = fileparts(project.SourcePath);
                if isfolder(candidate), folder = candidate; end
            end
            folder = uigetdir(folder,'Export native images');
            if isequal(folder,0), return; end
            folder = string(folder);

            summary = oops.export.nativeImagesOmeTiff(project,folder, ...
                AverageIntensity=options.AverageIntensity,Mask=options.Mask, ...
                Order=options.Order,Azimuth=options.Azimuth, ...
                AuxiliaryIndividual=options.AuxiliaryIndividual, ...
                AuxiliaryCombined=options.AuxiliaryCombined, ...
                EmbedLUTs=options.EmbedLUTs,ImageFolders=options.ImageFolders, ...
                ExistingFiles=string(options.ExistingFiles),Progress=opts.Progress);
            oops.Log.INFO(sprintf( ...
                'Native image export complete: %d exported, %d skipped.', ...
                summary.Exported,summary.Skipped));
            result = true;
        end
    end
end
