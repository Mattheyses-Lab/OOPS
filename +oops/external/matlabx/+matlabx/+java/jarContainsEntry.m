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

function tf = jarContainsEntry(jarFile,entryName)
%JARCONTAINSENTRY  Determine whether a JAR contains a specified entry
%
%   tf = matlabx.java.jarContainsEntry(jarFile,entryName) returns true when
%   the specified JAR archive contains the requested file or class entry.
%
%   Entry names must use forward slashes, for example:
%
%       "loci/formats/IFormatReader.class"
%
%   Inputs
%       jarFile   - Path to a JAR file
%       entryName - Name of an entry within the JAR
%
%   Output
%       tf        - True when the entry exists

    arguments
        jarFile   {mustBeTextScalar}
        entryName {mustBeTextScalar}
    end

    jarFile = string(jarFile);
    entryName = string(entryName);

    tf = false;
    jar = [];

    if ~isfile(jarFile)
        return
    end

    try
        jar = java.util.jar.JarFile(char(jarFile));
        tf = ~isempty(jar.getJarEntry(char(entryName)));
    catch
        tf = false;
    end

    if ~isempty(jar)
        try
            jar.close();
        catch
        end
    end
end