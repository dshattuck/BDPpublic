% 
% BDP BrainSuite Diffusion Pipeline
% 
% Copyright (C) 2017 The Regents of the University of California and
% the University of Southern California
% 
% Created by Chitresh Bhushan, Divya Varadarajan, Justin P. Haldar, Anand A. Joshi,
%            David W. Shattuck, and Richard M. Leahy
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; version 2.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
% USA.
% 


function [versionStr, releaseDate, bdpStr, buildNo] = bdp_get_online_version(manifestFile)
% Returns the version and release date of latest BDP from website.
% Returns empty strings if file cannot be found.

bdpStr = '';
releaseDate = '';
versionStr = '';
buildNo = [];

if nargin==0
   manifestFile = 'http://brainsuite.org/latestversions.xml';
   % manifestFile = 'http://neuroimage.usc.edu/~chitresh/latestversions.xml';
end

try
   if strncmpi(manifestFile, 'http://', 7)
      filecontents = urlread(manifestFile);
   else
      filecontents = fileread(manifestFile);
   end
catch
   return; % Could not open file, so return empty strings
end

bdpStr = regexpi(filecontents, '<bdp (.*)/>', 'tokens', 'once');
bdpStr = bdpStr{1};

versionStr = regexpi(bdpStr, 'version="([^"]*)"', 'tokens', 'once');
versionStr = versionStr{1};

releaseDate = regexpi(bdpStr, 'releasedate="([^"]*)"', 'tokens', 'once');
releaseDate = releaseDate{1};

buildStr = regexpi(bdpStr, 'build="([^"]*)"', 'tokens', 'once');
buildNo = str2double(buildStr{1});

end
