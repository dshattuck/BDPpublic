% 
% BDP BrainSuite Diffusion Pipeline
% 
% Copyright (C) 2016 The Regents of the University of California and
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


function savedFileName = writedfsGz(fileName, dfs, workdir)
% Writes gzipped BrainSuite surface file with extension .dfs.gz. Wrapper around writedfs.
% WARNING: This function 'silently' overwrites the destination filename.
%
%   dfs: dfs structure as read by readdfsGz.m
%   fileName: Destination filename, with/without '.dfs' or '.dfs.gz'.
%             Use [] for no filename. When [] is used, filename is
%             retrived from dfs.name .
%   workdir: (optional) temporary work directory
%

if isempty(fileName)
   [pathstr, fileName] = fileBaseName(dfs.name);
else
   [pathstr, fileName] = fileBaseName(fileName);
end

if isempty(pathstr)
   pathstr = pwd;
end

if ~exist('workdir', 'var')
   workdir = tempname;
   mkdir(workdir)
   temp_folder = true;
else
   temp_folder = false;
end

tempdfs = fullfile(workdir, [fileName '.dfs']);
writedfs(tempdfs, dfs);
fname = gzip(tempdfs, pathstr);
savedFileName = fname{1};

if temp_folder
   rmdir(workdir, 's');
end

end

