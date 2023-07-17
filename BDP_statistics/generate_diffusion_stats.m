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


function generate_diffusion_stats(dwi_file, options)
% Writes out statistics files for diffusion data using label/mask file.
% This function computes statistics in T1 coordinates, and assumes that all the diffusion
% parameter files are generated/transfered in T1 coordinates.
%
% options is the bdp_options structure - see bdp_setup.m
%

bdpPrintSectionHeader('Computing statistics - T1 coordinate');

workdir = tempname();
mkdir(workdir);
temp_nii_file = fullfile(workdir , [randstr(15) '.nii.gz']);

fprintf('Using diffusion data: %s', dwi_file);
fprintf('\nBDP is checking for required files...')

% set up file names
file_base = options.file_base_name;
file_suffix = options.mprage_coord_suffix;

% dwi_file_base = remove_extension(dwi_file);
dwi_file_base = fullfile(fileparts(options.file_base_name), fileBaseName(dwi_file));

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
   error('BDP:ExpectedFileNotFound', ['BDP cannot find any diffusion parameter files for the fileprefix: %s \n'...
      'Please make sure you have run BDP on this directory. If you are using --only-generate-stats all '...
      'the other flags must be exactly same as that of in the BDP run which processed the '...
      'diffusion files.'], escape_filename(options.bfc_file_base));
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
   error('BDP:ExpectedFileNotFound', ['BDP cannot find brainsuite cortex dewisp mask: %s\n'...
      'Please make sure you have run BrainSuite on this directory.'], escape_filename(dewisp_mask_file));
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


% get mask for FOV of diffusion data
diffusion_coord_file = [file_base '.bfc' options.Diffusion_coord_suffix '.nii.gz'];
affinematrix_file = [file_base '.bfc' options.Diffusion_coord_suffix '.rigid_registration_result.mat'];
bfc_filename = options.bfc_file;

if exist(diffusion_coord_file, 'file')==2
   % make FOV mask
   d_coord_nii = load_untouch_nii_gz(diffusion_coord_file);
   d_coord_nii.img = 255*ones(size(d_coord_nii.img));
   save_untouch_nii_gz(d_coord_nii, temp_nii_file, 2);
   
   % tranform mask
   load(affinematrix_file);
   affine_transform_nii(temp_nii_file, M_world, origin, temp_nii_file); % just apply the rigid transform to header
   dwi_FOV_mask = interp3_nii(temp_nii_file, bfc_filename, temp_nii_file, 'nearest');   
   
else
   error('BDP:ExpectedFileNotFound', ['BDP cannot find file: %s \nPlease run BDP again without flag '...
      '--generate-only-stats'], escape_filename(diffusion_coord_file))
end


% Generate ROI ids, if required
if isempty(options.custom_label_description_xml)
   global BDP_custom_roi_id_count BDP_xml_struct
   BDP_custom_roi_id_count = 10000;
   BDP_xml_struct = [];
   BDP_xml_struct.BDP_ROI_MAP.file = {};
   
   % custom T1 label file/folder
   if ~isempty(options.custom_T1_label)
      if exist(options.custom_T1_label, 'dir')==7
         f_lst = dir(options.custom_T1_label);
         for k = 1:length(f_lst)
            if ~f_lst(k).isdir               
               set_labels_roi_id(fullfile(options.custom_T1_label, f_lst(k).name), options);
            end
         end
         
      elseif exist(options.custom_T1_label, 'file')==2
         set_labels_roi_id(options.custom_T1_label, options);
         
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
               set_labels_roi_id(fullfile(options.custom_diffusion_label, f_lst(k).name), options);
            end
         end
         
      elseif exist(options.custom_diffusion_label, 'file')==2
         set_labels_roi_id(options.custom_diffusion_label, options);
         
      else
         error('BDP:FileDoesNotExist', 'Could not find custom stat file/folder: %s', escape_filename(options.custom_T1_label));
      end
   end
   
   % Write BDP_ROI_map.xml
   if ~isempty(BDP_xml_struct.BDP_ROI_MAP.file)
      BDP_xml_struct.BDP_ROI_MAP.info{1}.Attributes.stat_filebase_name = dwi_file_base;
      BDP_xml_struct.BDP_ROI_MAP.info{1}.Attributes.xml_description = ['This xml file describes the mapping between ROI-id '...
         'used in BDP-generated statistics file(s) and the voxel intensities found in the custom mask/label files. Each '...
         '''file'' tag in this xml file describes mapping for one custom mask/label file with the file-name and directory '...
         'saved in ''name'' and ''path'' attributes respectively. ''map'' tag stores the the mapping between ROI id (saved '...
         'in attribute ''roi_id'') and voxel intensity (saved in attribute ''value'').'];
      BDP_xml_struct.BDP_ROI_MAP = orderfields(BDP_xml_struct.BDP_ROI_MAP, [2 1]);
      struct2xml(BDP_xml_struct, [file_base '.BDP_ROI_MAP.xml']);
      
      msg = {'\n\n', ...
         ['BDP found some custom label/mask files which will be used for statistics computation. But no custom xml (label '...
         'description) file was found. Hence, BDP has generated unique 5-digit ROI IDs for the each label/mask found. '...
         'These unique 5-digit ROI IDs will be used in all .cvs files to report statistics. '...
         'The mapping between generated ROI IDs and voxel intensity for each custom label/mask file is saved in xml '...
         'format. Please use this xml file to interprete statistics: \n'],...
         escape_filename([file_base '.BDP_ROI_MAP.xml']), ...
         '\n\n'};
      fprintf(bdp_linewrap(msg));
      
   elseif ~isempty(options.custom_label_description_xml)
      msg = {'\n\n', ...
         ['BDP found custom xml (label description) file. BDP will only generate statistics for ROI ids mentioned in ',...
         'the xml file and will ignore any other labels/masks, if present (including in any custom label/mask file). '...
         'Custom xml file used: \n'],...
         escape_filename(options.custom_label_description_xml), ...
         '\n\n'};
      fprintf(bdp_linewrap(msg));
   end
end


% write initial file 
write_stat_file_initial(dwi_file_base, file_suffix);


% generate svreg roi stats
ignored_labels = [];
if exist('svreg_label_file', 'var')
   temp = gen_stat_for_label_file(dwi_file_base, file_suffix, svreg_label_file, svreg_label_file, dewisp_mask_file, ....
      dwi_FOV_mask, dwi_file_base, options);
   ignored_labels = [ignored_labels; temp(:)];
end

% custom T1 label file/folder
if ~isempty(options.custom_T1_label)
   if exist(options.custom_T1_label, 'dir')==7
      f_lst = dir(options.custom_T1_label);
      for k = 1:length(f_lst)
         if ~f_lst(k).isdir
            fname = fullfile(options.custom_T1_label, f_lst(k).name);
            temp = gen_stat_for_label_file(dwi_file_base, file_suffix, fname, fname, dewisp_mask_file, ...
               dwi_FOV_mask, dwi_file_base, options);
            ignored_labels = [ignored_labels; temp(:)];
         end
      end
      
   elseif exist(options.custom_T1_label, 'file')==2
      temp = gen_stat_for_label_file(dwi_file_base, file_suffix, options.custom_T1_label, options.custom_T1_label, ...
         dewisp_mask_file, dwi_FOV_mask, dwi_file_base, options);
      ignored_labels = [ignored_labels; temp(:)];
   end
end

% custom diffusion label file/folder
if ~isempty(options.custom_diffusion_label)
   if exist(options.custom_diffusion_label, 'dir')==7
      f_lst = dir(options.custom_diffusion_label);
      for k = 1:length(f_lst)
         if ~f_lst(k).isdir
            fname_d_coord = fullfile(options.custom_diffusion_label, f_lst(k).name);
            label_file = fullfile(fileparts(options.file_base_name), suffix_filename(f_lst(k).name, options.mprage_coord_suffix));
            temp = gen_stat_for_label_file(dwi_file_base, file_suffix, label_file, fname_d_coord, dewisp_mask_file, dwi_FOV_mask,...
               dwi_file_base, options);
            ignored_labels = [ignored_labels; temp(:)];
         end
      end
      
   elseif exist(options.custom_diffusion_label, 'file')==2
      fname_d_coord = options.custom_diffusion_label;
      [~, nm, ext] = fileparts(fname_d_coord);
      label_file = fullfile(fileparts(options.file_base_name), suffix_filename([nm ext], options.mprage_coord_suffix));             
      temp = gen_stat_for_label_file(dwi_file_base, file_suffix, label_file, fname_d_coord, dewisp_mask_file, dwi_FOV_mask, ...
         dwi_file_base, options);
      ignored_labels = [ignored_labels; temp(:)];
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
msg = {'\n\n', ['BDP is finished generating all statistics. CSV (comma-separated values) '...
    'file are written with fileprefix: ' escape_filename(dwi_file_base)], '\n'};
fprintf(bdp_linewrap(msg));

end



function label_ignore = gen_stat_for_label_file(file_base, file_suffix, label_file, orig_label_file, dewisp_mask_file, ...
                                       dwi_FOV_mask, stats_file_base, options)
% Generate stats for particular file. It also checks/adds for sform matrix & reorient it to bfc's
% coordinates before computation

fprintf('\n________________________________________________');
fprintf('\n\nProcessing label-file: %s', label_file);

workdir = tempname();
mkdir(workdir);
temp_nii_file = fullfile(workdir, [randstr(15) '.nii.gz']);

[labels, roi_id] = get_orig_labels_roi_id(orig_label_file, options);

% get labels in BFC/T1 coordinates
label_data = fixBSheader(options.bfc_file, label_file, temp_nii_file);

if ~isequal(size(label_data.img), size(dwi_FOV_mask.img))
   error('BDP:InvalidLabelFile', ['The image size of label must match .bfc image. Make sure the '...
      'label file is in bfc coordinates and overlay on bfc image correctly in BrainSuite GUI: %s'], label_file);
end

% Check diffusion FOV overlay with ROIs
label_data_masked = label_data;
label_data_masked.img(dwi_FOV_mask.img<=0) = 0;
voxels_missing_fraction = zeros(size(labels));
label_ignore = [];

for k=1:length(labels)
   nvox_orig = sum(label_data.img(:)==labels(k));
   nvox = sum(label_data_masked.img(:)==labels(k));
   voxels_missing_fraction(k) = (nvox_orig - nvox)/nvox;
   
   if nvox < nvox_orig
      fprintf('\n ROI id %d is missing %3.1f%% (%d/%d) of voxels in field of view of diffusion scan',...
         roi_id(k), 100*(1-single(nvox)/single(nvox_orig)), (nvox_orig-nvox), nvox_orig);
      label_ignore = [label_ignore, labels(k)];
      
   elseif nvox > nvox_orig      
      fprintf('\n ROI id %d has %3.1f%% more voxels in field of view of diffusion scan',...
         roi_id(k), 100*(single(nvox)/single(nvox_orig)-1));            
      label_ignore = [label_ignore, labels(k)];            
   end
end
voxels_missing_fraction(isnan(voxels_missing_fraction)) = 0;

if options.force_partial_roi_stats && ~isempty(label_ignore)
   msg = {'\n\n', ['Above ROIs were not completely included in diffusion scan field of view. But '...
      '--force-partial-roi-stats flag was detected. So, BDP will generate statistics for these ROIs as well. '...
      'Please be careful with the analysis of the partially acquired ROIs.\n']};   
   fprintf(bdp_linewrap(msg));
   label_ignore = [];
   
elseif ~options.force_partial_roi_stats && ~isempty(label_ignore)
   % throw away ignored labels from list of labels for which stats would be computed
   for k=1:length(label_ignore)
      msk = (labels==label_ignore(k));
      labels(msk) = [];
      roi_id(msk) = [];
      voxels_missing_fraction(msk) = [];
   end
   
   fprintf(bdp_linewrap({'\n\n', ['Above ROIs were not completely included in diffusion scan field of view. '...
      'BDP will NOT generate statistics for these ROIs. '...
      'If you want to force generation of statistics for all ROIs irrespective of overlap of '...
      'field of view in diffusion and MPRAGE scan then please run BDP again after adding flags ' ...
      '--generate-only-stats --force-partial-roi-stats\n']}));
end

% Mask image outside the brain 
t1_mask = load_untouch_nii_gz(options.t1_mask_file);
t1_mask = t1_mask.img>0;

temp = label_data_masked.img(~t1_mask & label_data_masked.img~=0);
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
   label_data_masked.img(~t1_mask) = 0;
end

append_diffusion_stats_csv(file_base, file_suffix, labels, roi_id, voxels_missing_fraction, label_data_masked,...
                           dewisp_mask_file, stats_file_base, orig_label_file)
rmdir(workdir, 's');
end


