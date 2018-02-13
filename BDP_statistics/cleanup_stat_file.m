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


function cleanup_stat_file(stats_file_base, file_suffix, bdp_opt, ignored_id)
% Removes repeated-zero entries in stat file and list the stats in the same order as
% the custom xml file in use.

if nargin<4
   ignored_id = [];
end

global BDP_xml_struct

% Get list of ROI ids (in desired order)
%  * When custom xml - Directly use it
%  * When no custom xml - Use BDP-xml file and also check for global BDP_xml_struct

roi_id_custom = []; % Additional ROI-ids created by BDP for custom label files
if isempty(bdp_opt.custom_label_description_xml)
   data_xml = xml2struct('brainsuite_labeldescription_BDP.xml');
   
   if ~isempty(BDP_xml_struct.BDP_ROI_MAP.file)
      for k = 1:length(BDP_xml_struct.BDP_ROI_MAP.file)
         for m = 1:length(BDP_xml_struct.BDP_ROI_MAP.file{k}.map)
            roi_id_custom = cat(1, roi_id_custom, str2double(BDP_xml_struct.BDP_ROI_MAP.file{k}.map{m}.Attributes.roi_id));
         end
      end
   end
   
else % custom xml
   data_xml = xml2struct(bdp_opt.custom_label_description_xml);
end

roi_id = zeros(length(data_xml.labelset.label),1);
for k = 1:length(data_xml.labelset.label)
   roi_id(k) = str2num(data_xml.labelset.label{k}.Attributes.id);
end
roi_id = [roi_id; roi_id_custom]; % full list of ROI ids


% throw away ignored ROIs 
roi_id = setdiff(roi_id, ignored_id, 'stable');


% clean stat files
d_measures = {'mADC', 'FA', 'MD', 'axial', 'radial', 'L2', 'L3', 'FRT_GFA'};

for k = 1:length(d_measures)
   fileName = [stats_file_base '.' d_measures{k} file_suffix '.stat.csv'];
   
   if exist(fileName, 'file') == 2
      
      [hdr, M, col1, col_end] = csvreadBDP(fileName);
      if ~isempty(col1)
         error('1st column should be numeric ROI ids. This csv file seems to be not written by BDP: %s', escape_filename(fileName))
      end
      if isempty(col_end), cmt = {}; else cmt = {''};  end
      
      % Throw away zero rows - this is really required to get rid of repeated zero-rows when a
      % custom xml file is used (when custom-xml file is used all labels listed are searched in
      % every single label file)
      zero_mask = ~(abs(M(:,2))>0 | abs(M(:,5))>0);
      M(zero_mask,:) = [];
      col1(zero_mask,:) = [];
      col_end(zero_mask,:) = [];
      
      
      % List by custom xml order
      M_new = [];
      col1_new = cell(0, size(col1, 2));
      col_end_new = cell(0, size(col_end, 2));
      for id = 1:length(roi_id)
         msk = (M(:,1)==roi_id(id));
         
         if any(msk) % add all rows matching ROI id
            M_new = cat(1, M_new, M(msk,:));
            col1_new = cat(1, col1_new, col1(msk,:));
            col_end_new = cat(1, col_end_new, col_end(msk,:));
            
         else % add a zero row when ROI id is not found
            M_new = cat(1, M_new, [roi_id(id) 0 NaN NaN 0 NaN NaN 0 NaN NaN 0]);
            col1_new = cat(1, col1_new, {});
            col_end_new = cat(1, col_end_new, cmt);
         end
      end
      csvwriteBDP(fileName, hdr, M_new, col1_new, col_end_new);
   end
end

end

