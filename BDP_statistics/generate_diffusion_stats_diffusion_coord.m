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


function generate_diffusion_stats_diffusion_coord(dwi_file, options)
% Writes out statistics files for diffusion data using label/mask file. This function computes
% statistics in diffusion coordinates, and assumes that all the diffusion parameter files are
% generated/transfered to diffusion coordinates.
%
% options is the bdp_options structure - see setup_bdp.m
%

bdpPrintSectionHeader('Computing statistics - Diffusion coordinate');

workdir = tempname();
mkdir(workdir);
temp_nii_file = fullfile(workdir , [randstr(15) '.nii.gz']);

fprintf('Using diffusion data: %s', dwi_file);
fprintf('\nBDP is checking for required files...')

% set up file names
file_base = options.file_base_name;
file_suffix = '';

dwi_file_base = fullfile(options.diffusion_coord_output_folder, fileBaseName(dwi_file));
ADC_file = [dwi_file_base '.mADC' file_suffix '.nii.gz'];
FA_file = [dwi_file_base '.FA' file_suffix '.nii.gz'];
MD_file = [dwi_file_base '.MD' file_suffix '.nii.gz'];
axial_file = [dwi_file_base '.axial' file_suffix '.nii.gz'];
radial_file = [dwi_file_base '.radial' file_suffix '.nii.gz'];
L2_file = [dwi_file_base '.L2' file_suffix '.nii.gz'];
L3_file = [dwi_file_base '.L3' file_suffix '.nii.gz'];
GFA_file = [dwi_file_base '.FRT_GFA' file_suffix '.nii.gz'];

% check for diffusion files
if ~exist(ADC_file, 'file') && ~exist(FA_file, 'file') && ~exist(MD_file, 'file') && ~exist(axial_file, 'file') && ...
      ~exist(radial_file, 'file') && ~exist(L2_file, 'file') && ~exist(L3_file, 'file') && ~exist(GFA_file, 'file')  
   err_msg = ['BDP cannot find any diffusion parameter (in diffusion coordinates) files for the fileprefix: '...
      escape_filename(options.bfc_file_base) ...
      '\nPlease make sure you have run BDP previously with the flag --output-diffusion-coordinate '...
      'AND without the flag --generate-only-stats.'];
   error('BDP:ExpectedFileNotFound', bdp_linewrap(err_msg));
end

if ~exist(ADC_file, 'file'), fprintf('\nNo stats will be generated for mADC. File not found: %s', ADC_file); end
if ~exist(FA_file, 'file'), fprintf('\nNo stats will be generated for FA. File not found: %s', FA_file); end
if ~exist(MD_file, 'file'), fprintf('\nNo stats will be generated for MD. File not found: %s', MD_file); end
if ~exist(axial_file, 'file'), fprintf('\nNo stats will be generated for axial. File not found: %s', axial_file); end
if ~exist(radial_file, 'file'), fprintf('\nNo stats will be generated for radial. File not found: %s', radial_file); end
if ~exist(L2_file, 'file'), fprintf('\nNo stats will be generated for L2. File not found: %s', L2_file); end
if ~exist(L3_file, 'file'), fprintf('\nNo stats will be generated for L3. File not found: %s', L3_file); end
if ~exist(GFA_file, 'file'), fprintf('\nNo stats will be generated for GFA. File not found: %s', GFA_file); end
fprintf('\n');

% check for brainsuite masks
dewisp_mask_file = [options.bfc_file_base '.cortex.dewisp.mask.nii.gz'];
if exist(dewisp_mask_file, 'file')~=2
   error('BDP:ExpectedFileNotFound', ['BDP cannot find brainsuite cortex dewisp mask: %s'...
      '\nPlease make sure you have run BrainSuite on this directory.'], dewisp_mask_file);
end

% check for svreg labels
if exist([options.bfc_file_base '.svreg.label.nii.gz'], 'file')==2
   svreg_label_file = [options.bfc_file_base '.svreg.label.nii.gz'];
   workdir_label = fullfile(workdir, [fileBaseName(svreg_label_file) '.nii.gz']);
   svreg_label_file = mergeNewSVRegLabels(svreg_label_file, workdir_label);
   
elseif isempty(options.custom_T1_label) && isempty(options.custom_diffusion_label)
   err_msg = ['BDP cannot find any BrainSuite label file or any custom label files. '...
      'Label files are required in order to generate ROI-wise statistics. Please make '...
      'sure you have specified custom masks AND/OR have run BrainSuite extraction with '...
      'volumetric registration for fileprefix: ' escape_filename(options.bfc_file_base)];
   error('BDP:ExpectedFileNotFound', bdp_linewrap(err_msg));
   
else
   msg = ['BDP cannot find any BrainSuite label files (only custom label files are found). If you want ROI-wise statistics ' ...
      'for BrainSuite ROIs then please make sure you have run BrainSuite extraction with volumetric '...
      'registration for file-prefix: ' escape_filename(options.bfc_file_base)];
   bdpPrintWarning('Missing BrainSuite label-file', msg);   
end


% transfer labels/masks to diffusion coordinates
[~, nm, ext] = fileparts(options.t1_mask_file);
d_coord_file = fullfile(fileparts(file_base), suffix_filename([nm ext], options.Diffusion_coord_suffix));
affinematrix_file = [file_base '.bfc' options.Diffusion_coord_suffix '.rigid_registration_result.mat'];
bfc_nii = load_untouch_nii_gz(options.bfc_file);

if exist(d_coord_file, 'file')==2
   [~, nm, ext] = fileparts(dewisp_mask_file);
   output_fname = fullfile(options.diffusion_coord_output_folder, ...
      suffix_filename([nm ext], options.Diffusion_coord_suffix));
   
   dewisp_mask_file = transfer_T1_to_diffusion(dewisp_mask_file, bfc_nii, d_coord_file, affinematrix_file, ...
      output_fname, 'nearest');
else
   error('BDP:ExpectedFileNotFound', ['BDP cannot find file: %s \nPlease run BDP again without flag '...
      '--generate-only-stats'], escape_filename(d_coord_file))
end

% initial csv file
write_stat_file_initial(dwi_file_base, file_suffix);


% generate svreg roi stats
ignored_labels = [];
if exist('svreg_label_file', 'var')
   [~, nm, ext] = fileparts(svreg_label_file);
   output_fname = fullfile(options.diffusion_coord_output_folder, ...
      suffix_filename([nm ext], options.Diffusion_coord_suffix));
   
   label_file = transfer_T1_to_diffusion(svreg_label_file, bfc_nii, d_coord_file, affinematrix_file, ...
                                                       output_fname, 'nearest');
   
   temp = gen_stat_for_label_file_Dcoord(dwi_file_base, file_suffix, label_file, svreg_label_file, dewisp_mask_file,...
      dwi_file_base, d_coord_file, options);
   ignored_labels = [ignored_labels; temp(:)];
end


% custom T1 label file/folder
if ~isempty(options.custom_T1_label)
   if exist(options.custom_T1_label, 'dir')==7
      f_lst = dir(options.custom_T1_label);
      for k = 1:length(f_lst)
         if ~f_lst(k).isdir
            fname_T1 = fullfile(options.custom_T1_label, f_lst(k).name);
            label_file = fullfile(options.diffusion_coord_output_folder, ...
                                  suffix_filename(f_lst(k).name, options.Diffusion_coord_suffix));
                               
            temp = gen_stat_for_label_file_Dcoord(dwi_file_base, file_suffix, label_file, fname_T1, dewisp_mask_file, ...
               dwi_file_base, d_coord_file, options);
            ignored_labels = [ignored_labels; temp(:)];
         end
      end
      
   elseif exist(options.custom_T1_label, 'file')==2
      [~, nm, ext] = fileparts(options.custom_T1_label);
      label_file = fullfile(options.diffusion_coord_output_folder, ...         
                       suffix_filename([nm ext], options.Diffusion_coord_suffix)); 
                    
      temp = gen_stat_for_label_file_Dcoord(dwi_file_base, file_suffix, label_file, options.custom_T1_label, dewisp_mask_file, ...
         dwi_file_base, d_coord_file, options);
      ignored_labels = [ignored_labels; temp(:)];
   else
      error('BDP:FileDoesNotExist', 'Could not find custom stat file/folder: %s', escape_filename(options.custom_T1_label));
   end
end


% custom diffusion label file/folder
if ~isempty(options.custom_diffusion_label)
   if exist(options.custom_diffusion_label, 'dir')==7
      f_lst = dir(options.custom_diffusion_label);
      for k = 1:length(f_lst)
         if ~f_lst(k).isdir
            fname = fullfile(options.custom_diffusion_label, f_lst(k).name);            
            temp = gen_stat_for_label_file_Dcoord(dwi_file_base, file_suffix, fname, fname, dewisp_mask_file, ...
               dwi_file_base, d_coord_file, options);
            ignored_labels = [ignored_labels; temp(:)];
         end
      end
      
   elseif exist(options.custom_diffusion_label, 'file')==2      
      temp = gen_stat_for_label_file_Dcoord(dwi_file_base, file_suffix, options.custom_diffusion_label, options.custom_diffusion_label, ...
         dewisp_mask_file, dwi_file_base, d_coord_file, options);
      ignored_labels = [ignored_labels; temp(:)];
         
   else
      error('BDP:FileDoesNotExist', 'Could not find custom stat file/folder: %s', escape_filename(options.custom_diffusion_label));
   end
end


% remove useless cvs files
if ~exist(ADC_file, 'file'), delete([dwi_file_base '.mADC' file_suffix '.stat.csv']); end
if ~exist(FA_file, 'file'),  delete([dwi_file_base '.FA' file_suffix '.stat.csv']); end
if ~exist(MD_file, 'file'),  delete([dwi_file_base '.MD' file_suffix '.stat.csv']); end
if ~exist(axial_file, 'file'),  delete([dwi_file_base '.axial' file_suffix '.stat.csv']); end
if ~exist(radial_file, 'file'),  delete([dwi_file_base '.radial' file_suffix '.stat.csv']); end
if ~exist(L2_file, 'file'),  delete([dwi_file_base '.L2' file_suffix '.stat.csv']); end
if ~exist(L3_file, 'file'),  delete([dwi_file_base '.L3' file_suffix '.stat.csv']); end
if ~exist(GFA_file, 'file'), delete([dwi_file_base '.FRT_GFA' file_suffix '.stat.csv']); end

% remove multiple lines with zero voxels and list the stats in the 'desired 'order
cleanup_stat_file(dwi_file_base, file_suffix, options, ignored_labels);

rmdir(workdir, 's');
msg = {'\n\n', ['BDP is finished generating all statistics in diffusion coordinates. '...
    'CSV (comma-separated values) '...
    'file are written with fileprefix: ' escape_filename(dwi_file_base)], '\n'};
fprintf(bdp_linewrap(msg));   
   
end



function roi_ignore = gen_stat_for_label_file_Dcoord(file_base, file_suffix, label_file, orig_label_file, dewisp_mask_file, ...
                                        stats_file_base, d_coord_file, options)
% Generate stats for particular file. It also checks/adds for sform matrix & reorient it to RAS
% before computation.

fprintf('\n________________________________________________');
fprintf('\n\nProcessing label-file: %s', label_file);

workdir = tempname();
mkdir(workdir);
temp_nii_file = fullfile(workdir, [randstr(15) '.nii.gz']);

[labels, roi_id] = get_orig_labels_roi_id(orig_label_file, options);
voxels_missing_fraction = zeros(size(labels));

% get labels in BFC/mprage coordinates
[~, outFile] = check_nifti_file(label_file, workdir);
label_data = reorient_nifti_sform(outFile, temp_nii_file);  

dwi_coord_img = load_untouch_nii_gz(dewisp_mask_file);
if ~isequal(size(label_data.img), size(dwi_coord_img.img))
   error('BDP:InvalidLabelFile', ['The image size of label must match diffusion image. Make sure the '...
      'label file is in diffusion coordinates and overlay on diffusion data correctly in BrainSuite GUI: %s'], ...
      escape_filename(label_file));
end

% Mask image outside the brain 
d_coord_mask = load_untouch_nii_gz(d_coord_file);
d_coord_mask = d_coord_mask.img>0;

temp = label_data.img(~d_coord_mask & label_data.img~=0);
label_data_masked = label_data;

if ~isempty(temp)
   msg = {'\n\n', [num2str(numel(temp)) ' voxels were found outside the head mask. These voxels will not be used for '...
      'statistics computation. These rejected voxels may include voxels which BDP found to be unreliable for any diffusion '...
      'parameter estimation. A label wise break-up of reject voxel is given below:\n']};
   fprintf(bdp_linewrap(msg));
   
   temp_unq = unique(temp);
   for u_ind = 1:length(temp_unq)
      s = sum(temp == temp_unq(u_ind));
      fprintf('\t%d voxels rejected for label id: %d \n', s, temp_unq(u_ind));
   end
   label_data_masked.img(~d_coord_mask) = 0;
end

% Get FOV overlay ROIs from T1 coordinate stat files
listing = dir([options.file_base_name '.*.csv']);
if ~isempty(listing)
   [ROI_csv, missing_fraction] = get_all_ROIs(fullfile(fileparts(options.file_base_name), listing(1).name));
else
   error('T1 coordinate stats not generated!')
end

roi_ignore = setdiff(roi_id, ROI_csv, 'stable'); % ROIs excluded by xml, if any
if isempty(roi_ignore) % ROIs with missing voxels
   roi_ignore_full = ROI_csv(missing_fraction~=0);
   msk_ignore = ismember(roi_id, roi_ignore_full, 'R2012a');
   roi_ignore = roi_id(msk_ignore);
end

if ~isempty(roi_ignore)
   if options.force_partial_roi_stats      
      msk_csv = ismember(ROI_csv, roi_ignore, 'R2012a');
      missing_fraction_ignore = missing_fraction(msk_csv);
      
      [msk, locb] = ismember(roi_id, roi_ignore, 'R2012a');
      voxels_missing_fraction(msk) = missing_fraction_ignore(locb(msk));
      msg = {'\n\n', ['Following ROIs were not completely included in diffusion scan field of view '...
         '(Missing percentage is same as T1-coordinate statistics). But '...
         '--force-partial-roi-stats flag was detected. So, BDP will generate statistics for these ROIs as well. '...
         'Please be careful with the analysis of the partially acquired ROIs.\n']};
      fprintf(bdp_linewrap(msg));
      fprintf('ROI id %d \n', roi_id(msk));
      roi_ignore = [];
      
   else    
      msk = ismember(roi_id, roi_ignore, 'R2012a');
      fprintf(bdp_linewrap({'\n', ['Following ROIs were not completely included in diffusion scan field of view '...
         '(Missing percentage is same as T1-coordinate statistics). '...
         'BDP will NOT generate statistics for these ROIs. '...
         'If you want to force generation of statistics for all ROIs irrespective of overlap of '...
         'field of view in diffusion and MPRAGE scan then please run BDP again, adding the flags ' ...
         '--generate-only-stats --force-partial-roi-stats\n']}));
      fprintf('ROI id %d \n', roi_id(msk));
      
      % throw away ignored labels from list of labels for which stats would be computed
      labels(msk) = [];
      roi_id(msk) = [];
      voxels_missing_fraction(msk) = [];      
   end   
end

append_diffusion_stats_csv(file_base, file_suffix, labels, roi_id, voxels_missing_fraction, label_data_masked,...
                           dewisp_mask_file, stats_file_base, orig_label_file)
rmdir(workdir, 's');
end


function [ROIs, missing_fraction] = get_all_ROIs(csv_file)
[hdr, M, col1, col_end] = csvreadBDP(csv_file);

if ~isempty(col1)
   error('First column should be numeric ids: %s', escape_filename(csv_file));
end

ROIs = M(:,1);
missing_fraction = M(:,2)./M(:,5);
missing_fraction(isnan(missing_fraction)) = 0;
end
