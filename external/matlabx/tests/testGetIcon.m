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

function tests = testGetIcon
%TESTGETICON Exercise generated SVG content and disposable cache behavior.
    tests = functiontests(localfunctions);
end

function setupOnce(t)
    root = fileparts(fileparts(mfilename('fullpath')));
    t.applyFixture(matlab.unittest.fixtures.PathFixture(root));
end

function testCircleContentAndReuse(t)
    file = matlabx.ui.icon.get();
    t.verifyEqual(file,string(fullfile(matlabx.internal.Paths.prefRoot( ...
        'cache','icons'),'v1-circle-0072BD-16.svg')));
    svg = fileread(file);
    t.verifyTrue(contains(svg,'width="16" height="16"'));
    t.verifyTrue(contains(svg,'<circle cx="8" cy="8" r="6" fill="#0072BD"/>'));
    t.verifyFalse(contains(svg,'<rect'));
    t.verifyFalse(contains(svg,'stroke='));
    before = dir(file);
    t.verifyEqual(matlabx.ui.icon.get(Color=[0 114 189]/255),file);
    after = dir(file);
    t.verifyEqual(after.datenum,before.datenum);
    t.verifyEqual(fileread(file),svg);
end

function testOptionsDistinguishFiles(t)
    first = matlabx.ui.icon.get(Color=[1 0 0],Size=16);
    second = matlabx.ui.icon.get(Color=[0 1 0],Size=16);
    third = matlabx.ui.icon.get(Color=[1 0 0],Size=32);
    t.verifyNotEqual(first,second);
    t.verifyNotEqual(first,third);
    t.verifyTrue(contains(fileread(third),'width="32" height="32"'));
end

function testMissingFileRegenerated(t)
    % Reserve an unusual size and remove only this test's cache entry.
    file = matlabx.ui.icon.get(Color=[0.123 0.456 0.789],Size=137);
    cleanup = onCleanup(@() delete(file)); %#ok<NASGU>
    original = fileread(file);
    delete(file);
    t.verifyEqual(matlabx.ui.icon.get(Color=[0.123 0.456 0.789],Size=137),file);
    t.verifyEqual(fileread(file),original);
end

function testInvalidOptions(t)
    t.verifyError(@() matlabx.ui.icon.get(Shape="square"),'MATLAB:validators:mustBeMember');
    t.verifyError(@() matlabx.ui.icon.get(Color=[0 NaN 0]),'MATLAB:validators:mustBeFinite');
    t.verifyError(@() matlabx.ui.icon.get(Color=[0 2 0]),'MATLAB:validators:mustBeInRange');
    t.verifyError(@() matlabx.ui.icon.get(Color=[0 1i 0]),'MATLAB:validators:mustBeReal');
    t.verifyError(@() matlabx.ui.icon.get(Size=0),'MATLAB:validators:mustBePositive');
    t.verifyError(@() matlabx.ui.icon.get(Size=1.5),'MATLAB:validators:mustBeInteger');
    t.verifyError(@() matlabx.ui.icon.get(Size=Inf),'MATLAB:validators:mustBeFinite');
end

function testEncodingRoundTrip(t)
    name = matlabx.ui.icon.encode(Color=[0 0.4470 0.7410],Size=24);
    t.verifyEqual(name,"v1-circle-0072BD-24.svg");
    options = matlabx.ui.icon.decode(name);
    t.verifyEqual(options,struct('Shape',"circle",'Color',[0 114 189]/255,'Size',24));
    pairs = namedargs2cell(options);
    t.verifyEqual(matlabx.ui.icon.encode(pairs{:}),name);
    t.verifyEqual(matlabx.ui.icon.decode("C:\old\cache\" + name),options);
    t.verifyEqual(matlabx.ui.icon.decode("/old/cache/" + name),options);
    t.verifyEqual(matlabx.ui.icon.get(name),matlabx.ui.icon.get(pairs{:}));
end

function testEncodedPathRegeneratesLocally(t)
    name = matlabx.ui.icon.encode(Color=[0.234 0.567 0.891],Size=139);
    file = string(fullfile(matlabx.internal.Paths.prefRoot('cache','icons'),name));
    if isfile(file)
        delete(file);
    end
    t.verifyFalse(isfile(file));
    t.verifyEqual(matlabx.ui.icon.get("/obsolete/cache/" + name),file);
    cleanup = onCleanup(@() delete(file)); %#ok<NASGU>
    t.verifyTrue(isfile(file));
    original = fileread(file);
    delete(file);
    t.verifyEqual(matlabx.ui.icon.get(name),file);
    t.verifyEqual(fileread(file),original);
end

function testInvalidEncodedNames(t)
    invalid = ["anything.svg","v1-circle-0072bd-16.svg", ...
        "v1-circle-0072BD-0.svg","v1-circle-0072BD-1.5.svg", ...
        "v1-circle-0072BD-016.svg","v1-circle-0072BD-9007199254740993.svg"];
    for name = invalid
        t.verifyError(@() matlabx.ui.icon.decode(name),'matlabx:ui:InvalidIconName');
        t.verifyError(@() matlabx.ui.icon.get(name),'matlabx:ui:InvalidIconName');
    end
    t.verifyError(@() matlabx.ui.icon.decode("v2-circle-0072BD-16.svg"), ...
        'matlabx:ui:UnsupportedIconVersion');
    t.verifyError(@() matlabx.ui.icon.decode("v1-square-0072BD-16.svg"), ...
        'matlabx:ui:UnsupportedIconShape');
end
