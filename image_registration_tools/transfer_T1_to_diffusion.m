% 
% BDP BrainSuite Diffusion Pipeline
% 
% Copyright (C) 2018 The Regents of the University of California and
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


function out_fname = transfer_T1_to_diffusion(src_T1_file, ref_bfc, ref_diffusion, affinematrix_file, ...
                                                       output_filename, method)
% Transfers input T1-coordinate volume to diffusion coordinate after fixing to BS header. It also
% checks nifti file for problem and supports reading sform only volumes.
%
%    src_T1_file - Source T1 file name (can not be nii structure)
%    ref_bfc - Reference bfc file name (or nii struct) which was used for rigid registration. Must
%              be in RAS orientation (See note below).  
%    ref_diffusion - Reference diffusion coordinate file name (or nii struct) which was used for
%                    rigid registration. 
%    affinematrix_file - File name of saved .mat file after rigid registration.
%    output_filename - Target output file name with/without .nii.gz
%    method - (Optional) Interpolation method. 'linear' is default. See interpn for all possible
%             options. 
%    out_fname - Filename of saved transformed file.
%
% Important NOTE: This function assumes that ref_bfc is in RAS orientation and is mainly
%                 written to provide easy support for NIfTI files with BS/SVReg type incorrect
%                 headers along with some more file checks. In other situations following call
%                 or something similar should be sufficient:
%
%                 affine_transform_nii(src_T1_nii, inv(M_world), origin, temp_fname);
%                 [~, out_fname] = interp3_nii(temp_fname, ref_diffusion, output_filename, method);
%

fprintf('\nTransforming input file to diffusion coordinates: %s', src_T1_file);

if exist(affinematrix_file, 'file')==2
   load(affinematrix_file);
else
   error('BDP:ExpectedFileNotFound', ['BDP could not find rigid registration result file:%s\n'...
      'Please make sure you have run BDP on this filebase without the flag --generate-only-stats.'], affinematrix_file);
end

if ischar(ref_bfc)
   ref_bfc = load_untouch_nii_gz(ref_bfc);
elseif ~isfield(ref_bfc,'untouch') || ref_bfc.untouch ~= 1
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
[~, outFile] = check_nifti_file(src_T1_file, workdir);
src_T1_nii = reorient_nifti_sform(outFile, temp_fname);

src_T1_nii.hdr.hist.sform_code = ref_bfc.hdr.hist.sform_code;
src_T1_nii.hdr.hist.srow_x = ref_bfc.hdr.hist.srow_x;
src_T1_nii.hdr.hist.srow_y = ref_bfc.hdr.hist.srow_y;
src_T1_nii.hdr.hist.srow_z = ref_bfc.hdr.hist.srow_z;
src_T1_nii.hdr.hist.qform_code = 0; % unset qform_code

% check for possible inconsistency
if norm(src_T1_nii.hdr.dime.dim(2:4) - ref_bfc.hdr.dime.dim(2:4)) > 1e-4
   error('BDP:InvalidT1File', 'Dimension of input and reference T1 file must match: %s', src_T1_file);
end

if ~isequal(size(ref_bfc.img), size(src_T1_nii.img))
   error('BDP:InvalidT1File', 'Image size of input and reference T1 file must match: %s', src_T1_file);
end

if norm(src_T1_nii.hdr.dime.pixdim(2:4)-ref_bfc.hdr.dime.pixdim(2:4)) > 1e-3
   error('BDP:InvalidT1File', 'Voxel resolution of input and reference T1 file must match: %s', src_T1_file);
end

% interpolate
affine_transform_nii(src_T1_nii, inv(M_world), origin, temp_fname);
[~, out_fname] = interp3_nii(temp_fname, ref_diffusion, output_filename, method);

rmdir(workdir, 's');
fprintf('\nFinished transformation. Saved file to disk: %s\n', out_fname);
end

