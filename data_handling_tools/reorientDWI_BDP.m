% 
% BDP BrainSuite Diffusion Pipeline
% 
% Copyright (C) 2019 The Regents of the University of California and
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


function [dwi_out_file, bmat_file, bvec_file, nii_RAS, bMatrice_RAS, bvec_RAS] = reorientDWI_BDP(dwi_file, dwi_out_file, bmat, bdp_opts)
% Same as reorient_nifti_sform followed by bvec rotation, if any. 

fprintf('\nChecking orientation information...')
[nii_RAS, reorient_matrix, sform_new, bMatrice_RAS] = reorient_nifti_sform(dwi_file, dwi_out_file, bmat);

% reorient bvec, if it exists
if isempty(bdp_opts.bvec_file)
   bvec_file = '';
   bvec_RAS = [];
else
   bvec = readBvecBval(bdp_opts.bvec_file);
   bvec_RAS = transpose(reorient_matrix*(bvec'));
   bvec_file = [remove_extension(dwi_out_file) '.bvec'];
   writeBvecBvalFile(bvec_RAS, bvec_file);
end
bmat_file = [remove_extension(dwi_out_file) '.bmat'];

fprintf('Done');
end
