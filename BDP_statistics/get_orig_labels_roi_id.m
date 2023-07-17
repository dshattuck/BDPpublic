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


function [labels, roi_id] = get_orig_labels_roi_id(label_file, bdp_opt)
% Find the labels and corresponding roi_id for input label_file. 
% In case of svreg label or custom xml file, labels & roi_id are read directly from xml file 
%   (via set_labels_roi_id). 
% For custom label/mask files, labels & roi_id are read from global BDP_xml_struct. BDP_xml_struct
%   must be set appropiately previously by calling set_labels_roi_id on each of custom label/mask
%   file.
%


global BDP_xml_struct

if ~isempty(bdp_opt.custom_label_description_xml)
   [labels, roi_id] = set_labels_roi_id(label_file, bdp_opt);
   
   
else % not custom xml file
   [~, lname, ext] = fileparts(label_file);
   lname = [lname ext];
   
   [~, bName, ext] = fileparts(bdp_opt.bfc_file_base);
   bName = [bName ext];
   
   svreg_filename1 = [bName '.svreg.label.nii.gz'];
   svreg_filename2 = [bName '.svreg.corr.label.nii.gz'];

   if strcmp(lname, svreg_filename1) || strcmp(lname, svreg_filename2)
      [labels, roi_id] = set_labels_roi_id(label_file, bdp_opt);
      
      
   else % custom mask/label - read from xml struct
      nfile = length(BDP_xml_struct.BDP_ROI_MAP.file);
      
      fnd = false;
      for k = 1:nfile
         fname = fullfile(BDP_xml_struct.BDP_ROI_MAP.file{k}.Attributes.path, ...
                          BDP_xml_struct.BDP_ROI_MAP.file{k}.Attributes.name);
         if strcmp(fname, label_file)
            fnd = true;
            break;
         end
      end
      
      if ~fnd
         error('BDP_ROI_MAP.xml entry for label could not be found: %s', label_file);
      end
      
      nval = length(BDP_xml_struct.BDP_ROI_MAP.file{k}.map);
      labels = zeros(nval, 1);
      roi_id = zeros(nval, 1);
      for m = 1:nval
         labels(m) = str2double(BDP_xml_struct.BDP_ROI_MAP.file{k}.map{m}.Attributes.value);
         roi_id(m) = str2double(BDP_xml_struct.BDP_ROI_MAP.file{k}.map{m}.Attributes.roi_id);
      end
   end
end

end
