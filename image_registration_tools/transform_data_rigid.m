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


function transform_data_rigid(bdp_options)
% Transforms label/volume/mask/sufaces to-fro from diffusion and T1
% coordinate using input parameters. 
%
% This is NOT general function. See transform_data_affine.m for general
% implementation. This function mainly provides better messages and error
% messages and has much lower file i/o. 


if ~isempty(bdp_options.custom_diffusion_label) || ~isempty(bdp_options.custom_T1_label) ...
      || ~isempty(bdp_options.custom_T1_volume) || ~isempty(bdp_options.custom_diffusion_volume) ...
      || ~isempty(bdp_options.custom_T1_surface) || ~isempty(bdp_options.custom_diffusion_surface)
      
   bdpPrintSectionHeader('Transforming data between T1 & diffusion coordinates');

   ref_diffusion = [bdp_options.file_base_name '.bfc' bdp_options.Diffusion_coord_suffix '.nii.gz'];
   affinematrix_file = [bdp_options.file_base_name '.bfc' bdp_options.Diffusion_coord_suffix '.rigid_registration_result.mat'];
   
   if exist(ref_diffusion, 'file')~=2 
      error('BDP:ExpectedFileNotFound', ['BDP cannot find file: %s \nPlease run BDP again without flags '...
         '--generate-only-stats and --only-transform-data'], ref_diffusion)
      
   elseif exist(affinematrix_file, 'file')~=2
      error('BDP:ExpectedFileNotFound', ['BDP cannot find file: %s \nPlease run BDP again without flag '...
      '--generate-only-stats and --only-transform-data'], affinematrix_file)
   end
   
   ref_bfc = load_untouch_nii_gz(bdp_options.bfc_file);
   ref_diffusion = load_untouch_nii_gz(ref_diffusion);
   
   % Labels - in diffusion coordinate
   if ~isempty(bdp_options.custom_diffusion_label)
      if exist(bdp_options.custom_diffusion_label, 'dir')==7
         f_lst = dir(bdp_options.custom_diffusion_label);
         for k = 1:length(f_lst)
            if ~f_lst(k).isdir
               input_fname = fullfile(bdp_options.custom_diffusion_label, f_lst(k).name);
               output_fname = fullfile(fileparts(bdp_options.file_base_name), ...
                  suffix_filename(f_lst(k).name, bdp_options.mprage_coord_suffix));
               transfer_diffusion_to_T1(input_fname, ref_diffusion, ref_bfc, affinematrix_file, ...
                                                       output_fname, 'nearest');
            end
         end
         
      elseif exist(bdp_options.custom_diffusion_label, 'file')==2
         [~, nm, ext] = fileparts(bdp_options.custom_diffusion_label);
         output_fname = fullfile(fileparts(bdp_options.file_base_name), suffix_filename([nm ext], bdp_options.mprage_coord_suffix));
         transfer_diffusion_to_T1(bdp_options.custom_diffusion_label, ref_diffusion, ref_bfc, affinematrix_file, ...
            output_fname, 'nearest');
         
      else
         error('BDP:FileDoesNotExist', 'Could not find custom diffusion label file/folder: %s', bdp_options.custom_diffusion_label);
      end
   end
   
   % Labels - in T1 coordinate
   if ~isempty(bdp_options.custom_T1_label)
      if exist(bdp_options.custom_T1_label, 'dir')==7
         f_lst = dir(bdp_options.custom_T1_label);
         for k = 1:length(f_lst)
            if ~f_lst(k).isdir
               input_fname = fullfile(bdp_options.custom_T1_label, f_lst(k).name);
               output_fname = fullfile(bdp_options.diffusion_coord_output_folder, ...
                  suffix_filename(f_lst(k).name, bdp_options.Diffusion_coord_suffix));
               transfer_T1_to_diffusion(input_fname, ref_bfc, ref_diffusion, affinematrix_file, ...
                  output_fname, 'nearest');
            end
         end
         
      elseif exist(bdp_options.custom_T1_label, 'file')==2
         [~, nm, ext] = fileparts(bdp_options.custom_T1_label);
         output_fname = fullfile(bdp_options.diffusion_coord_output_folder, ...
            suffix_filename([nm ext], bdp_options.Diffusion_coord_suffix));
         transfer_T1_to_diffusion(bdp_options.custom_T1_label, ref_bfc, ref_diffusion, affinematrix_file, ...
            output_fname, 'nearest');
      else
         error('BDP:FileDoesNotExist', 'Could not find custom T1 label file/folder: %s', bdp_options.custom_T1_label);     
      end
   end
   
   % Volumes - in T1 coordinate
   if ~isempty(bdp_options.custom_T1_volume)
      if exist(bdp_options.custom_T1_volume, 'dir')==7
         f_lst = dir(bdp_options.custom_T1_volume);
         for k = 1:length(f_lst)
            if ~f_lst(k).isdir
               input_fname = fullfile(bdp_options.custom_T1_volume, f_lst(k).name);
               output_fname = fullfile(bdp_options.diffusion_coord_output_folder, ...
                  suffix_filename(f_lst(k).name, bdp_options.Diffusion_coord_suffix));
               transfer_T1_to_diffusion(input_fname, ref_bfc, ref_diffusion, affinematrix_file, ...
                  output_fname, bdp_options.interp_method);
            end
         end
         
      elseif exist(bdp_options.custom_T1_volume, 'file')==2
         [~, nm, ext] = fileparts(bdp_options.custom_T1_volume);
         output_fname = fullfile(bdp_options.diffusion_coord_output_folder, ...
            suffix_filename([nm ext], bdp_options.Diffusion_coord_suffix));
         transfer_T1_to_diffusion(bdp_options.custom_T1_volume, ref_bfc, ref_diffusion, affinematrix_file, ...
            output_fname, bdp_options.interp_method);
      else
         error('BDP:FileDoesNotExist', 'Could not find custom T1 volume file/folder: %s', bdp_options.custom_T1_volume);
      end
   end
   
   % Volumes - in diffusion coordinate
   if ~isempty(bdp_options.custom_diffusion_volume)
      if exist(bdp_options.custom_diffusion_volume, 'dir')==7
         f_lst = dir(bdp_options.custom_diffusion_volume);
         for k = 1:length(f_lst)
            if ~f_lst(k).isdir
               input_fname = fullfile(bdp_options.custom_diffusion_volume, f_lst(k).name);
               output_fname = fullfile(fileparts(bdp_options.file_base_name), ...
                  suffix_filename(f_lst(k).name, bdp_options.mprage_coord_suffix));
               transfer_diffusion_to_T1(input_fname, ref_diffusion, ref_bfc, affinematrix_file, ...
                  output_fname, bdp_options.interp_method);
            end
         end
         
      elseif exist(bdp_options.custom_diffusion_volume, 'file')==2
         [~, nm, ext] = fileparts(bdp_options.custom_diffusion_volume);
         output_fname = fullfile(fileparts(bdp_options.file_base_name), suffix_filename([nm ext], bdp_options.mprage_coord_suffix));
         transfer_diffusion_to_T1(bdp_options.custom_diffusion_volume, ref_diffusion, ref_bfc, affinematrix_file, ...
            output_fname, bdp_options.interp_method);
         
      else
         error('BDP:FileDoesNotExist', 'Could not find custom diffusion volume file/folder: %s', bdp_options.custom_diffusion_volume);
      end
   end
   
   % Surface - in diffusion coordinate
   if ~isempty(bdp_options.custom_diffusion_surface)
      if exist(bdp_options.custom_diffusion_surface, 'dir')==7
         f_lst = dir(bdp_options.custom_diffusion_surface);
         for k = 1:length(f_lst)
            if ~f_lst(k).isdir
               input_fname = fullfile(bdp_options.custom_diffusion_surface, f_lst(k).name);
               output_fname = fullfile(fileparts(bdp_options.file_base_name), ...
                  suffix_filename(f_lst(k).name, bdp_options.mprage_coord_suffix));
               dfs_diffusion_to_T1(input_fname, output_fname, ref_bfc, ref_diffusion, affinematrix_file)         
            end
         end
         
      elseif exist(bdp_options.custom_diffusion_surface, 'file')==2
         [~, nm, ext] = fileparts(bdp_options.custom_diffusion_surface);
         output_fname = fullfile(fileparts(bdp_options.file_base_name), ...
            suffix_filename([nm ext], bdp_options.mprage_coord_suffix));
         dfs_diffusion_to_T1(bdp_options.custom_diffusion_surface, output_fname, ref_bfc, ref_diffusion, affinematrix_file)
      else
         error('BDP:FileDoesNotExist', 'Could not find custom T1 surface file/folder: %s', bdp_options.custom_diffusion_surface);
      end
   end
   
   % Surface - in T1 coordinate
   if ~isempty(bdp_options.custom_T1_surface)
      if exist(bdp_options.custom_T1_surface, 'dir')==7
         f_lst = dir(bdp_options.custom_T1_surface);
         for k = 1:length(f_lst)
            if ~f_lst(k).isdir
               input_fname = fullfile(bdp_options.custom_T1_surface, f_lst(k).name);
               output_fname = fullfile(bdp_options.diffusion_coord_output_folder, ...
                  suffix_filename(f_lst(k).name, bdp_options.Diffusion_coord_suffix));
               dfs_T1_to_diffusion(input_fname, output_fname, ref_bfc, ref_diffusion, affinematrix_file)         
            end
         end
         
      elseif exist(bdp_options.custom_T1_surface, 'file')==2
         [~, nm, ext] = fileparts(bdp_options.custom_T1_surface);
         output_fname = fullfile(bdp_options.diffusion_coord_output_folder, ...
            suffix_filename([nm ext], bdp_options.Diffusion_coord_suffix));
         dfs_T1_to_diffusion(bdp_options.custom_T1_surface, output_fname, ref_bfc, ref_diffusion, affinematrix_file)
      else
         error('BDP:FileDoesNotExist', 'Could not find custom T1 surface file/folder: %s', bdp_options.custom_T1_surface);
      end
   end


   
elseif bdp_options.only_transform_data
   if bdp_options.generate_stats
      msg = {'\n', ...
         ['WARNING: --only-transform-data flag was found. But BDP could not find any custom input volume/label/mask '....
         'files. If you want to transform custom data please re-run BDP and use '...
         '--transform-diffusion-volume or --transform-t1-volume '...
         'to specify file/folders to transform.'],...
         '\n'};
      fprintf(bdp_linewrap(msg));
   else
      err_msg = ['--only-transform-data flag was found. But BDP could not find any custom input volume/label/mask '....
         'files. If you want to transform data please re-run BDP and use '...
         '--transform-diffusion-volume or --transform-t1-volume '...
         'to specify file/folders to transform.'];
      error('BDP:ExpectedFileNotFound', bdp_linewrap(err_msg));
   end
end

end


function dfs_T1_to_diffusion(T1_dfs_file, output_dfs_file, T1_bfc, diffusion_bfc, affinematrix_file)
fprintf('\nTransforming input surface file to diffusion coordinate: %s', T1_dfs_file);
load(affinematrix_file);
affine_transform_dfs(T1_dfs_file, inv(M_world), origin, output_dfs_file, T1_bfc, diffusion_bfc);
fprintf('\nFinished transformation. Saved file to disk: %s\n', output_dfs_file);
end

function dfs_diffusion_to_T1(diffusion_dfs_file, output_dfs_file, T1_bfc, diffusion_bfc, affinematrix_file)
fprintf('\nTransforming input surface file to T1 coordinate: %s', diffusion_dfs_file);
load(affinematrix_file);
affine_transform_dfs(diffusion_dfs_file, M_world, origin, output_dfs_file, diffusion_bfc, T1_bfc);
fprintf('\nFinished transformation. Saved file to disk: %s\n', diffusion_dfs_file);
end

