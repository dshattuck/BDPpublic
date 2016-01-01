% 
% BDP BrainSuite Diffusion Pipeline
% 
% Copyright (C) 2015 The Regents of the University of California and
% the University of Southern California
% 
% Created by Chitresh Bhushan, Justin P. Haldar, Anand A. Joshi, David W. Shattuck, and Richard M. Leahy
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


function out_fname = transfer_diffusion_to_T1(src_diffusion_file, ref_diffusion, ref_bfc, affinematrix_file, ...
                                                       output_filename, method)
% Transfers input diffusion-coordinate volume to T1 coordinate after fixing to BS header. It also
% checks nifti file for problem and supports reading sform only volumes.
%
%    src_diffusion_file - Source diffusion file name (can not be nii structure)
%    ref_bfc - Reference bfc file name (or nii struct) which was used for rigid registration.
%    ref_diffusion - Reference diffusion coordinate file name (or nii struct) which was used for
%                    rigid registration. Must be in RAS orientation (See note below). 
%    affinematrix_file - File name of saved .mat file after rigid registration.
%    output_filename - Target output file name with/without .nii.gz
%    method - (Optional) Interpolation method. 'linear' is default. See interpn for all possible
%             options. 
%    out_fname - Filename of saved transformed file.
%
% Important NOTE: This function assumes that ref_diffusion is in RAS orientation and is mainly
%                 written to provide easy support for NIfTI files with BS/SVReg type incorrect
%                 headers along with some more file checks. In other situations following call
%                 or something similar should be sufficient:
%
%                 affine_transform_nii(src_T1_nii, M_world, origin, temp_fname);
%                 [~, out_fname] = interp3_nii(temp_fname, ref_diffusion, output_filename, method);
%

fprintf('\nTransforming input file to T1 coordinates: %s', src_diffusion_file);

if exist(affinematrix_file, 'file')==2
   load(affinematrix_file);
else
   error('BDP:ExpectedFileNotFound', ['BDP could not find rigid registration result file:%s\n'...
      'Please make sure you have run BDP on this filebase without the flag --generate-only-stats.'], affinematrix_file);
end

if ischar(ref_diffusion)
   ref_diffusion = load_untouch_nii_gz(ref_diffusion);
elseif ~isfield(ref_diffusion,'untouch') || ref_diffusion.untouch ~= 1
   error('Please use ''load_untouch_nii.m'' to load the structure ref_T1.');
end

if ~exist('method', 'var')
   method = 'linear';
end

workdir = tempname();
mkdir(workdir);
temp_fname = fullfile(workdir, [Random_String(16) '.nii.gz']);

% fix BS header; Following should be similar to implementation in fixBSheader.m 
% However, following provides more relevant error messages in BDP and less file I/O during 
% whole processing. Hence it should be retained. 
[~, outFile] = check_nifti_file(src_diffusion_file, workdir);
src_diffusion_nii = reorient_nifti_sform(outFile, temp_fname);

src_diffusion_nii.hdr.hist.sform_code = ref_diffusion.hdr.hist.sform_code;
src_diffusion_nii.hdr.hist.srow_x = ref_diffusion.hdr.hist.srow_x;
src_diffusion_nii.hdr.hist.srow_y = ref_diffusion.hdr.hist.srow_y;
src_diffusion_nii.hdr.hist.srow_z = ref_diffusion.hdr.hist.srow_z;
src_diffusion_nii.hdr.hist.qform_code = 0; % unset qform_code

% check for possible inconsistency
if norm(src_diffusion_nii.hdr.dime.dim(2:4) - ref_diffusion.hdr.dime.dim(2:4)) > 1e-4
   error('BDP:InvalidT1File', 'Dimension of input and reference diffusion file must match: %s', src_diffusion_file);
end

if ~isequal(size(ref_diffusion.img), size(src_diffusion_nii.img))
   error('BDP:InvalidT1File', 'Image size of input and reference diffusion file must match: %s', src_diffusion_file);
end

if norm(src_diffusion_nii.hdr.dime.pixdim(2:4)-ref_diffusion.hdr.dime.pixdim(2:4)) > 1e-3
   error('BDP:InvalidT1File', 'Voxel resolution of input and reference diffusion file must match: %s', src_diffusion_file);
end

% interpolate
affine_transform_nii(src_diffusion_nii, M_world, origin, temp_fname);
[~, out_fname] = interp3_nii(temp_fname, ref_bfc, output_filename, method);

rmdir(workdir, 's');
fprintf('\nFinished transformation. Saved file to disk: %s\n', out_fname);
end

