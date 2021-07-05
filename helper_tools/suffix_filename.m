% 
% BDP BrainSuite Diffusion Pipeline
% 
% Copyright (C) 2021 The Regents of the University of California and
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


function out_fname = suffix_filename(fname, suffix)
% Puts suffix at relevant location. useful for filenames with special meaning.

if (length(fname)>11) && strcmp(fname(end-11:end), '.mask.nii.gz')
   out_fname = [fname(1:end-12) suffix '.mask.nii.gz'];
   
elseif (length(fname)>12) && strcmp(fname(end-12:end), '.label.nii.gz')
   out_fname = [fname(1:end-13) suffix '.label.nii.gz'];
   
elseif (length(fname)>10) && strcmp(fname(end-10:end), '.eig.nii.gz')
   out_fname = [fname(1:end-11) suffix '.eig.nii.gz'];

else
   [f, e] = remove_extension(fname);
   out_fname = [f suffix e];
   
end
