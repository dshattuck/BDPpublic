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


function [dwi_correct_filename, bmat_file] = coregister_diffusion_mprage_pipeline(bdp_options)
%
% This function coregisters MPRAGE & diffusion MRI images. It also corrects the diffusion
% data for geometric distortions using given fieldmap or registration-based technique. 
%
% This function takes all inputs in form of a matlab structure. Check setup_bdp.m for possible
% options and flags. 
%
%
% file_base - String input representing base file name with full path to the dataset (in same
%             format as svreg). This function expects following files to be present on the
%             disk: 
%
%        <file_base>.bfc.nii.gz - Skull stripped (and Bias-field corrected) MPRAGE file. It is
%                                 generated during BrainSuite extraction sequence. 
%        <file_base>.dwi.nii.gz - Diffusion weighted image file. Only one b=0 image is used
%                                 for estimation of distortion. The function automatically
%                                 detects b=0 image among the diffusion images by using
%                                 information from .bmat file. Although, only one image is used
%                                 for estimation of distortion, the distortion correction is
%                                 applied to all the diffusion images.
%        <file_base>.fieldmap.nii.gz - (Optional, required only when using fieldmap correction)
%                                      Fieldmap file, which must have units of rad/sec.
%
%
%
% The function writes out following files: 
%        <file_base>.dwi.RSA.correct.nii.gz : Distortion corrected diffusion weighted image
%        <file_base>.bfc.Diffusion.coord.nii.gz : MPRAGE in undistorted diffusion coordinates
%        <file_base>.dwi.RSA.correct.0_diffusion.T1.coord.nii.gz : b=0 image in MPRAGE coordinates
%        <file_base>.bfc.Diffusion.coord.rigid_registration_result.mat : mat file containing rigid 
%                                                                        registration parameters.
%        <file_base>.dwi.correct.distortion.map.nii.gz : Distortion map (in voxels) along phase
%                                                        encoding direction.
%
%


%% Initialize variables
bdpPrintSectionHeader('Co-registration and Distortion Correction');
fprintf('Reading the input parameters for co-registration...');

opt = parse_input_COREGISTERDIFFUSIONMPRAGEPIPELINE(bdp_options); % file_base, varargin, default_options);

file_base = opt.file_base_name;
dwi_filename = opt.dwi_file; % diffusion file or b=0 file
bmat_file = opt.bmat_file;

if strcmpi(opt.file_base_name, opt.bfc_file_base)
   bfc_filename = opt.bfc_file;
else
   if copyfile(opt.bfc_file, [file_base '.bfc.nii.gz'])
      bfc_filename = [file_base '.bfc.nii.gz'];
   else
      err_msg = ['BDP could not write to the output directory: ' escape_filename(fileparts(file_base)) ...
         '\n Please make sure that you have write permission in the directory.'];
      error('BDP:FlagError', bdp_linewrap(err_msg));
   end
end

%% memory checks
if ~opt.ignore_memory
   low_memory_machine = false;
   min_memory_required = 5; % in GiB
   
   try % all of memory detection
      if ispc
         userview = memory;
         mem_found = userview.MemAvailableAllArrays/(2^30);
         fprintf('\n\nTotal usable memory found: %6.2fGB\n', double(mem_found))
         if mem_found < min_memory_required
            low_memory_machine = true;
         end
         
      elseif ismac
         [s, m] = unix('sysctl hw.memsize | cut -d: -f2');
         
         if s==0
            mem_found = str2double(m)/(2^30);
            if (mem_found < min_memory_required)
               low_memory_machine = true;
            end
            fprintf('\nTotal physical memory found: %6.2fGB\n', double(mem_found))
         end
         
      elseif isunix
         [s1,m1] = unix('cat /proc/meminfo | grep MemTotal');
         [s2,m2] = unix('cat /proc/meminfo | grep SwapTotal');
         
         if s1==0
            mem1 = sscanf(m1, 'MemTotal: %f %c');
            if lower(char(mem1(2)))=='k'
               mem1 = mem1(1)*(2^10);
            elseif lower(char(mem1(2)))=='m'
               mem1 = mem1(1)*(2^20);
            elseif lower(char(mem1(2)))=='g'
               mem1 = mem1(1)*(2^30);
            else
               mem1 = mem1(1);
            end
         else
            mem1 = 0;
         end
         
         if s2==0
            mem2 = sscanf(m2, 'SwapTotal: %f %c');
            if lower(char(mem2(2)))=='k'
               mem2 = mem2(1)*(2^10);
            elseif lower(char(mem1(2)))=='m'
               mem2 = mem2(1)*(2^20);
            elseif lower(char(mem2(2)))=='g'
               mem2 = mem2(1)*(2^30);
            else
               mem2 = mem2(1);
            end
         else
            mem2 = 0;
         end
         
         mem_found = (mem1 + mem2)/(2^30);
         fprintf('\nTotal memory (physical+swap) found: %6.2fGB\n', double(mem_found))
         
         if mem_found<min_memory_required
            low_memory_machine = true;
         end
      end
      
   catch  % all of memory detection
      fprintf(['\n\nBDP could not reliably detect memory on this system. \n\n' ...
               'Distortion-correction and co-registration usually requires approx. 6GB\n'...
               'of available memory to run. In case you encounter errors due to lack of\n'...
               'memory, you can try following options:\n\n'...
               '   1. Close other running applications and restart BDP.\n\n'...
               '   2. Enable or add enough virtual memory to your system. It may slow\n'...
               '      down your system and take longer to run, but it will produce\n'...
               '      better results than option 4 below. This is a bit of an advanced\n'...
               '      procedure, so look up documentation on how to do this for your\n'...
               '      operating system.\n\n' ...
               '   3. Run BDP with the flag --ignore-memory to ignore this warning and\n'...
               '      continue with processing. This may cause BDP to exit with errors\n'...
               '      if it cannot allocate enough memory.\n\n'...
               '   4. Run BDP with the flag --low-memory to run the distortion\n'...
               '      correction at a lower resolution. This may result in decreased\n'...
               '      accuracy while performing distortion correction.\n\n']);
   end
   
   
   if low_memory_machine
      if ismac
         fprintf(1, ['\nThe current machine may not have enough memory (approx 6GB) available for\n' ...
                     'BDP to run. However, Mac OS X usually has a large swap memory, so we will\n'...
                     'continue with the processing.\n\n'...
                     'In case you encounter errors, you can try following options:\n\n'...
                     '   1. Try closing other running applications and re-run BDP.\n\n'...
                     '   2. Run BDP with the flag --ignore-memory to ignore this memory check\n'...
                     '      and proceed with processing. This may cause BDP to exit with\n'...
                     '      errors if it cannot allocate enough memory.\n\n'...
                     '   3. Run BDP with the flag --low-memory, which will run the distortion\n'...
                     '      correction at lower resolution. This may result in decreased'...
                     '      accuracy while performing distortion correction.\n\n']);
      else
          error('BDP:LowMemoryMachine', 'Not enough free memory found.')
      end
   end
end


%% temp files/folders
workDir = tempname();
mkdir(workDir);

% Test distortion correction inputs 
if opt.fieldmap_distortion_correction && opt.registration_distortion_correction
   error('Both distortion correction options can not be true.')
end

%% Pre-registration 
% Reorient to canonical coordinate system, if required
[dwi_filename, bmat_file] = reorientDWI_BDP(dwi_filename, ...
   [file_base opt.dwi_fname_suffix '.RAS.nii.gz'], bmat_file, opt);

% Extract b=0 image & maks
fprintf('\nExtracting 0-diffusion (b=0) image from input DWIs...');
[dwi_rearranged_b0_file, dwi_mask_file, dwi_mask_less_csf_file] = ...
   mask_b0_setup(dwi_filename, opt, bmat_file, workDir);


%% Distortion correction
if opt.fieldmap_distortion_correction
   fprintf('Performing distortion correction using fieldmap...');      
   opt.fieldmap_options.mask = dwi_mask_file;
   opt.fieldmap_options.b0_file = dwi_rearranged_b0_file;
   dwi_correct_filename = [remove_extension(dwi_filename) opt.dwi_corrected_suffix '.nii.gz'];
   EPI_correct_file_fieldmap(dwi_filename, opt.fieldmap_options.field_filename, dwi_correct_filename, opt.fieldmap_options)
   
   fprintf('\nCorrecting DWI mask...'); 
   dwi_mask_correct_fname = suffix_filename(dwi_mask_file, opt.dwi_corrected_suffix);
   opt.fieldmap_options.checkFOV = false;
   opt.fieldmap_options.leastsq_sol = false;
   EPI_correct_file_fieldmap(dwi_mask_file, opt.fieldmap_options.field_filename, dwi_mask_correct_fname, opt.fieldmap_options)
   temp_msk = load_untouch_nii_gz(dwi_mask_correct_fname);
   temp_msk.img = (temp_msk.img>170)*255; % only use voxels with high value
   save_untouch_nii_gz(temp_msk, dwi_mask_correct_fname);
   dwi_mask_file = dwi_mask_correct_fname;
   
   fprintf('\nDistortion correction finished.\n');
   
elseif opt.registration_distortion_correction
   fprintf('\n\nStarting Registration based distortion Correction...\n');
   dwi_correct_filename = [remove_extension(dwi_filename) opt.dwi_corrected_suffix '.nii.gz'];
   struct_output_filename = [file_base '.bfc' opt.Diffusion_coord_suffix '.nii.gz'];
   opt.registration_distortion_corr_options.epi_mask = dwi_mask_file;
   opt.registration_distortion_corr_options.epi_mask_less_csf = dwi_mask_less_csf_file;
   
   if strcmpi(opt.registration_correction_method, 'mi')
      EPI_correct_files_registration_BDP17(dwi_rearranged_b0_file, bfc_filename, dwi_correct_filename, struct_output_filename, ...
         opt.registration_distortion_corr_options);
   else
      EPI_correct_files_registration_INVERSION(dwi_rearranged_b0_file, bfc_filename, dwi_correct_filename, struct_output_filename, ...
         opt.registration_distortion_corr_options);
   end
   
   % distortion correct (warp) all diffusion images
   fprintf('\nCorrecting all diffusion images for distortion...\n')
   t_epi = load_untouch_nii_gz([remove_extension(dwi_correct_filename) '.distortion.map.nii.gz'], true, workDir);
   DWI_orig = load_untouch_nii_gz(dwi_filename, true, workDir);
   
   [x_g, y_g, z_g] = ndgrid(1:size(DWI_orig.img,1), 1:size(DWI_orig.img,2), 1:size(DWI_orig.img,3));
   switch opt.phase_encode_direction
      case {'x', 'x-'}
         x_g = x_g + t_epi.img;
         if opt.intensity_correct
            [~, crct_grd] = gradient(t_epi.img);
         end
      case {'y', 'y-'}
         y_g = y_g + t_epi.img;
         if opt.intensity_correct
            [crct_grd] = gradient(t_epi.img);
         end
      case {'z', 'z-'}
         z_g = z_g + t_epi.img;
         if opt.intensity_correct
            [~, ~, crct_grd] = gradient(t_epi.img);
         end
   end
   
%    moving_out = DWI_orig;
%    moving_out.img = zeros(size(DWI_orig.img));
   cpb = ConsoleProgressBar(); % Set progress bar parameters
   cpb.setMinimum(1);
   cpb.setMaximum(size(DWI_orig.img,4));
   cpb.start();
   for k = 1:size(DWI_orig.img,4)
      DWI_orig.img(:,:,:,k) = interpn(double(DWI_orig.img(:,:,:,k)), x_g, y_g, z_g, 'cubic', 0);
      if opt.intensity_correct
         DWI_orig.img(:,:,:,k) = double(DWI_orig.img(:,:,:,k)) .* (1+crct_grd);
      end
      text = sprintf('%d/%d volumes done', k, size(DWI_orig.img,4));
      cpb.setValue(k); cpb.setText(text);
   end
   cpb.stop();
   
   % save corrected data
   disp('Saving corrected diffusion data...')
   DWI_orig.hdr.dime.scl_slope = 0;
   DWI_orig.hdr.dime.scl_inter = 0;
   save_untouch_nii_gz(DWI_orig, dwi_correct_filename, workDir);
   clear DWI_orig crct_grd x_g y_g z_g t_epi DWI_orig_res
   fprintf('\nDistortion correction finished.\n');
else
   dwi_correct_filename = dwi_filename;
   fprintf('Distortion Correction skipped.\n');
end
clear struct_output_filename

% extract corrected b=0 image from corrected DWIs
if opt.fieldmap_distortion_correction || opt.registration_distortion_correction
   DEout = checkDiffusionEncodingScheme(bmat_file, opt.bval_ratio_threshold);
   num_b0s = sum(DEout.zero_bval_mask);
   fprintf('Extracting distortion corrected 0-diffusion (b=0) image...');
   dwi_rearranged_b0_file = [remove_extension(dwi_correct_filename) '.rearranged.b0s.nii.gz'];
   dwi = load_untouch_nii_gz(dwi_correct_filename, workDir);
   b0s = dwi;
   b0s.img = dwi.img(:,:,:,DEout.zero_bval_mask);
   b0s.hdr.dime.dim(5) = num_b0s;
   save_untouch_nii_gz(b0s, dwi_rearranged_b0_file, workDir);
   clear dwi b0s
   fprintf('Done\n');
end

%% - - - - Rigid Register volumes - - - - %
if ~opt.registration_distortion_correction
   reg_options = struct( ...
      'moving_mask', opt.t1_mask_file, ...
      'static_mask', dwi_mask_file, ...
      'pngout', opt.pngout, ...
      'verbose', opt.verbose, ...
      'similarity', opt.rigid_similarity, ...
      'dof', 6,...
      'nthreads', opt.num_threads);
   
   output_filename = [file_base '.bfc' opt.Diffusion_coord_suffix '.nii.gz'];   
   register_files_affine(bfc_filename, dwi_rearranged_b0_file, output_filename, reg_options);
   
   clear output_filename reg_options moving_file static_file
end


%% - - - - Transfer data to/from diffusion-mprage coordinate - - - - %
fprintf('\nTransferring data to mprage/diffusion coordinate...');

affinematrix_file = [file_base '.bfc' opt.Diffusion_coord_suffix '.rigid_registration_result.mat'];

% diffusion to mprage coordinate
out_file = [remove_extension(dwi_correct_filename) '.0_diffusion' opt.mprage_coord_suffix '.nii.gz'];
transfer_diffusion_to_T1(dwi_rearranged_b0_file, dwi_rearranged_b0_file, bfc_filename, affinematrix_file, ...
                         out_file, 'cubic');
                      
% mprage to diffusion coordinate
[~, nm, ext] = fileparts(opt.t1_mask_file);
struct_output_filename = fullfile(fileparts(file_base), suffix_filename([nm ext], opt.Diffusion_coord_suffix));
transfer_T1_to_diffusion(opt.t1_mask_file, bfc_filename, dwi_rearranged_b0_file, affinematrix_file, ...
   struct_output_filename, 'nearest');

unmasked_struct_file = [opt.bfc_file_base '.nii.gz'];
if ~exist(unmasked_struct_file, 'file')
   unmasked_struct_file = [opt.bfc_file_base '.nii'];
end
if exist(unmasked_struct_file, 'file')==2   
   if ~isfield(opt.input_filenames, 'dwi_file') ...
         || ~strcmp(opt.input_filenames.dwi_file, unmasked_struct_file) % dwi file does NOT match unmasked_struct_file
      struct_output_filename = [file_base opt.Diffusion_coord_suffix '.nii.gz'];
      transfer_T1_to_diffusion(unmasked_struct_file, bfc_filename, dwi_rearranged_b0_file, affinematrix_file, ...
         struct_output_filename, 'cubic');
   end
   
else  % original MPRAGE not found
   [~, fName, ~] = fileparts(unmasked_struct_file);
   fName = remove_extension(fName);
   msg = {'\n', ['BDP could not transfer original unmasked MPRAGE to diffusion coordinates, as it was unable to find '...
      'the original MPRAGE file: ' escape_filename(fName) '.nii OR ' escape_filename(fName) '.nii.gz\n']};
   fprintf(bdp_linewrap(msg));
   
end
clear temp struct_output_filename

% copy D_coord files to d_coord output, if applicable
if opt.diffusion_coord_outputs
   copyfile([opt.file_base_name '*' opt.Diffusion_coord_suffix '*.nii.gz'], opt.diffusion_coord_output_folder)
end

fprintf('\nFinished transferring data to mprage/diffusion coordinate\n');

%% File cleanup
if opt.clean_files
   fprintf('Cleaning up intermediate files...');
   
   [file_base_folder, name, ext] = fileparts(file_base);
   sep = filesep;
   
   if ~isempty(file_base_folder) 
      file_base_folder = [file_base_folder sep];
   end
   
   % delete hdr_transform files
   listing = dir([file_base '*.headr_transform.nii.gz']);
   for k = 1:length(listing)
      delete([file_base_folder listing(k).name])
   end
   
   % delete rearranged dwis and bmat
   delete(fullfile(fileparts(dwi_filename), '*.rearranged*.nii.gz'));
   delete(fullfile(fileparts(dwi_filename), '*.rearranged*.bmat'));
   
   if opt.fieldmap_distortion_correction
      delete(fullfile(fileparts(file_base), 'fieldmap.radians.used.nii.gz'));
   end
   
   % delete b=0 images 
   temp = [remove_extension(dwi_filename) '.0_diffusion.nii.gz'];
   if exist(temp, 'file'), delete(temp); end
   
   temp = [remove_extension(dwi_filename) '.0_diffusion.mask.nii.gz'];
   if exist(temp, 'file'), delete(temp); end
   
   temp = [remove_extension(dwi_filename) opt.dwi_corrected_suffix '.0_diffusion.nii.gz'];
   if exist(temp, 'file'), delete(temp); end

   % delete bfc file in custom output folder
   if ~strcmpi(opt.file_base_name, opt.bfc_file_base)
      delete(bfc_filename); 
   end      
   
   fprintf('Done\n');
else
   fprintf('Intermediate files generated by BDP will not be deleted.\n');
end

%%

rmdir(workDir, 's');
fprintf('\nCoregisteration of Diffusion and MPRAGE is done!\n\n')

end



function opts = parse_input_COREGISTERDIFFUSIONMPRAGEPIPELINE(in_opts)

if ~isstruct(in_opts)
   error('in_opts must to be a matlab structure')
end
opts = in_opts;

% default settings for registration based distortion correction

if strcmpi(opts.registration_correction_method, 'mi')
   registration_distortion_corr_options = struct(...
      'similarity', 'mi', ...
      'rigid_similarity', in_opts.rigid_similarity, ... 
      'struct_mask', in_opts.t1_mask_file, ...
      'epi_mask', in_opts.dwi_mask_file, ...
      'pngout', in_opts.pngout, ...
      'num_threads',  in_opts.num_threads, ... 
      'intensity_correct', in_opts.intensity_correct, ... 
      'phase_encode_direction', in_opts.phase_encode_direction, ...  % x/y/z
      'Penalty', in_opts.regularization_scale_wt*[5e-4 1e-8 0], ...  % Spatial regularization [in-plane orthognal-to-plane 0]
      'debug', false, ...
      'verbose', in_opts.verbose, ...
      'dense_grid', ~(in_opts.low_memory) ...
      );
   
elseif ismember(opts.registration_correction_method, {'inversion-epi-t1', 'inversion-t1', 'inversion-epi', 'bdp'})
   
   registration_distortion_corr_options = struct(...
      'similarity', in_opts.registration_correction_method, ...
      'rigid_similarity', in_opts.rigid_similarity, ... 
      'struct_mask', in_opts.t1_mask_file, ...
      'epi_mask', in_opts.dwi_mask_file, ...
      'pngout', in_opts.pngout, ...
      'num_threads',  in_opts.num_threads, ...  
      'intensity_correct', in_opts.intensity_correct, ... 
      'phase_encode_direction', in_opts.phase_encode_direction, ...
      'Penalty', [in_opts.regularization_scale_wt 0.00000001 0.0000001],...[alpha kx bigkx ky]
      'debug', false, ...
      'verbose', in_opts.verbose, ...
      'non_uniformity_correction', in_opts.non_uniformity_correction ...
      );
else
   error('BDP:NotIncluded', ['Distortion correction based on this similarity measure '...
      'is not included yet: %s\n'], opts.registration_correction_method);
end

% default settings for Fieldmap based distortion correction
if in_opts.fieldmap_leastsq
   interp_method = 'linear';
else
   interp_method = 'cubic';
end
fieldmap_options = struct(...
   'field_filename', in_opts.fieldmap_file, ...
   'echo_spacing', in_opts.echo_spacing, ...   % Echo Spacing in sec
   'smooth', ~isempty(in_opts.fieldmap_smooth3_sigma), ...
   'smooth_sigma', in_opts.fieldmap_smooth3_sigma, ...
   'phase_encode_direction', in_opts.phase_encode_direction, ... % x/y/z/z-/y-/z-
   'interpolation_method', interp_method, ...
   'siemens_correct', false, ... % ONLY for Siemens saved fieldmap
   'intensity_correct', in_opts.intensity_correct, ...
   'ignore_FOV_errors', in_opts.ignore_fmap_FOV_errors, ...
   'mask', in_opts.dwi_mask_file, ...
   'checkFOV', true, ...
   'leastsq_sol', in_opts.fieldmap_leastsq ...
   );


if isfield(in_opts, 'registration_distortion_corr_options')
   fnames = fieldnames(in_opts.registration_distortion_corr_options);
   for iname = 1:length(fnames)
      registration_distortion_corr_options = setfield(registration_distortion_corr_options, fnames{iname}, ...
         getfield(in_opts.registration_distortion_corr_options, fnames{iname}));
   end
end
opts.registration_distortion_corr_options = registration_distortion_corr_options;

if isfield(in_opts, 'fieldmap_options')
   fnames = fieldnames(in_opts.fieldmap_options);
   for iname = 1:length(fnames)
      fieldmap_options = setfield(fieldmap_options, fnames{iname}, ...
         getfield(in_opts.fieldmap_options, fnames{iname}));
   end
end
opts.fieldmap_options = fieldmap_options;


% some sanity checks 
if opts.fieldmap_distortion_correction 
   opts.ignore_memory = true; 
end

if opts.ignore_memory
   opts.low_memory = false;
   opts.registration_distortion_corr_options.dense_grid = ~(opts.low_memory);
end

if opts.fieldmap_distortion_correction && isempty(opts.echo_spacing)
   error('BDP:FlagError', ['Echo spacing must be specified when using fieldmap distortion correction.' ...
                              'Please use flag --echo-spacing=t to set echo spacing to t seconds.\n']);
end


end


function [dwi_rearranged_b0_file, dwi_mask_file, dwi_mask_less_csf_file] = mask_b0_setup(dwi_filename, bdp_opts, bmat_file, workDir)

% extract b=0 image
DEout = checkDiffusionEncodingScheme(bmat_file, bdp_opts.bval_ratio_threshold);
num_b0s = sum(DEout.zero_bval_mask);
if num_b0s>0
   dwi_rearranged_b0_file = [remove_extension(dwi_filename) '.rearranged.b0s.nii.gz'];
   dwi = load_untouch_nii_gz(dwi_filename, workDir);
   b0s = dwi;
   b0s.img = dwi.img(:,:,:,DEout.zero_bval_mask);
   b0s.hdr.dime.dim(5) = num_b0s;
   save_untouch_nii_gz(b0s, dwi_rearranged_b0_file, workDir);
else
   err_msg = ['BDP could not detect any volume without diffusion weighting (b-value = 0) in the input diffusion data. ', ...
      'b-value = 0 image is required for co-registration and distortion correction. Please make sure that the input '...
      'diffusion parameters files (bvec/bval/bmat) have correct information. In order to use diffusion image with '...
      'low b-value as b=0 image, please use the flag --bval-ratio-threshold to adjust the threshold.'];
   error('BDP:InvalidFile', bdp_linewrap(err_msg))
end

% Setup b=0 masks
mskfile_base = remove_extension(dwi_filename);
if isempty(bdp_opts) || isempty(bdp_opts.dwi_mask_file)
   msg = {'\n\n', ['DWI mask is not defined in input flags. BDP will try to estimate a (pseudo) mask from 0-diffusion (b=0) image. '...
      'Automatic mask estimation may not be accurate in some sitations and can affect overall quality of co-registration. '...
      'In case co-registration is not accurate, you can define a DWI mask by using flag --dwi-mask <mask_filename>. The '...
      'mask can be generated and hand edited in BrainSuite interface. This mask would be used only for registration '...
      'purposes (and not for statistics computation).'], '\n'};
   fprintf(bdp_linewrap(msg)); drawnow update;
   
   switch lower(bdp_opts.dwi_pseudo_masking_method)
      case 'intensity'
         masking_approach = 1;
      case 'hist'
         masking_approach = 2;
      otherwise
         error('BDP:FlagError', ['Invalid DWI masking method: %s \nValid '...
            'options are: "hist" or "intensity".'], bdp_opts.dwi_pseudo_masking_method);
   end
   [dwi_mask_file, dwi_mask_less_csf_file] = maskDWI(dwi, mskfile_base, bmat_file, masking_approach);
   fprintf('Saved (pseudo) masks: %s\n', escape_filename(dwi_mask_file));
   
else % user defined; only refine to remove CSF
   [mask, dwi_mask_file] = fixBSheader(dwi_rearranged_b0_file, bdp_opts.dwi_mask_file, ...
      fullfile(workDir, 'dwi_pseudo_mask.nii.gz'));
   
   dwi_mean = b0s;
   dwi_mean.hdr.dime.dim(1) = 3;
   dwi_mean.hdr.dime.dim(5) = 1;
   dwi_mean.img = double(mean(dwi.img(:,:,:,~DEout.zero_bval_mask), 4));
   mask_dwi = maskHeadPseudoHist(dwi_mean, true); % aggresive DWI masking
   
   mask_less_csf = mask;
   mask_less_csf.img = (imerode(mask.img>0, strel_sphere(3)) | mask_dwi.img>0) & mask.img>0;
   mask_less_csf.img = largest_connected_component(mask_less_csf.img, 6);
   mask_less_csf.img = uint8(mask_less_csf.img>0)*255; % make BrainSuite compatible
   dwi_mask_less_csf_file = save_untouch_nii_gz(mask_less_csf, [mskfile_base '.less_csf.mask.nii.gz'], 2);
end

clear dwi mask b0s
end

% Find the biggest connected component
function out = largest_connected_component(mask, conn)

cc = bwconncomp(mask, conn);
if cc.NumObjects>1
   cc_size = [];
   for k = 1:cc.NumObjects
      cc_size(k) = length(cc.PixelIdxList{k});
   end
   [~,IX] = sort(cc_size,'descend');
   out = false(size(mask));
   out(cc.PixelIdxList{IX(1)}) = true;
else
   out = mask;
end
end


