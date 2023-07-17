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


function dir_fullpath = search_rmpath(dir_name)
% Searches for dir_name in matlab path and if found, removes dir_name and
% all its subdirectories from the MATLAB search path.
% Returns the list of directories which were removed. The directories can
% be added to path again by running:
%        addpath(dir_fullpath)
%


% get path as long string
p=path;

f = strfind(p, [dir_name pathsep]);
dir_fullpath = [];

if isempty(f)
   return
   %fprintf('%s - not found in path.\n', dir_name);
else
   % divide string to directory names
   delim=[0 strfind(p, pathsep) length(p)+1];

   for nf = 1:length(f)
      n = 1;
      while delim(n)<f(nf)
         n = n+1;
      end
      dir_root_full = p(delim(n-1)+1:delim(n)-1); % full path to dir_name

      for i=max(n-1, 2):length(delim)
         direc = p(delim(i-1)+1:delim(i)-1);
         if strncmpi(direc, dir_root_full, length(dir_root_full))   
            dir_fullpath = [dir_fullpath direc pathsep];
            rmpath(direc);
         end
      end
   end
   dir_fullpath(end) = []; % remove last pathsep
end

end
