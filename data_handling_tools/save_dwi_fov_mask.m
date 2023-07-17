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


function save_dwi_fov_mask(dwi_file, options)
fprintf('Saving DWI FOV mask');
fprintf('\nUsing diffusion data: %s...', dwi_file);

temp_nii_file = fullfile(options.temp_file_workdir , [randstr(15) '.nii.gz']);

% set up file names
file_base = options.file_base_name;

% get mask for FOV of diffusion data
diffusion_coord_file = [file_base '.bfc' options.Diffusion_coord_suffix '.nii.gz'];
mprage_coord_nii = [file_base '.bfc.nii.gz'];
affinematrix_file = [file_base '.bfc' options.Diffusion_coord_suffix '.rigid_registration_result.mat'];
bfc_filename = options.bfc_file;
dwi_fov_mask_dcoord_file = [file_base '.dwi_fov' options.Diffusion_coord_suffix '.mask.nii.gz'];
dwi_fov_mask_mprage_coord_file = [file_base '.dwi_fov' options.mprage_coord_suffix '.mask.nii.gz'];

if exist(diffusion_coord_file, 'file')==2
   % make FOV mask
   d_coord_nii = load_untouch_nii_gz(diffusion_coord_file);
   d_coord_nii.img = 255*ones(size(d_coord_nii.img));
   save_untouch_nii_gz(d_coord_nii, dwi_fov_mask_dcoord_file, 2);
   
   % tranform mask
   load(affinematrix_file);
   affine_transform_nii(dwi_fov_mask_dcoord_file, M_world, origin, temp_nii_file); % just apply the rigid transform to header
   dwi_FOV_mask = interp3_nii(temp_nii_file, bfc_filename, dwi_fov_mask_mprage_coord_file, 'nearest');
else
   error('BDP:ExpectedFileNotFound', 'BDP cannot find file: %s \nPlease run BDP again', escape_filename(diffusion_coord_file))
end
fprintf('Done')
end
