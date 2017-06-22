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


function [earlyExit] = bdp_preprocess_input(varargin)
% Check for and process flags that shortcircuit or change the behavior of the
% entire pipeline.
%
% Checked-for Flags:
% --version and -v display the current version of BDP
% --check-for-update(s) checks if there is a newer version of BDP online
% -h and --help to show help


earlyExit = false;

VERSION_FLAGS = {'--version', '-v'};
UPDATE_FLAGS = {'--check-for-update', '--check-for-updates'};
HELP_FLAGS = {'-h', '--help'};

inputs = lower(varargin);
[bdpVersion, releaseDate] = bdp_get_version();

if any(ismember(VERSION_FLAGS, inputs))
   if ~isempty(bdpVersion)
      fprintf(1, 'BDP Version: %s, released %s\n', bdpVersion, releaseDate);
   else
      fprintf(1, ['Unable to determine this version of BDP. Check for' ...
         ' a bdpmanifest.xml file in\nthe same directory as' ...
         ' your BDP executables.\n']);
   end
   earlyExit = true;
   
elseif any(ismember(UPDATE_FLAGS, inputs))
   bdp_check_for_updates();
   earlyExit = true;
   
elseif any(ismember(HELP_FLAGS, inputs)) 
   fprintf(1, bdp_usage(true));
   earlyExit = true;
   
elseif nargin==0
   fprintf(1, bdp_usage());
   earlyExit = true;
   
else % usual run
   if ~isempty(bdpVersion)
      fprintf(1, '\nBDP Version: %s, released %s\n', bdpVersion, releaseDate);
   end
end

end
