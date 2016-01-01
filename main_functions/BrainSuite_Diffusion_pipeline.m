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


function BrainSuite_Diffusion_pipeline(varargin)
% Main BDP function. See about_BDP.txt and license.txt for more information about BDP.

bdp_ticID = tic;
warning('off', 'MATLAB:maxNumCompThreads:Deprecated');
warning('off', 'BDP:UnknownOptions'); % BDP:UnknownOptions is being used for dev
warning('off', 'MATLAB:nearlySingularMatrix');

try
   [earlyExit] = bdp_preprocess_input(varargin{:});
   if earlyExit, return; end
   
   opts = bdp_setup(varargin{:});
   fprintf('\nProcessing data with fileprefix:\n\t%s\n', opts.bfc_file_base);
   
   if ~opts.generate_only_stats && ~opts.only_transform_data
      
      if opts.no_structural_registration
         [dwi_corr_file, bmat_file] = reorientDWI_BDP(opts.dwi_file, ...
            [opts.file_base_name opts.dwi_fname_suffix '.RAS.nii.gz'], opts.bmat_file, opts);
         if opts.fieldmap_distortion_correction
            dwi_corr_file = fmap_correction_no_structural_registration(dwi_corr_file, opts);
         end
         
      else
         [dwi_corr_file, bmat_file] = coregister_diffusion_mprage_pipeline(opts);
         affinematrix_file = [opts.file_base_name '.bfc' opts.Diffusion_coord_suffix '.rigid_registration_result.mat'];
      end
      
      if opts.estimate_odf_FRT || opts.estimate_odf_FRACT
         bdpPrintSectionHeader('Estimating Diffusion ODFs');
         if ~opts.no_structural_registration
            estimate_SH_FRT_FRACT_mprage(dwi_corr_file, opts.bfc_file, affinematrix_file, bmat_file, opts);
         end
         
         if opts.diffusion_coord_outputs || opts.no_structural_registration
            uopts = opts;
            uopts.FRT_out_dir = fullfile(opts.diffusion_coord_output_folder, 'FRT');
            uopts.FRACT_out_dir = fullfile(opts.diffusion_coord_output_folder, 'FRACT');
            estimate_SH_FRT_FRACT(dwi_corr_file, bmat_file, uopts);
         end
      end
      
      if opts.estimate_tensor
         bdpPrintSectionHeader('Estimating Diffusion Tensors');
         if ~opts.no_structural_registration
            estimate_tensors_mprage(dwi_corr_file, opts.bfc_file, affinematrix_file, bmat_file, opts);
         end
         
         if opts.diffusion_coord_outputs || opts.no_structural_registration
            uopts = opts;
            uopts.tensor_out_dir = opts.diffusion_coord_output_folder;
            estimate_tensors(dwi_corr_file, bmat_file, uopts);
         end
      end
   end
   
   % rigid transform data, if required
   transform_data_rigid(opts);
   
   if opts.generate_stats
      if ~exist('dwi_corr_file', 'var')
         if (opts.fieldmap_distortion_correction || opts.registration_distortion_correction) ...
               && exist([opts.file_base_name opts.dwi_fname_suffix '.RAS' opts.dwi_corrected_suffix '.nii.gz'], 'file')
            dwi_corr_file = [opts.file_base_name opts.dwi_fname_suffix '.RAS' opts.dwi_corrected_suffix '.nii.gz'];
            
         elseif ~(opts.fieldmap_distortion_correction || opts.registration_distortion_correction) ...
               && exist([opts.file_base_name opts.dwi_fname_suffix '.RAS.nii.gz'], 'file')
            dwi_corr_file = [opts.file_base_name opts.dwi_fname_suffix '.RAS.nii.gz'];
            
         else
            err_msg = ['BDP can not find the diffusion file written by it. Please make sure that you ran '...
               'BDP on fileprefix: ' escape_filename(opts.file_base_name) '\nIf you did run BDP previously, '...
               'please make sure that all flags, except --generate-only-stats, are exactly same as previous '...
               'BDP run. You can find the command used in BDP summary file (<fileprefix>.BDPSummary.txt).'];
            error('BDP:ExpectedFileNotFound', bdp_linewrap(err_msg));
         end
      end
      generate_diffusion_stats(dwi_corr_file, opts);
      
      if opts.diffusion_coord_outputs
         generate_diffusion_stats_diffusion_coord(dwi_corr_file, opts)
      end
   end
   
   if ~opts.no_structural_registration
      bdpWriteBST(opts);
   end
   rmdir(opts.temp_file_workdir, 's')
   
   % write configuration file if required..
   summary_fname = bdp_summary(opts, varargin, bdp_ticID);
   fprintf('\n\nBDP finished all processing on %s for data with fileprefix:\n\t%s \n\n', datestr(clock), opts.bfc_file_base);
   fprintf('A summary of the processing is saved in file:\n\t%s \n\n', summary_fname);
   
catch err
   bdp_error_handler(err);
end
end

function dwi_correct_filename = fmap_correction_no_structural_registration(dwi_filename, in_opts)

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

dwi_correct_filename = [remove_extension(dwi_filename) in_opts.dwi_corrected_suffix '.nii.gz'];
EPI_correct_file_fieldmap(dwi_filename, fieldmap_options.field_filename, dwi_correct_filename, fieldmap_options)

end
