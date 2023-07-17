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


function [vol_interp, file_out] = interp3_nii(datafile, target_file, file_out, method)
% Wrapper around myreslice_nii to interpolates nifti file DATAFILE to the image-matrix space of
% TARGET_FILE. It uses information from nifti header. No successive interpolation is applied.
% Usage: 
%    [vol_interp, file_out] = interp3_nii(datafile, target_file, file_out)
%    [vol_interp, file_out] = interp3_nii(datafile, target_file, file_out, method)
%
% Also see: 
%   myreslice_nii, myreslice_nii_match_res, reslice_nii
%

if ~exist('method', 'var')
   method = 'linear';
end

[dataIn, ~, ~, ~, res1, T1, data] = get_original_grid_data(datafile);
dataIn = double(dataIn);
[~, X_vol2, Y_vol2, Z_vol2, ~, T2, vol_interp] = get_original_grid_data(target_file);


if is_same_grid(T1, T2, size(dataIn), size(X_vol2))
   vol_reslice = dataIn;
else
   vol_reslice = myreslice_nii(data, method, X_vol2, Y_vol2, Z_vol2);
end

vol_interp.hdr.dime.scl_slope = 0;
vol_interp.hdr.dime.scl_inter = 0;
vol_interp.img = vol_reslice;

% set dimensions correctly
vol_interp.hdr.dime.dim(1) = data.hdr.dime.dim(1);
vol_interp.hdr.dime.dim(5) = data.hdr.dime.dim(5); % when data is 4D volume
vol_interp.hdr.dime.dim((data.hdr.dime.dim(1)+2):end) = 1;

file_out = save_untouch_nii_gz(vol_interp, file_out, data.hdr.dime.datatype);

end

function flg = is_same_grid(T1, T2, sizedata1, sizedata2)

if ~isequal(sizedata1, sizedata2)
   flg = false;
   return;
end

if max(abs(T1(:)-T2(:)))<5e-3
   flg = true;
else
   flg = false;
end

end
