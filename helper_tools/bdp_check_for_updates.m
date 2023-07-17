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


function bdp_check_for_updates()
% Checks online for the latest manifest file and compares its version to the
% locally installed one. Either lets the user know that there is a newer
% version available and where to download it, or that they currently have the
% latest version distributed.

if ~isdeployed
    fprintf(1, 'Cannot check for updates when BDP is run via Matlab.\n');
    return;
end

CHANGELOG_URL = 'http://brainsuite.org/bdp/bdpchangelog.txt';
DOWNLOAD_URL = 'http://brainsuite.org/download/';

[onlineVersion, onlineDate, ~, onlineBuildNo] = bdp_get_online_version();
[thisVersion, thisDate, thisBuildNo] = bdp_get_version();

if isempty(thisVersion) || isempty(onlineVersion)
    fprintf(1, bdp_linewrap(['Problem checking version numbers. Make sure you are connected to '...
        'the internet and have a bdpmanifest.xml file in your BDP directory.\n']));
    return; % Could not determine one of the versions
end

if datenum(onlineDate)>datenum(thisDate) || onlineBuildNo>thisBuildNo
    changeLog = get_change_log(CHANGELOG_URL, thisDate);
    
    fprintf(1, 'New version of BDP available.\n');
    fprintf(1, 'Current Version: %s, released %s\n', thisVersion, thisDate);
    fprintf(1, 'Latest Version: %s (build #%04d), released %s\n\n', onlineVersion, onlineBuildNo, onlineDate);
    
    fprintf(1, '%s\n', changeLog);
    fprintf(1, 'To download the latest version, please visit:\n');
    fprintf(1, '\t%s\n', DOWNLOAD_URL);
else
    fprintf(1, 'This is the latest version of BDP available.\n');
    fprintf(1, 'BDP Version: %s, released %s\n', thisVersion, thisDate);
end
end

function changeLog = get_change_log(fileName, oldDate)
changeLog = '';

try
    if strncmpi(fileName, 'http://', 7)
        fileContents = urlread(fileName);
    else
        fileContents = fileread(fileName);
    end
catch
    return; % Could not open file, so return empty strings
end

releaseDates = regexpi(fileContents, 'v[^\(\)]+\((.{10})\)', 'tokens');
num_dates = length(releaseDates);

for idate = num_dates:-1:1
   if datenum(releaseDates{idate}) > datenum(oldDate)
      idate = idate+1;
      if idate>num_dates
         idate = num_dates;
      end
      pattern = sprintf('(.*)v[^\\(\\)]+\\(%s\\)', releaseDates{idate}{1});
      break;
   end
end


changeLog = regexpi(fileContents, pattern, 'tokens', 'once');
if isempty(changeLog)
    changeLog = '';
else
    changeLog = changeLog{1};
end
end
