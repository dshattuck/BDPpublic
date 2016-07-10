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


function [header, ext, filetype, machine] = load_untouch_header_only_gz( file )
% wrapper around load_untouch_header_only to work with .gz files.
%
%   1. Extracts GNU zip files, if file is zipped.
%   2. Loads the data & returns it.
%   3. Deletes the unzipped file, if file is zipped.
%
%   file - is a string with relative / absolute path to .gz or .nii file
%
%   Requires NIFTI toolbox.

loc = strfind(file, '.gz');
len = length(file);

if (~isempty(loc)) && (len-loc(end) == 2)  % .gz extension found
   workdir = tempname;
   niiData = gunzip(file, workdir);
   [header, ext, filetype, machine] = load_untouch_header_only(char(niiData));
   delete(char(niiData));
   rmdir(workdir, 's')
else
  [header, ext, filetype, machine] = load_untouch_header_only(file);
end

end

