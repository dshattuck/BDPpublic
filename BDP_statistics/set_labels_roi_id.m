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


function [labels, roi_id] = set_labels_roi_id(label_file, bdp_opt)
% Sets (& returns) labels (voxel intensities) and corresponsding roi_id for input label file.
% 1. When bdp_opts has defined custom xml file, the xml file is directly used
% 2. When label_file is svreg-label then BDP's inbuilt xml label-description file is used
% 3. When both (1) & (2) is not true, then this function sets/updates the global BDP_xml_struct
%    which define BDP_ROI_MAP for intensities in the file.  
%

global BDP_custom_roi_id_count BDP_xml_struct

if ~isempty(bdp_opt.custom_label_description_xml)
   label_xml = bdp_opt.custom_label_description_xml;
   data = xml2struct(label_xml);
   
   labels = zeros(length(data.labelset.label),1);
   for k = 1:length(data.labelset.label)
      labels(k) = str2num(data.labelset.label{k}.Attributes.id);
   end
   roi_id = labels;
   
   fprintf('\nCustom labels description xml file found. ROI ids are same as that described in %s\n', label_xml);
   
else % not custom xml file   
   [~, lname, ext] = fileparts(label_file);
   lname = [lname ext];
   
   [pathstr, bName, ext] = fileparts(bdp_opt.bfc_file_base);
   bName = [bName ext];
   
   svreg_filename1 = [bName '.svreg.label.nii.gz'];
   svreg_filename2 = [bName '.svreg.corr.label.nii.gz'];
   
   if strcmp(lname, svreg_filename1) || strcmp(lname, svreg_filename2)
      
      label_xml = 'brainsuite_labeldescription_BDP.xml'; % BDP's inbuilt xml file
      data = xml2struct(label_xml);
      
      labels = zeros(length(data.labelset.label),1);
      for k = 1:length(data.labelset.label)
         labels(k) = str2num(data.labelset.label{k}.Attributes.id);
      end
      roi_id = labels;
      
      fprintf('\nSVReg labels found. Inbuilt xml file will be used.\n');
      
   else % custom mask/label
      
      label_data = load_untouch_nii_gz(label_file);
      if ndims(label_data.img)~=3
         error('BDP:InvalidLabelFile','Label/mask file must be a 3D file: %s', escape_filename(label_file));
      end
      
      if ~isa(label_data.img, 'integer') && max(abs(floor(label_data.img(:))-label_data.img(:)))>0
         error('BDP:InvalidLabelFile','Label/mask file must have only integer values: %s', escape_filename(label_file));
      end
      
      labels = unique(label_data.img(label_data.img~=0));
      l_msg = sprintf('\nBDP found %d labels in custom-label file: %s', length(labels), escape_filename(label_file));
      
      if length(labels)>200
         msg = [l_msg '\nIt seems that the custom-label file contains too many labels. Please make sure it is the desired '...
            'label file. BDP will continue anyway with this label file!'];
         bdpPrintWarning('Too many labels?', msg);
      else
         fprintf(l_msg);
      end
      
      if isempty(labels)
         fprintf('\nNo labels found!\n')
         roi_id = [];
         return;
      else
         % increment custom ROI id counter
         if isempty(BDP_custom_roi_id_count )
            BDP_custom_roi_id_count  = 10000;
         end
         
         roi_id = BDP_custom_roi_id_count + (1:length(labels));
         BDP_custom_roi_id_count = BDP_custom_roi_id_count + length(labels);
         
         % update xml struct
         ifile = length(BDP_xml_struct.BDP_ROI_MAP.file) + 1;
         
         [pathstr, lname, ext] = fileparts(label_file);
         BDP_xml_struct.BDP_ROI_MAP.file{ifile}.Attributes.name = [lname ext];
         BDP_xml_struct.BDP_ROI_MAP.file{ifile}.Attributes.path = pathstr;
         
         for k = 1:length(labels)
            BDP_xml_struct.BDP_ROI_MAP.file{ifile}.map{k}.Attributes.value = num2str(int64(labels(k)));
            BDP_xml_struct.BDP_ROI_MAP.file{ifile}.map{k}.Attributes.roi_id = num2str(roi_id(k));
         end
      end
      labels = labels(:);
      roi_id = roi_id(:);
   end
end

end

