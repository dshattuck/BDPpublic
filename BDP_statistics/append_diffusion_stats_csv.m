% 
% BDP BrainSuite Diffusion Pipeline
% 
% Copyright (C) 2021 The Regents of the University of California and
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


function append_diffusion_stats_csv(file_base, file_suffix, labels, roi_id, voxels_missing_fraction, label_data, ...
                                    dewisp_mask_file, stats_file_base, label_fname)
% Appends statistics files for diffusion data using input label/mask file. If the file does not
% exists then creates one.
%
% file_base - for quantitative diffusion parameters
% label_file - should be taken care of diffusion mask (data in MPRAGE coordinate) - missing data
% dewisp_mask_file - mask file to get white_matter & gray_matter.
%

if length(labels)<1
   return;
end

fprintf('\nComputing statistics...')
workdir = tempname();
mkdir(workdir);
temp_nii_file = fullfile(workdir, [randstr(15) '.nii.gz']);

if numel(labels)~=numel(roi_id)
   error('labels and roi_id must have same number of elements.')
end

dewisp_mask = reorient_nifti_sform(dewisp_mask_file, temp_nii_file);
d_measures = {'mADC', 'FA', 'MD', 'axial', 'radial', 'L2', 'L3', 'FRT_GFA'};

cpb = ConsoleProgressBar(); % Set progress bar parameters
cpb.setMinimum(0); cpb.setMaximum(length(d_measures)); cpb.start();
for k = 1:length(d_measures)
   measure_nii = [file_base '.' d_measures{k} file_suffix '.nii.gz'];
   measure_csv = [stats_file_base '.' d_measures{k} file_suffix '.stat.csv'];
   append_csv(measure_csv, measure_nii, labels, roi_id, voxels_missing_fraction, label_data, ...
      dewisp_mask, temp_nii_file, label_fname, stats_file_base)
   
   text = sprintf('%d/%d measures done', k, length(d_measures));
   cpb.setValue(k); cpb.setText(text);
end
cpb.stop();

rmdir(workdir, 's');
end


function append_csv(measure_csv, measure_nii, labels, roi_id, voxels_missing_fraction, label_data,...
                    dewisp_mask, temp_nii_file, label_fname, stats_file_base)
% append stats for input measure files

if exist(measure_nii, 'file')
   param = reorient_nifti_sform(measure_nii, temp_nii_file);
   param_stat = zeros([length(labels), 9]);
   
   for k = 1:length(labels)
      lbl_msk = (label_data.img==labels(k));
      dewisp_pos_msk = dewisp_mask.img>0 & lbl_msk;
      dewisp_zero_msk = dewisp_mask.img<=0 & lbl_msk;
      
      data = param.img(lbl_msk);
      param_stat(k,1) = mean(data);
      param_stat(k,2) = std(data);
      param_stat(k,3) = length(data);
      
      data = param.img(dewisp_pos_msk);
      param_stat(k,4) = mean(data);
      param_stat(k,5) = std(data);
      param_stat(k,6) = length(data);
      
      data = param.img(dewisp_zero_msk);
      param_stat(k,7) = mean(data);
      param_stat(k,8) = std(data);
      param_stat(k,9) = length(data);
   end
   
   csv_fileID = fopen(measure_csv, 'a');
   for k = 1:length(labels)
      fprintf(csv_fileID,'%d,%d', roi_id(k), round(voxels_missing_fraction(k)*param_stat(k,3)));
      fprintf(csv_fileID,',%05.10f',param_stat(k,:));
      fprintf(csv_fileID,',%s\n', comment_str(label_fname, stats_file_base, labels(k)));
   end
   fclose(csv_fileID);
end
end


function str = comment_str(label_fname, stats_file_base, label)
if (length(label_fname)>18 && strcmp(label_fname(end-18:end), '.svreg.label.nii.gz')) ...
      || (length(label_fname)>23 && strcmp(label_fname(end-23:end), '.svreg.corr.label.nii.gz'))
   str = '';
   
else % custom label
   str = [label_fname ' - ' num2str(label)];
   %    fbase = [fileBaseName(stats_file_base) '.'];
   %    l = length(fbase);
   %    if length(label_fname)>l && strcmp(label_fname(1:l), fbase)
   %       str = label_fname(l+1:end); % remove <filebasename>
   %    else
   %       str = label_fname;
   %    end
end

end


