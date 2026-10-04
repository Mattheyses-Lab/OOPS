% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2026 William Dean
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation; either version 2 of the License, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, see <https://www.gnu.org/licenses/>.

function info = bioFormats()
%BIOFORMATS  Configure the bundled Bio-Formats installation
%
%   matlabx.setup.bioFormats() configures the Bio-Formats installation
%   bundled with matlabx. Competing Bio-Formats folders are removed from
%   the MATLAB search path, and competing Bio-Formats JARs are removed from
%   the dynamic Java class path.
%
%   INFO = matlabx.setup.bioFormats() returns a struct describing the
%   resulting configuration.
%
%   Bio-Formats installations on the static Java class path cannot be
%   removed during a MATLAB session. If a competing static installation is
%   detected, this function throws an error.
%
%   Note:
%       Modifying the dynamic Java class path may clear variables and Java
%       class definitions associated with dynamically loaded JARs.

    bfFolder = matlabx.internal.Paths.external('bfmatlab');
    bfFolder = matlabx.files.canonicalPath(bfFolder);

    if ~isfolder(bfFolder)
        error( ...
            "matlabx:setup:bioFormats:FolderNotFound", ...
            "The bundled Bio-Formats folder was not found:\n%s", ...
            bfFolder);
    end

    bioFormatsEntry = "loci/formats/IFormatReader.class";

    %% Locate the bundled Bio-Formats JAR

    bundledJars = string( ...
        fullfile(bfFolder,{dir(fullfile(bfFolder,"*.jar")).name}));

    correctJars = matlabx.java.findJarsContaining( ...
        bundledJars,bioFormatsEntry);

    if isempty(correctJars)
        error( ...
            "matlabx:setup:bioFormats:JarNotFound", ...
            "No Bio-Formats JAR containing the core reader API was " + ...
            "found in:\n%s", ...
            bfFolder);
    end

    if numel(correctJars) > 1
        error( ...
            "matlabx:setup:bioFormats:MultipleBundledJars", ...
            "Multiple Bio-Formats JARs were found in the bundled " + ...
            "installation:\n\n  %s", ...
            strjoin(correctJars,"\n  "));
    end

    correctJar = correctJars(1);

    %% Remove competing bfmatlab folders from the MATLAB path

    discoveredFolders = findBioFormatsFolders();
    incorrectFolders = discoveredFolders( ...
        ~matlabx.files.isSamePath(discoveredFolders,bfFolder));

    for n = 1:numel(incorrectFolders)
        if matlabx.files.isFolderOnPath(incorrectFolders(n))
            rmpath(incorrectFolders(n));
        end
    end

    % Add the bundled installation at the beginning of the MATLAB path.
    if matlabx.files.isFolderOnPath(bfFolder)
        rmpath(bfFolder);
    end

    addpath(bfFolder,"-begin");

    %% Check the static Java class path

    staticPath = matlabx.java.staticClassPath();

    staticBioFormats = matlabx.java.findJarsContaining( ...
        staticPath,bioFormatsEntry);

    incorrectStatic = staticBioFormats( ...
        ~matlabx.files.isSamePath(staticBioFormats,correctJar));

    if ~isempty(incorrectStatic)
        error( ...
            "matlabx:setup:bioFormats:StaticConflict", ...
            "A competing Bio-Formats installation is present on the " + ...
            "static Java class path:\n\n  %s\n\n" + ...
            "Static Java entries cannot be removed during the current " + ...
            "MATLAB session. Remove the conflicting entry from " + ...
            "javaclasspath.txt, restart MATLAB, and run " + ...
            "matlabx.setup.bioFormats() again." , ...
            strjoin(incorrectStatic,"\n  "));
    end

    %% Remove competing dynamic Bio-Formats JARs

    dynamicPath = matlabx.java.dynamicClassPath();

    dynamicBioFormats = matlabx.java.findJarsContaining( ...
        dynamicPath,bioFormatsEntry);

    incorrectDynamic = dynamicBioFormats( ...
        ~matlabx.files.isSamePath(dynamicBioFormats,correctJar));

    for n = 1:numel(incorrectDynamic)
        javarmpath(incorrectDynamic(n));
    end

    %% Add the bundled JAR

    dynamicPath = matlabx.java.dynamicClassPath();

    if ~any(matlabx.files.isSamePath(dynamicPath,correctJar))
        javaaddpath(correctJar,"-end");
    end

    %% Verify the resulting configuration

    activeDynamicPath = matlabx.java.dynamicClassPath();

    activeBioFormats = matlabx.java.findJarsContaining( ...
        activeDynamicPath,bioFormatsEntry);

    if ~any(matlabx.files.isSamePath(activeBioFormats,correctJar))
        error( ...
            "matlabx:setup:bioFormats:ConfigurationFailed", ...
            "The bundled Bio-Formats JAR could not be added to the " + ...
            "dynamic Java class path:\n%s", ...
            correctJar);
    end

    remainingIncorrect = activeBioFormats( ...
        ~matlabx.files.isSamePath(activeBioFormats,correctJar));

    if ~isempty(remainingIncorrect)
        error( ...
            "matlabx:setup:bioFormats:DynamicConflict", ...
            "Competing Bio-Formats JARs remain on the dynamic Java " + ...
            "class path:\n\n  %s", ...
            strjoin(remainingIncorrect,"\n  "));
    end

    info = struct( ...
        "Folder",             bfFolder, ...
        "Jar",                correctJar, ...
        "RemovedFolders",     incorrectFolders, ...
        "RemovedJars",        incorrectDynamic, ...
        "StaticJars",         staticBioFormats, ...
        "DynamicJars",        activeBioFormats);
end


function folders = findBioFormatsFolders()
%FINDBIOFORMATSFOLDERS  Locate bfmatlab folders on the MATLAB search path

    functionFiles = [
        string(which("bfopen","-all"))
        string(which("bfCheckJavaPath","-all"))
        string(which("bfGetReader","-all"))
    ];

    functionFiles = functionFiles(strlength(functionFiles) > 0);

    folders = strings(size(functionFiles));

    for n = 1:numel(functionFiles)
        folders(n) = string(fileparts(functionFiles(n)));
    end

    folders = matlabx.files.canonicalizePaths(folders);
    folders = unique(folders,"stable");
end