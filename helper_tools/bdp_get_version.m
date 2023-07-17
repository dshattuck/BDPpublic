% 
% BDP BrainSuite Diffusion Pipeline
% 
% Copyright (C) 2023 The Regents of the University of California and
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


function [versionStr, releaseDate, buildNo] = bdp_get_version(manifestFile)
% Returns the version and release date of BDP from the bdpmanifest.xml file.
% Returns empty strings if running from Matlab or file cannot be found.

if nargin == 0
   execDir = bdp_get_deployed_exec_dir();
   manifestFile = fullfile(execDir, 'bdpmanifest.xml');
end

versionStr = '';
releaseDate = '';
buildNo = [];

try
   if strncmpi(manifestFile, 'http://', 7)
      filecontents = urlread(manifestFile);
   else
      filecontents = fileread(manifestFile);
   end
catch
   return; % Could not open file, so return empty strings
end

versionStr = regexpi(filecontents, '<version>(.*)</version>', 'tokens', 'once');
versionStr = versionStr{1};

releaseDate = regexpi(filecontents, '<date>(.*)</date>', 'tokens', 'once');
releaseDate = releaseDate{1};

temp = regexpi(filecontents, '<build>(.*)</build>', 'tokens', 'once');
if isempty(temp)
   if ~isempty(versionStr)
      versionStr = [versionStr ' (build #0000)'];
   end
else
   buildNo = str2double(temp{1});
   versionStr = [versionStr ' (build #' temp{1} ')'];
end

end
