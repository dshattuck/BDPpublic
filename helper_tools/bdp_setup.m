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


function bdp_options = bdp_setup(varargin)
%
% Takes the input from the main BrainSuite Diffusion Pipeline program and
% parses it, to set up everything for the rest of the pipeline.
%
% Development flags
%
% --verbose                                Enables verbose mode, which shows various details of
%                                          optimization process and other details. Useful for
%                                          detailed logging and debugging. 
%                                          Note that -v = version & NOT verobse!
%
% --keep-temp-files                        BDP generates many intermediate files, which could be
% -k                                       useful for debugging. This flag disables deletion of all
%                                          the intermediate files at the end of processing.
%
% --png-out                                Write png files showing various types of overlayes. It
% -p                                       can be useful to check output and performance of
%                                          alignment/distortion correction visually. This may
%                                          require *huge* running memory and can lead to
%                                          out-of-memory error on low end machines.
%
%

bdpPrintSectionHeader('Setting up dataset and inputs');
disp('Reading input flags...')

workdir = tempname();
mkdir(workdir);

% Default options struct
bdp_options = struct( ...
   ... main file names
   'temp_file_workdir', workdir, ...
   'file_base_name', [], ... % act as output file base
   'bfc_file_base', [], ... 
   'bfc_file', [], ...
   't1_mask_file', [], ...
   'dwi_file', [], ...
   'dwi_mask_file', [], ...
   'bmat_file', [], ...
   'bvec_file', [], ...
   'input_filenames', [], ... % stores filenames of input files, just in case
   ...
   ... structural options
   'no_structural_registration', false, ...
   ...
   ... distortion correction options
   'phase_encode_direction', 'y', ...
   'intensity_correct', true, ...
   'non_uniformity_correction', true, ...
   'registration_distortion_correction', true, ...
   'registration_correction_method', 'bdp', ...
   'regularization_scale_wt', 1.0, ...
   'low_memory', false, ...
   'ignore_memory', false, ...
   ...
   ... more registration options
   'rigid_similarity', 'bdp', ...
   'dwi_pseudo_masking_method', 'hist', ...
   ...
   ... fieldmap correction
   'fieldmap_distortion_correction', false, ...
   'fieldmap_file', [], ...
   'echo_spacing', [], ...
   'fieldmap_smooth3_sigma', [], ...
   'ignore_fmap_FOV_errors', false, ...
   'fieldmap_leastsq', true, ...
   ...
   ... tensor/FRT/FRACT/3DSHORE/GQI odf
   'estimate_tensor', false, ...
   'estimate_odf_FRACT', false, ...
   'estimate_odf_FRT', false, ...
   'estimate_odf_3DSHORE', false, ...
   'estimate_odf_GQI',false, ...
   'odf_lambda', 0.006, ...
   'diffusion_time', 0, ...
   'sigma_gqi',1.25, ...
   'shore_radial_ord',6,...
   'diffusion_coord_outputs', false, ...
   'diffusion_coord_output_folder', [], ...
   'diffusion_modelling_mask', [], ... % mask filename in diffusion coordinate
   'bMatrixCond', [], ...
   'bval_ratio_threshold', 45, ... ratio of 900 to 20
   'num_of_estimated_b0s', [], ...
   ...
   ... stats options
   'generate_stats', false, ...
   'generate_only_stats', false, ...
   'force_partial_roi_stats', false, ...
   'custom_diffusion_label', [], ...
   'custom_T1_label', [], ...
   'custom_label_description_xml', [], ...
   ...
   ... transform data
   'only_transform_data', false, ...
   'custom_T1_volume', [], ...
   'custom_diffusion_volume', [], ...
   'interp_method', 'linear',...
   'custom_T1_surface', [], ...
   'custom_diffusion_surface', [], ...
   ...
   ...
   'pngout', false, ...
   'clean_files', true, ...
   'verbose', false, ...
   'num_threads', 4, ...
   ...
   ...
   'Diffusion_coord_suffix', '.D_coord', ...
   'mprage_coord_suffix', '.T1_coord', ...
   'dwi_fname_suffix', '.dwi', ...
   'dwi_corrected_suffix', '.correct', ...
   ...
   ...
   'bdp_version', bdp_get_version(), ... version with build# as string 
   'bdp_execdir', bdp_get_deployed_exec_dir());

%% Check for diffusion input
lower_varargin = lower(varargin);
diffusion_data_flags = {'--nii'};
if ismember('-d', lower_varargin) % old DICOM flag
   error('BDP:FlagError', bdp_linewrap(['-d flag (DICOM input) is not supported anymore. Only NIfTI-1 input files ' ...
      '(.nii/.nii.gz) are supported via --nii flag. Please use your favorite dicom-to-nifti converter. '...
      'See additional-tools page for a dicom-to-nifti converter with limited support: '...
      'http://brainsuite.org/processing/additional-tools/\n']));
   
elseif ~(ismember(diffusion_data_flags, lower_varargin))
   error('BDP:MandatoryInputNotFound', bdp_linewrap(['Diffusion data is a mandatory input. --nii flag must '...
      'be used to define input diffusion data.']));
end

%% check if BFC file & --no-structural-registration co-exists then Grab the BFC file & output file prefix
arg1 = varargin{1};
if exist(arg1, 'file')==2
   if ismember({'--no-structural-registration'}, lower_varargin)
      error('BDP:FlagError', [bdp_linewrap(['The flag --no-structural-registration can not be combined with a bfc fileinput. '...
         'Please see the usage below and make sure that the first argument is correct. If you want to set output '...
         'fileprefix then use flag --output-fileprefix.']) '\n\n' bdp_usage()]);
      
   else
      if isempty(strfind(arg1, '.bfc.nii.gz')) % bfc-file found but does not have valid filename
         error('BDP:InvalidFile','The BFC file does not appear to be a valid .bfc.nii.gz file generated by BrainSuite:\n\t%s',...
            escape_filename(arg1));
         
      else % bfc-file found & seems to be valid
         bfc_file = arg1;
         bdp_options.input_filenames.bfc_file = bfc_file;
         k = strfind(bfc_file, '.bfc.nii.gz');
         bfc_filebase = bfc_file(1:k-1);
         bdp_options.bfc_file_base = bfc_filebase;
         bdp_options.file_base_name = bfc_filebase;
         filebase_name = bfc_filebase; % act as output file base
         iflag = 2; % skip first flag in next part 
      end
   end
   
else % arg1 is not a filename which could be found on disk
   
   if ismember({'--no-structural-registration'}, lower_varargin) && arg1(1)~='-' % First argument must be a flag 
      error('BDP:FlagError', [bdp_linewrap(['--no-structural-registration was found among inputs flags and while using it '...
         'the first argument to BDP must be a flag. Please see the usage below and make sure that the '...
         'first argument is correct:\t']) escape_filename(arg1) '\n\n' bdp_usage()]);
   
   elseif ismember({'--no-structural-registration'}, lower_varargin)
      [bdp_options, bfc_file, bfc_filebase, filebase_name] = setupNoStructuralRegistration(varargin, bdp_options);
      iflag = 1;
      
   elseif arg1(1)=='-' % may be flag but without --no-structural-registration among other flags
      error('BDP:FlagError', [bdp_linewrap(['The first argument to BDP should be either a bfc filename or '...
         'a flag. Please see the usage below and make sure that the '...
         'first argument is correct:\t']) escape_filename(arg1) '\n\n' bdp_usage()]);
   else
      error('BDP:FileDoesNotExist','BDP could not find the bfc file:\n\t%s', escape_filename(arg1));
   end
end

%% Parse remaining inputs - No processing

% check for flag configuration file
flag_cell = varargin;
nflags = nargin;
[Lia, Locb] = ismember({'--flag-conf-file'}, varargin);
if Lia % flag found
   if (Locb+1)>nargin
      error('BDP:FlagError','--flag-conf-file must be followed by a file name.');
   else      
      config_flag = readFlagConfigFile(varargin{Locb+1});
      flag_cell(Locb:Locb+1) = [];
      flag_cell = [flag_cell(1) config_flag{:} flag_cell(2:end)];
      nflags = length(flag_cell);
   end
end

while iflag <= nflags
   inpt = strtrim(lower(flag_cell{iflag}));
   
   switch inpt
      case '--no-structural-registration'
         % do nothing here, handelled in previous block to call setupNoStructuralRegistration()
         
      case '--output-fileprefix' % handelled in setupNoStructuralRegistration(); show warning
         if (iflag+1 > nflags)
            error('BDP:FlagError', 'An output fileprefix string must be specified after --output-fileprefix flag.');
         elseif ~ismember({'--no-structural-registration'}, lower_varargin)
            msg = {['\nThe flag --output-fileprefix and its argument ''' flag_cell{iflag+1} ...
               ''' will be ignored as --no-structural-registration was not used.'], '\n'};
            fprintf(bdp_linewrap(msg));            
         end
         iflag = iflag + 1;
         
      case '--output-subdir'
         if (iflag+1 > nflags)
            error('BDP:FlagError','--output-subdir must be followed by a folder name.');
         else
            % clean up input subdir
            output_subdir = deblank(flag_cell{iflag+1});
            iflag = iflag + 1;
            if output_subdir(end)=='/' || output_subdir(end)=='\'
               output_subdir = output_subdir(1:end-1);
            end
            
            % check for nested structure
            [pthstr, ~, ~] = fileparts(output_subdir);
            [bfc_pth, bfc_nm, bfc_e] = fileparts(bfc_filebase);
            output_subdir = fullfile(bfc_pth, output_subdir); % make full directory
            if ~isempty(pthstr)
               msg = ['\nSub directory specified by --output-subdir flag seems to have nested structure. BDP '...
                  'will assume that it is the desired output sub-directory and will try to write outputs to following '...
                  'directory: ' escape_filename(output_subdir)];
               fprintf(bdp_linewrap(msg));
            end
            
            % create folder 
            if exist(output_subdir, 'dir')
               msg = {['\nOutput sub-directory already exists: ' escape_filename(output_subdir)], '\n', ['The files in the '...
                  'output folder can be overwritten.'], '\n'};
               fprintf(bdp_linewrap(msg));
               bdp_options.file_base_name = fullfile(output_subdir, [bfc_nm bfc_e]);
               filebase_name = bdp_options.file_base_name;
               
            else
               if mkdir(output_subdir)
                  bdp_options.file_base_name = fullfile(output_subdir, [bfc_nm bfc_e]);
                  filebase_name = bdp_options.file_base_name;
               else
                  err_msg = ['BDP could not create the output directory: ' escape_filename(output_subdir) ...
                     '\n Please make sure that sub-directory following --output-subdir flag is a valid directory '...
                     'name on your operating system and has writable permission(s).'];
                  error('BDP:FlagError', bdp_linewrap(err_msg));
               end
            end                                    
         end
         
      case '--low-memory'
         bdp_options.pngout = false;
         bdp_options.low_memory = true;
         
      case '--ignore-memory'
         bdp_options.ignore_memory = true;
         
      case '--debug'
         error('BDP:FlagError', '--debug flag is not supported anymore. For verbose output use --verbose');
         
      case '--verbose'
         bdp_options.verbose = true;
         
      case '--no-intensity-correction'
         bdp_options.intensity_correct = false;
         
      case '--no-distortion-correction'
         bdp_options.fieldmap_distortion_correction = false;
         bdp_options.registration_distortion_correction = false;
         
      case '--no-nonuniformity-correction'
         bdp_options.non_uniformity_correction = false;
         
      case {'-k', '--keep-temp-files'}
         bdp_options.clean_files = false;
         
      case {'-p', '--png-out'}
         bdp_options.pngout = true;
         
      case {'-kp','-pk'}
         bdp_options.clean_files = false;
         bdp_options.pngout = true;            
         
      case '--odf'
        error('BDP:FlagError', '--odf flag is not supported anymore. Please select the odf methods to run using method specific flags instead. Supported odf method flags : --frt and/or --fract and/or --3dshore and/or --gqi.');
         
      case '--fract'
         bdp_options.estimate_odf_FRACT = true;
         
      case '--frt'
         bdp_options.estimate_odf_FRT = true;
      
	  case '--3dshore'
         bdp_options.estimate_odf_3DSHORE = true;
		
	  case '--gqi'
         bdp_options.estimate_odf_GQI = true;
		 
      case '--diffusion_time_ms'
         if (iflag + 1 > nflags)
            error('BDP:FlagError', 'Diffusion time in ms must be specified after --diffusion_time_ms.');
         end
         diffusion_time = str2double(flag_cell{iflag+1});
         if isnan(diffusion_time)
            error('BDP:FlagError', 'Diffusion time(ms) specified after --diffusion_time_ms flag must be numeric: %s',...
               flag_cell{iflag+1});
         else
            bdp_options.diffusion_time = diffusion_time*10^-3;
         end
         iflag = iflag + 1;         
		 
      case {'--tensor', '--tensors'}
         bdp_options.estimate_tensor = true;
         
      case '--no-reorientation'
         fprintf('\nThe flag --no-reorientation has been deprecated and has no effect on BDP.\n')
         
      case {'--output-diffusion-coordinate', '--output-diffusion-coordinates'}
         bdp_options.diffusion_coord_outputs = true;
         
      case {'--transform-data-only', '--only-transform-data'}
         bdp_options.only_transform_data = true;
         
      case '--transform-interpolation'
         if (iflag+1 > nflags)
            error('BDP:FlagError', bdp_linewrap(['--transform-interpolation must be followed '...
               'by an interpolation method. Possible methods are nearest, linear, cubic, '...
               'and spline.']));
         else
            interp_method = flag_cell{iflag+1};
            iflag = iflag + 1;
         end
         
         switch lower(interp_method)
            case 'nearest'
               bdp_options.interp_method = 'nearest';
            case 'linear'
               bdp_options.interp_method = 'linear';
            case 'cubic'
               bdp_options.interp_method = 'cubic';
            case 'spline'
               bdp_options.interp_method = 'spline';               
            otherwise
               error('BDP:FlagError', ['Unrecognized --transform-interpolation method: %s\n'...
                  'Possible methods are "linear", "nearest", "cubic" and "spline".'], interp_method);
         end
         
      case '--transform-diffusion-volume'
         if (iflag+1 > nflags)
            error('BDP:FlagError','--transform-diffusion-volume must be followed by a file/folder name.');
         else
            vol_file_folder = flag_cell{iflag+1};
            iflag = iflag + 1;
         end
         
         if ~exist(vol_file_folder, 'file') % check for both file or folder
            error('BDP:FileDoesNotExist', ['BDP could not find --transform-diffusion-volume file/folder. Check to make sure\n'...
               'that the following file/folder exits:\n%s'], escape_filename(vol_file_folder));
         else
            bdp_options.custom_diffusion_volume = vol_file_folder;
         end
         
      case '--transform-t1-volume'
         if (iflag+1 > nflags)
            error('BDP:FlagError','--transform-t1-volume must be followed by a file/folder name.');
         else
            vol_file_folder = flag_cell{iflag+1};
            iflag = iflag + 1;
         end
         
         if ~exist(vol_file_folder, 'file') % check for both file or folder
            error('BDP:FileDoesNotExist', ['BDP could not find --transform-t1-volume file/folder. Check to make sure\n'...
               'that the following file/folder exits:\n%s'], escape_filename(vol_file_folder));
         else
            bdp_options.custom_T1_volume = vol_file_folder;
         end
         
      case '--transform-diffusion-surface'
         if (iflag+1 > nflags)
            error('BDP:FlagError','--transform-diffusion-surface must be followed by a file/folder name.');
         else
            surf_file_folder = flag_cell{iflag+1};
            iflag = iflag + 1;
         end
         
         if ~exist(surf_file_folder, 'file') % check for both file or folder
            error('BDP:FileDoesNotExist', ['BDP could not find --transform-diffusion-surface file/folder. Check to make sure\n'...
               'that the following file/folder exits:\n%s'], escape_filename(surf_file_folder));
         else
            bdp_options.custom_diffusion_surface = surf_file_folder;
         end
         
      case '--transform-t1-surface'
         if (iflag+1 > nflags)
            error('BDP:FlagError','--transform-t1-surface must be followed by a file/folder name.');
         else
            surf_file_folder = flag_cell{iflag+1};
            iflag = iflag + 1;
         end
         
         if ~exist(surf_file_folder, 'file') % check for both file or folder
            error('BDP:FileDoesNotExist', ['BDP could not find --transform-t1-surface file/folder. Check to make sure\n'...
               'that the following file/folder exits:\n%s'], escape_filename(surf_file_folder));
         else
            bdp_options.custom_T1_surface = surf_file_folder;
         end
         
      case '--generate-stats'
         bdp_options.generate_stats = true;
         
      case {'--generate-only-stats', '--generate-stats-only', '--only-generate-stats'}
         bdp_options.generate_only_stats = true;
         bdp_options.generate_stats = true;
         
      case '--force-partial-roi-stats'
         bdp_options.force_partial_roi_stats = true;               
         
      case '--custom-diffusion-label'
         if (iflag+1 > nflags)
            error('BDP:FlagError','--custom-diffusion-label must be followed by a file/folder name.');
         else
            stat_file_folder = flag_cell{iflag+1};
            iflag = iflag + 1;
         end
         
         if ~exist(stat_file_folder, 'file') % check for both file or folder
            error('BDP:FileDoesNotExist', ['BDP could not find --custom-diffusion-label file/folder. Check to make sure\n'...
               'that the following file/folder exits:\n%s'], escape_filename(stat_file_folder));
         else
            bdp_options.custom_diffusion_label = stat_file_folder;
         end
         
      case '--custom-t1-label'
         if (iflag+1 > nflags)
            error('BDP:FlagError','--custom-T1-label must be followed by a file/folder name.');
         else
            stat_file_folder = flag_cell{iflag+1};
            iflag = iflag + 1;
         end
         
         if ~exist(stat_file_folder, 'file') % check for both file or folder
            error('BDP:FileDoesNotExist', ['BDP could not find --custom-T1-label file/folder. Check '...
               'to make sure that the following file/folder exits: %s'], escape_filename(stat_file_folder));
         else
            bdp_options.custom_T1_label = stat_file_folder;
         end
         
      case '--custom-label-xml'
         if (iflag+1 > nflags)
            error('BDP:FlagError','--custom-label-xml must be followed by a file/folder name.');
         else
            stat_xml = flag_cell{iflag+1};
            iflag = iflag + 1;
         end
         
         if exist(stat_xml, 'file')~=2 % check for file
            error('BDP:FileDoesNotExist', ['BDP could not find --custom-label-xml file/folder. Check '...
               'to make sure that the following file exits: %s'], escape_filename(stat_xml));
         else
            bdp_options.custom_label_description_xml = stat_xml;
         end
         
      case '--fieldmap-correction'
         if (iflag+1 > nflags) || strcmp(flag_cell{iflag+1}(1), '-') % does not allow file names to start with '-'
            fieldmap_file = [bfc_filebase '.fieldmap.nii.gz'];
            bdp_options.input_filenames.fieldmap_file = '';
            msg = {['\nFlag --fieldmap-correction is found but it is not followed by any filename. '...
               'BDP will try to use following file as fieldmap: ' escape_filename(fieldmap_file)], '\n'};
            fprintf(bdp_linewrap(msg));
         else
            fieldmap_file = flag_cell{iflag+1};
            bdp_options.input_filenames.fieldmap_file = fieldmap_file;
            iflag = iflag + 1;
         end
         
         if exist(fieldmap_file, 'file')~=2
            error('BDP:FileDoesNotExist', ['BDP could not find fieldmap file. Check to make sure that '...
               'the following file exists:\n%s'], escape_filename(fieldmap_file));
         else
            bdp_options.fieldmap_file = fieldmap_file;
            bdp_options.fieldmap_distortion_correction = true;
            bdp_options.registration_distortion_correction = false;
         end
         
      case '--ignore-fieldmap-fov'
         bdp_options.ignore_fmap_FOV_errors = true;         
         
      case '--fieldmap-correction-method'
         if (iflag+1 > nflags)
            error('BDP:FlagError','--fieldmap-correction-method must be followed by a method name.');
         else
            fmap_method = flag_cell{iflag+1};
            iflag = iflag + 1;
         end
         
         switch lower(fmap_method)
            case {'pixelshift', 'pixel-shift'}
               bdp_options.fieldmap_leastsq = false;
            case 'leastsq'
               bdp_options.fieldmap_leastsq = true;
            otherwise
               error('BDP:FlagError', ['Unrecognized method for --fieldmap-correction-method: %s\n'...
                  'Possible methods are "pixelshift" and "leastsq".'], fmap_method);
         end         
         
      case '--rigid-reg-measure'
         if (iflag+1 > nflags)
            error('BDP:FlagError', bdp_linewrap(['--rigid-reg-measure must be followed '...
               'by a measure name. Possible measure are "MI", "INVERSION" and "BDP"']));
         else
            rigid_method = flag_cell{iflag+1};
            iflag = iflag + 1;
         end
         
         switch lower(rigid_method)
            case {'mi', 'mutualinfo', 'nmi'}
               bdp_options.rigid_similarity = 'mi';
            case 'inversion'
               bdp_options.rigid_similarity = 'inversion';
            case 'bdp'
               bdp_options.rigid_similarity = 'bdp';
            otherwise
               error('BDP:FlagError', ['Unrecognized option for --rigid-reg-measure: %s\n'...
                  'Possible measure are: MI, INVERSION and BDP.'], rigid_method);
         end
         
      case '--dcorr-reg-method'
         if (iflag+1 > nflags)
            error('BDP:FlagError','--dcorr-reg-method must be followed by a method name.');
         else
            dcorr_method = flag_cell{iflag+1};
            iflag = iflag + 1;
         end
         
         switch lower(dcorr_method)
            case {'mi', 'mutualinfo', 'nmi'}
               bdp_options.registration_correction_method = 'mi';
            case {'inversion-epi'}
               bdp_options.registration_correction_method = 'inversion-epi';
            case 'inversion-t1'
               bdp_options.registration_correction_method = 'inversion-t1';
            case {'inversion', 'inversion-both'}
               bdp_options.registration_correction_method = 'inversion-epi-t1';
            case 'bdp'
               bdp_options.registration_correction_method = 'bdp';
            otherwise               
               error('BDP:FlagError', ['Unrecognized method for --dcorr-reg-method: %s\n'...
                  'Possible methods are: MI, INVERSION-EPI, INVERSION-T1, INVERSION-BOTH, and BDP.'], dcorr_method);
         end
         
      case '--dcorr-regularization-wt'
         if (iflag + 1 > nflags)
            error('BDP:FlagError', 'A numerical weight must be specified after --dcorr-regularization-wt.');
         end
         regularization_scale_wt = str2double(flag_cell{iflag+1});
         if isnan(regularization_scale_wt)
            error('BDP:FlagError', 'The weight specified after --dcorr-regularization-wt flag must be a numeric: %s',...
               flag_cell{iflag+1});
         else
            bdp_options.regularization_scale_wt = regularization_scale_wt;
         end
         iflag = iflag + 1;         
         
      case '--nii'
         if (iflag+1 > nflags)
            error('BDP:FlagError','NIfTI flag specified but no NIfTI file is provided after --nii flag.');
         else
            dwi_nii_file = flag_cell{iflag+1};
            iflag = iflag + 1;
         end
         
         if exist(dwi_nii_file, 'file')~=2
            error('BDP:FileDoesNotExist','The input diffusion NIfTI file does not exist: %s', escape_filename(dwi_nii_file));
         end
    
      case '--t1-mask'
         if (iflag+1 > nflags)
            error('BDP:FlagError','--t1-mask must be followed by a file name.');
         else
            t1_mask_file = flag_cell{iflag+1};
            iflag = iflag + 1;
         end
         
         if exist(t1_mask_file, 'file')~=2
            error('BDP:FileDoesNotExist', ['BDP could not find --t1-mask file. Check to make sure\n'...
               'that the following file exits:\n%s'], escape_filename(t1_mask_file));
         end
         
      case '--dwi-mask'
         if (iflag+1 > nflags)
            error('BDP:FlagError','--dwi-mask must be followed by a file name.');
         else
            dwi_mask_file = flag_cell{iflag+1};
            iflag = iflag + 1;
         end
         
         if exist(dwi_mask_file, 'file')~=2
            error('BDP:FileDoesNotExist', ['BDP could not find --dwi-mask file. Check to make sure\n'...
               'that the following file exits:\n%s'], escape_filename(dwi_mask_file));
         end
         
      case '--dwi-masking-method'
         if (iflag+1 > nflags)
            error('BDP:FlagError', ['--dwi-masking-method must be followed by a masking method. Possible '...
               'options are: "hist" or "intensity".']);
         else
            valid_dwi_masking_methods = {'hist', 'intensity'};
            if ismember(lower(flag_cell{iflag+1}), valid_dwi_masking_methods)
               bdp_options.dwi_pseudo_masking_method = lower(flag_cell{iflag+1});
            else
               error('BDP:FlagError', ['Invalid --dwi-masking-method: %s \nValid '...
                  'options are: "hist" or "intensity".'], flag_cell{iflag+1});
            end
            iflag = iflag + 1;
         end
         
      case {'-g', '--bvec'}
         if (iflag + 1 > nflags)
            error('BDP:FlagError','Gradient file flag specified but no gradient file provided.');
         end
         gradient_file = flag_cell{iflag+1};
         if exist(gradient_file, 'file')~=2
            error('BDP:FileDoesNotExist','The gradient file %s does not exist', escape_filename(gradient_file));
         end;
         iflag = iflag + 1;
         
      case {'-b', '--bval'}
         if (iflag + 1 > nflags)
            error('BDP:FlagError', 'b-value flag specified but no b-value provided.');
         end
         bval = str2double(flag_cell{iflag+1});
         if isnan(bval)
            bval = flag_cell{iflag+1};
         end
         iflag = iflag + 1;
         
      case '--bval-ratio-threshold'
         if (iflag + 1 > nflags)
            error('BDP:FlagError', 'A numerical threshold must be specified after --bval-ratio-threshold flag.');
         end
         bval_ratio_threshold = str2double(flag_cell{iflag+1});
         if isnan(bval_ratio_threshold)
            error('BDP:FlagError', 'The threshold specified after --bval-ratio-threshold flag must be a numeric: %s',...
               flag_cell{iflag+1});
         else
            bdp_options.bval_ratio_threshold = bval_ratio_threshold;
         end
         iflag = iflag + 1;
         
      case '--bmat'
         if (iflag + 1 > nflags)
            error('BDP:FlagError','b-matrix flag specified but no .bmat file provided.');
         end
         bmat_file = flag_cell{iflag+1};
         if exist(bmat_file, 'file')~=2
            error('BDP:FileDoesNotExist','The given b-matrix file does not exist:\n%s', escape_filename(bmat_file));
         end;
         iflag = iflag + 1;
         
      case  '--odf-lambda'
         if (iflag + 1 > nflags)
            error('BDP:FlagError','--odf-lambda flag specified but no value of lambda provided.');
         end
         bdp_options.odf_lambda = str2double(flag_cell{iflag+1});
         if isnan(bdp_options.odf_lambda) || bdp_options.odf_lambda<0
            error('BDP:FlagError','--odf-lambda flag must be followed by a non-negative (float) number.');
         end
         iflag = iflag + 1;   
		 
	  case  '--gqi-sigma'
		 if (iflag + 1 > nflags)
			error('BDP:FlagError','--gqi-sigma flag specified but no value of the parameter provided.');
		 end
		 bdp_options.sigma_gqi = str2double(flag_cell{iflag+1});
		 if isnan(bdp_options.sigma_gqi) || bdp_options.sigma_gqi<=0
			error('BDP:FlagError','--gqi-sigma flag must be followed by a positive (float) number.');
		 end
		 iflag = iflag + 1; 
		 
  	  case  '--3dshore-radord'
		 if (iflag + 1 > nflags)
			error('BDP:FlagError','--3dshore-radord flag specified but no value of the parameter provided.');
		 end
		 bdp_options.shore_radial_ord = str2double(flag_cell{iflag+1});
		 if isnan(bdp_options.shore_radial_ord) || bdp_options.shore_radial_ord<=0
			error('BDP:FlagError','--3dshore-radord flag must be followed by a positive number.');
		 end
		 iflag = iflag + 1;  
         
      otherwise
         
         if strncmp(inpt, '--dir=', 6)
            k = strfind(inpt, '=');
            direction = inpt(k(end)+1:end);
            if ~strcmp(direction, 'x') && ~strcmp(direction, 'y') && ~strcmp(direction, 'z') ...
                  && ~strcmp(direction, 'x-') && ~strcmp(direction, 'y-') && ~strcmp(direction, 'z-')
               error('BDP:FlagError', ['Invalid phase-encoding direction given: %s. Valid directions are' ...
                  'x, y, z, x-, y-, and z-.'], escape_filename(direction));
            end
            bdp_options.phase_encode_direction = direction;
            
         elseif strncmp(inpt, '--threads=', 10)
            if length(inpt) > 10
               k = strfind(inpt, '=');
               n = str2double(inpt(k(end)+1:end));
               if ~isnan(n)
                  bdp_options.num_threads = double(uint8(n));
               else
                  error('BDP:FlagError','Unable to process parallel threads flag %s.', escape_filename(inpt));
               end
            else
               error('BDP:FlagError','No number provided after threads flag %s.', escape_filename(inpt));
            end
            
         elseif strncmp(inpt, '--echo-spacing=', 15)
            if length(inpt) > 15
               k = strfind(inpt, '=');
               spacing = str2double(inpt(k(end)+1:end));
               if ~isnan(spacing)
                  bdp_options.echo_spacing = spacing;
               else
                  error('BDP:FlagError', ['Unable to process echo-spacing flag %s. Check to make sure that ' ...
                     'the value following the equals sign is a number'], escape_filename(inpt));
               end
            else
               error('BDP:FlagError', ['Unable to process echo-spacing flag %s. Check to make sure that ' ...
                  'the value following the equals sign is a number'], escape_filename(inpt));
            end
            
         elseif strncmp(inpt, '--fieldmap-smooth3=', 19)
            if length(inpt) > 19
               k = strfind(inpt, '=');
               s = str2double(inpt(k(end)+1:end));
               if ~isnan(s)
                  bdp_options.fieldmap_smooth3_sigma = s;
               else
                  error('BDP:FlagError', ['Unable to process fieldmap smoothing flag %s. Check to make sure '...
                     'that the value following the equals sign is a numnber'], escape_filename(inpt));
               end
            else
               error('BDP:FlagError', ['Unable to process fieldmap smoothing flag %s. Check to make sure '...
                  'that the value following the equals sign is a numnber'], escape_filename(inpt));
            end
            
         else
            error('BDP:UnknownFlag', [bdp_linewrap(['%s is not a valid flag. ' ...
               'For a complete list of flags with descriptions, run BDP with the flag --help. '...
               'Valid flags are:\n\n']) ...
               ['\t' strjoin_KY(bdp_list_flags(), '\n\t') '\n\n']], escape_filename(inpt));
         end
   end
   
   iflag = iflag + 1;
end

%% Sanity checks of input flags
% Echo spacing is given if using fieldmap distortion correction
if bdp_options.fieldmap_distortion_correction && isempty(bdp_options.echo_spacing)
   error('BDP:FlagError', bdp_linewrap(['Echo spacing must be specified when using fieldmap distortion correction.\n' ...
      'Please use flag --echo-spacing=t to set echo spacing to t seconds.\n']));
end

% --no-intensity-correction can not be combined with Least squares method
if bdp_options.fieldmap_distortion_correction && (bdp_options.fieldmap_leastsq && ~bdp_options.intensity_correct)
   error('BDP:FlagError', bdp_linewrap(['--no-intensity-correction cannot be used with leastsq method while '...
      'using fieldmap based distortion correction. You can either remove the flag --no-intensity-correction or use '...
      'pixelshift method.\n']));
end

% Set tensor calculation as default if no choice made
if ~bdp_options.estimate_odf_FRACT && ~bdp_options.estimate_odf_FRT && ~bdp_options.estimate_tensor && ~bdp_options.estimate_odf_3DSHORE && ~bdp_options.estimate_odf_GQI
   fprintf(bdp_linewrap('Did not detect --FRT/--FRACT/--tensor/--3dshore/--gqi. Using default setting of estimating tensors.\n'));
   bdp_options.estimate_tensor = true;
end


%% check input files
fprintf('\nChecking input files...\n')

% check bfc file
if ~bdp_options.no_structural_registration   
   flg = check_nifti_file(bfc_file);
   if flg==2 % only qform found
      error('BDP:InvalidFile',['The input BFC file does not appear to be a valid file generated by BrainSuite: '...
         '\n%s\n\nYou can try loading the file in BrainSuite and save it again.'], escape_filename(bfc_file));
   end
   temp_file = fullfile(workdir, [Random_String(15) '.nii.gz']);
   [~, R] = reorient_nifti_sform(bfc_file, temp_file);
   if ~isequal(R, eye(3))
      error('BDP:InvalidFile',['The input BFC file does not appear to be a valid file generated by BrainSuite: '...
         '\n%s\n\nYou can try loading the file in BrainSuite and save it again.'], escape_filename(bfc_file));
   end
   bdp_options.bfc_file = bfc_file;
end

if bdp_options.estimate_odf_3DSHORE || bdp_options.estimate_odf_GQI
    % Check if diffusion time was set by the user for 3d-shore and GQI.
    if bdp_options.diffusion_time == 0,
         err_msg = ['BDP can not find diffusion time flag or it is set to 0. Please make sure that you used '...
           '--diffusion_time_ms flag followed by the diffusion time (in milliseconds) of the DWI dataset.'...
           ' 3DSHORE and GQI based ODFs require diffusion time as a mandatory input parameter.'...
           'You can find the command used in BDP summary file (<fileprefix>.BDPSummary.txt).'];
         error('BDP:MandatoryInputNotFound', bdp_linewrap(err_msg));
    end;
end;
 
if ~bdp_options.generate_only_stats && ~bdp_options.only_transform_data
   
   % Generate b-matrices file
   if exist('bmat_file', 'var')
      bMat = readBmat(bmat_file);
      bdp_options.bmat_file = bmat_file;
      
   elseif exist('gradient_file', 'var') && exist('bval', 'var')
      bMat = calculate_bmat(bval, gradient_file);
      [~, name, ~] = fileparts([filebase_name bdp_options.dwi_fname_suffix]);
      outFile = fullfile(workdir, [remove_extension(name) '.bmat']);
      writeBmatFile(bMat, outFile);
      bdp_options.bmat_file = outFile;
      bdp_options.bvec_file = gradient_file;
      
      if ~exist([filebase_name bdp_options.dwi_fname_suffix '.bmat'], 'file')
         copyfile(outFile, [filebase_name bdp_options.dwi_fname_suffix '.bmat']);
      end
      
   else
      error('BDP:MandatoryInputNotFound', bdp_linewrap(['B-matrix file (--bmat BMAT_FILE) or a combination ' ...
         'of gradient file (--bvec '...
         'GRADIENT_FILE) and b-value (--bval B-VALUE) are required when using a NIfTI diffusion input.']));
   end
   
   % check NIfTI input
   [~, outFile] = check_nifti_file(dwi_nii_file, workdir);
   bdp_options.input_filenames.dwi_file = dwi_nii_file;
   bdp_options.dwi_file = outFile;
   
   % Check if number of images matchs the number of diffusion parameters
   [hdr, ~, ~, ~] = load_untouch_header_only_gz(bdp_options.dwi_file);
   nImages = hdr.dime.dim(5);
   nBMat = size(bMat,3);
   if (nImages ~= nBMat)
      error('BDP:InconsistentDiffusionParameters', ['Number of volumes in NIfTI file does not equal the '...
         'number of b-matrices.\n'...
         'Total number of images found: %d\nTotal number of bmatrices: %d \n'], nImages, nBMat);
   end
   
   
   if exist('dwi_mask_file', 'var')
      [~, outFile] = check_nifti_file(dwi_mask_file, workdir);
      bdp_options.input_filenames.dwi_mask_file = dwi_mask_file;
      bdp_options.dwi_mask_file = outFile;
   end
   
   if exist('fieldmap_file', 'var')
      [~, outFile] = check_nifti_file(fieldmap_file, workdir);
      bdp_options.fieldmap_file = outFile;
   end
   
   % Check diffusion encoding
   DE_out = checkDiffusionEncodingScheme(bdp_options.bmat_file, bdp_options.bval_ratio_threshold);
   bdp_options.bMatrixCond = DE_out.bCond;
   bdp_options.num_of_estimated_b0s = sum(DE_out.zero_bval_mask);   
   if (~bdp_options.no_structural_registration) && (bdp_options.num_of_estimated_b0s<=0)
      err_msg = ['BDP could not detect any volume without diffusion weighting (b-value = 0) in the input diffusion data. ', ...
         'b-value = 0 image is required for co-registration and distortion correction. Please make sure that the input '...
         'diffusion parameters files (bvec/bval/bmat) have correct information. In order to use diffusion image with '...
         'low b-value as b=0 image, please use the flag --bval-ratio-threshold to adjust the threshold.'];
      error('BDP:InvalidFile', bdp_linewrap(err_msg))
   end
end

% check/set T1 mask
if ~bdp_options.no_structural_registration
   if exist('t1_mask_file', 'var')
      bdp_options.input_filenames.t1_mask_file = t1_mask_file;
      [~, t1_mask_file] = fixBSheader(bdp_options.bfc_file, t1_mask_file, ...
         fullfile(workdir, [fileBaseName(t1_mask_file) '.nii.gz']));
      bdp_options.t1_mask_file = t1_mask_file;
      
   elseif exist([bfc_filebase '.mask.nii.gz'], 'file')==2
      [~, temp] = fixBSheader(bdp_options.bfc_file, [bfc_filebase '.mask.nii.gz'], ...
         fullfile(workdir, [fileBaseName([bfc_filebase '.mask.nii.gz']) '.nii.gz']));
      bdp_options.t1_mask_file = temp;
      msg = {'\n', ['.mask.nii.gz file found: ' escape_filename([bfc_filebase '.mask.nii.gz'])], '\n', ...
         ['BDP will use this file as brain mask. You can specify a custom brain mask by using flag --t1-mask '...
         '<maskfile_name>. The custom mask must overlay correctly with input BFC image in BrainSuite.'], '\n'};
      fprintf(bdp_linewrap(msg));
      
   else
      bdp_options.t1_mask_file = bfc_file;
      msg = {'\n', ['BDP could not find any .mask.nii.gz file. BDP will use input bfc file itself as brain mask '...
         'for registration and statistics. All voxels with intensity>0 in bfc will be treated as voxels in brain. '...
         'You can specify a custom brain mask by using flag --t1-mask '...
         '<maskfile_name>. The custom mask must overlay correctly with input BFC image in BrainSuite.'], '\n'};
      fprintf(bdp_linewrap(msg));
   end
end

% set diffusion modelling mask
if bdp_options.no_structural_registration
   bdp_options.diffusion_modelling_mask = bdp_options.dwi_mask_file;
else
   [~, nm, ext] = fileparts(bdp_options.t1_mask_file);
   bdp_options.diffusion_modelling_mask = fullfile(fileparts(bdp_options.file_base_name), ...
      suffix_filename([nm ext], bdp_options.Diffusion_coord_suffix));
end

if bdp_options.diffusion_coord_outputs
   if bdp_options.no_structural_registration
      bdp_options.diffusion_coord_outputs = false;
      bdp_options.diffusion_coord_output_folder = fileparts(filebase_name);
   else
      bdp_options.diffusion_coord_output_folder = fullfile(fileparts(bdp_options.file_base_name), 'diffusion_coord_outputs');
      if ~exist(bdp_options.diffusion_coord_output_folder, 'dir')
         mkdir(bdp_options.diffusion_coord_output_folder);
      end
   end
else % write diffusion coord outputs, if any, in usual output location
   bdp_options.diffusion_coord_output_folder = fileparts(filebase_name);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%
%   HELPER FUNCTIONS   %
%%%%%%%%%%%%%%%%%%%%%%%%

function bMatrices = calculate_bmat(bvals, gradients_file)
% bvals can be a text file or a 1x1 number

if ischar(bvals)
   [bvec, bvals] = readBvecBval(gradients_file, bvals);
   ndirs = size(bvec,1);
else
   bvec = readBvecBval(gradients_file);
   ndirs = size(bvec,1);
   [m, n] = size(bvals);
   if (m == 1 && n == 1)
      bvals = bvals * ones(ndirs, 1);
   else
      error('BDP:FlagError', 'Provided b-value must be either a single number or a plain text bval file.');
   end
end

bMatrices = zeros(3,3,ndirs);
for i = 1:ndirs
   n = norm(bvec(i,:));
   if n ~= 0
      norm_vec = bvec(i,:)/n;
   else
      norm_vec = bvec(i,:);
   end
   bMatrices(:,:,i) = bvals(i) * (norm_vec' * norm_vec);
end
end


function [bdp_opts, bfc_file, bfc_filebase, filebase_name] = setupNoStructuralRegistration(args, bdp_opts)
temp = lower(args);

if ismember({'--output-fileprefix'}, temp)
   [~, iflag] = ismember({'--output-fileprefix'}, temp);
   if iflag+1 > length(args)
      error('BDP:FlagError', 'An output fileprefix string must be specified after --output-fileprefix flag.');      
   else
      % clean up fileprefix
      fileprefix_str = deblank(args{iflag+1});
      if fileprefix_str(end)=='/' || fileprefix_str(end)=='\'
         fileprefix_str = fileprefix_str(1:end-1);
      end
      
      if fileprefix_str(1)=='-'
         error('BDP:FlagError', bdp_linewrap(['The output fileprefix string can not start with a dash (-): '...
            escape_filename(fileprefix_str)]));
      end
      
      % check for nested folder structure
      [pthstr, ~, ~] = fileparts(fileprefix_str);
      if ~isempty(pthstr)
         error('BDP:FlagError', bdp_linewrap(['The output fileprefix must be just a plain string without '...
            'slashes or backslashes: ' escape_filename(fileprefix_str)]));
      end
   end
end

[~,iflag] = ismember({'--nii'}, temp);
if iflag+1 > length(args)
   error('BDP:FlagError', 'NIfTI flag specified but no NIfTI file is provided after --nii flag.');
else
   dwi_nii_file = args{iflag+1};
   bdp_opts.dwi_fname_suffix = '';
end

if exist(dwi_nii_file, 'file')~=2
   error('BDP:FileDoesNotExist','The input diffusion NIfTI file does not exist: %s', escape_filename(dwi_nii_file));
end


% update dwi_nii_file when --output-fileprefix exists
if ismember({'--output-fileprefix'}, temp)
   [pthstr, nm, e] = fileparts(dwi_nii_file);
   [~, ext] = remove_extension([nm, e]);
   dwi_nii_file = fullfile(pthstr, [fileprefix_str ext]);
end

bfc_file = dwi_nii_file;
bfc_filebase = remove_extension(dwi_nii_file);
bdp_opts.bfc_file_base = bfc_filebase;
bdp_opts.file_base_name = bfc_filebase;
filebase_name = bfc_filebase;

bdp_opts.no_structural_registration = true;
bdp_opts.diffusion_coord_outputs = false;
bdp_opts.fieldmap_distortion_correction = false;
bdp_opts.registration_distortion_correction = false;

% Throw error when any of the extra flags does not make sense
not_allowed = {'--t1-mask', '--transform-diffusion-volume', '--transform-t1-volume', '--transform-t1-surface', ...
   '--transform-diffusion-surface', '--transform-data-only', '--only-transform-data', ...
   '--transform-interpolation', '--generate-stats', ...
   '--generate-only-stats', '--generate-stats-only', '--only-generate-stats', '--force-partial-roi-stats', ...
   '--custom-diffusion-label', '--custom-t1-label', '--custom-label-xml'};
if any(ismember(not_allowed, temp))
   error('BDP:FlagError', [bdp_linewrap(['--no-structural-registration can not be combined with following flags:\n\n']) ...
      ['\t' strjoin_KY(not_allowed, '\n\t') '\n\n']]);
end

end

