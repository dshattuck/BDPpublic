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


function filename = bdp_summary(optionsStruct, cmd_in, bdp_ticID)

citations = struct( ...
   'bhushan2012', false, ...
   'bhushan2015INVERSION', false, ...
   'bhushan2014InversionISMRM', false, ...
   'haldar2013', false, ...
   'kim2009', false, ...
   'ozarslan2009', false, ...
   'yeh2010', false);


filecontents = {'BrainSuite Diffusion Pipeline: Processing Summary\n', ...
                '*************************************************\n\n'};
filename = [optionsStruct.file_base_name '.BDPSummary.txt'];


% File Header
versionNum = optionsStruct.bdp_version;
if ~isempty(versionNum)
   filecontents{end+1} = ['BDP Version: ' versionNum '\n'];
end
filecontents{end+1} = ['Platform: ' getPlatformInfo() '\n'];
filecontents{end+1} = ['Processing finished: ' datestr(clock, 'local') '\n'];
filecontents{end+1} = ['Scan: ' escape_filename(optionsStruct.bfc_file_base) '\n\n'];



% Check flags and add message to summary as needed
if optionsStruct.no_structural_registration
   
   if optionsStruct.fieldmap_distortion_correction
      filecontents{end+1} = ['Diffusion MRI data was corrected for ' ...
         'susceptibility-induced distortions using an acquired B0 fieldmap [Bhushan 2015].\n\n'];
      citations.bhushan2015INVERSION = true;
   end
   
else % general co-registration
   if optionsStruct.registration_distortion_correction
      filecontents{end+1}  = ['Diffusion MRI data was co-registered '...
         'to the anatomical T1-weighted image using INVERSION method [Bhushan 2015, 2014] '...
         'and was corrected for susceptibility-induced distortions using a non-rigid '...
         'registration-based method [Bhushan 2015, 2012].\n\n'];
      citations.bhushan2012 = true;
      citations.bhushan2014InversionISMRM = true;
      citations.bhushan2015INVERSION = true;
   end
   
   if optionsStruct.fieldmap_distortion_correction
      filecontents{end+1} = ['Diffusion MRI data was co-registered ' ...
         'to the anatomical T1-weighted image using INVERSION method [Bhushan 2015, 2014] and corrected for ' ...
         'susceptibility-induced distortions using an acquired B0 fieldmap.\n\n'];
      citations.bhushan2014InversionISMRM = true;
      citations.bhushan2015INVERSION = true;
   end
   
   % No distortion-correction
   if ~optionsStruct.fieldmap_distortion_correction ...
         && ~optionsStruct.registration_distortion_correction
      filecontents{end+1} = ['Diffusion MRI data was co-registered' ...
         ' to the anatomical T1-weighted image using rigid registration' ...
         ' based on INVERSION method [Bhushan 2015, 2014].\n\n'];
      citations.bhushan2014InversionISMRM = true;
      citations.bhushan2015INVERSION = true;
   end
end

% Tensor estimation
if optionsStruct.estimate_tensor
   filecontents{end+1} = ['Diffusion tensors were estimated' ...
      ' using a weighted linear least squares method, and scalar' ...
      ' diffusion parameters such as fractional anisotropy (FA), mean ' ...
      'diffusivity (MD), radial diffusivity, and axial diffusivity were' ...
      ' computed based on an eigendecomposition of the tensors as' ...
      ' described in [Kim 2009].\n\n'];
   citations.kim2009 = true;
end

% ODF/FRACT estimation
if optionsStruct.estimate_odf_FRACT && optionsStruct.estimate_odf_FRT
   filecontents{end+1} = ['Orientation distribution functions' ...
      ' (ODFs) were computed using  the Funk-Radon Transform, the Funk-Radon and Cosine Transform' ...
      ' (FRACT) as described in [Haldar 2013].\n\n'];
   citations.haldar2013 = true;
   citations.ozarslan2009 = true;
   
elseif optionsStruct.estimate_odf_FRACT
   filecontents{end+1} = ['Orientation distribution functions' ...
      ' (ODFs) were computed using the Funk-Radon and Cosine Transform' ...
      ' (FRACT) [Haldar 2013].\n\n'];
   citations.haldar2013 = true;

% FRT estimation
elseif optionsStruct.estimate_odf_FRT
   filecontents{end+1} = ['Orientation distribution functions' ...
      ' (ODFs) were computed using the Funk-Radon Transform' ...
      ' implementation described in [Haldar 2013].\n\n'];
   citations.haldar2013 = true;
end;

%3DSHORE estimation
if optionsStruct.estimate_odf_3DSHORE
   filecontents{end+1} = ['Orientation distribution functions' ...
      ' (ODFs) were computed using the 3D SHORE basis [Ozarslan 2009].\n\n'];
   citations.ozarslan2009 = true;
end

%GQI estimation
if optionsStruct.estimate_odf_GQI
   filecontents{end+1} = ['Orientation distribution functions' ...
      ' (ODFs) were computed using the generalized q-sampling imaging method described in [Yeh 2010].\n\n'];
   citations.yeh2010 = true;
end


% %%%%%%%%%%
% Append citation
% %%%%%%%%%%
filecontents{end+1} = ['\n\nREFERENCES:\n\n'];

if citations.bhushan2015INVERSION
   filecontents{end+1} = ['[Bhushan 2015] C. Bhushan, J. P. ' ...
      'Haldar, S. Choi, A. A. Joshi, D. W. Shattuck, R. M. Leahy, "Co-registration '...
      'and distortion correction of diffusion and anatomical images based on inverse '...
      'contrast normalization", NeuroImage, 2015. DOI:10.1016/j.neuroimage.2015.03.050\n\n'];
end

if citations.bhushan2012
   filecontents{end+1} = ['[Bhushan 2012] C. Bhushan, J. P.' ...
      ' Haldar, A. A. Joshi, R. M. Leahy, "Correcting susceptibility' ...
      '-induced distortion in diffusion-weighted MRI using constrained ' ...
      'nonrigid registration", Asia-Pacific Signal & Information' ...
      ' Processing Association Annual Summit and Conference' ...
      ' (APSIPA ASC), Hollywood, pp. 1-9, 2012\n\n'];
end

if citations.bhushan2014InversionISMRM
   filecontents{end+1} = ['[Bhushan 2014] C. Bhushan, J. P.' ...
      ' Haldar, A. A. Joshi, D. W. Shattuck, R. M. Leahy, "INVERSION: A robust '...
      'method for co-registration of MPRAGE and diffusion MRI '...
      'images", Joint Annual Meeting ISMRM-ESMRMB, Milan, Italy, '...
      '2014, p. 2583 \n\n'];
end

if citations.haldar2013
   filecontents{end+1} = ['[Haldar 2013] J. P. Haldar, R. M.' ...
      ' Leahy, "Linear transforms for Fourier data on the sphere:' ...
      ' Application to high angular resolution diffusion MRI of the' ...
      ' brain", NeuroImage, Volume 71, Pages 233-247, 2013\n\n'];
end

if citations.kim2009
   filecontents{end+1} = ['[Kim 2009] J. H. Kim, J. P. Haldar,' ...
      ' Z.-P. Liang, S.-K. Song, "Diffusion tensor imaging of mouse' ...
      ' brain stem and cervical spinal cord", Journal of Neuroscience ' ...
      'Methods, Volume 176, Issue 2, Pages 186-191, 2009\n\n'];
end

if citations.ozarslan2009
   filecontents{end+1} = ['[Ozarslan 2009] E. Ozarslan, C. Koay,' ...
      'T. M. Shepherd, S. J. Blackband, P. J. Basser, "Simple harmonic ' ...
      'oscillator based reconstruction and estimation for three-dimensional' ...
	  'q-space MRI", Joint Annual Meeting ISMRM-ESMRMB, Honolulu, Hawaii, USA, ' ...
      'Page 1396, 2009\n\n'];
end

if citations.yeh2010
   filecontents{end+1} = ['[Yeh 2010] Fang-Cheng Yeh, Van Jay Wedeen,' ...
	  'and Wen-Yih Isaac Tseng, "Generalized q-Sampling Imaging", ' ...
      'IEEE Transactions on medical imaging, Volume 29, No. 9,' ...
	  'Pages 1626-1635, 2010\n\n'];
end

% linewrap
filecontents = bdp_linewrap(filecontents);


% Add the command used to the end of file
if exist('cmd_in','var')
   if ispc
      cmd_str = ['bdp.exe ' escape_filename(cmd_in{1})];
   else
      cmd_str = ['bdp.sh ' escape_filename(cmd_in{1})];
   end
   
   for k = 2:length(cmd_in)
      if strcmpi(cmd_in{k}(1), '-')
         cmd_str = [cmd_str '\n\t' escape_filename(cmd_in{k})];
      else
         cmd_str = [cmd_str ' ' escape_filename(cmd_in{k})];
      end
   end
   
   filecontents = [filecontents '\n\nCOMMAND USED:\n\n' cmd_str '\n\n'];
end

% Add total time taken to process
if exist('bdp_ticID','var')
   filecontents = [filecontents 'Approximate processing time: ' num2str(toc(bdp_ticID)/60, 4) ' minutes\n\n'];
end


% Correct for Windows line endings
if ispc
   filecontents = strrep(filecontents, '\n', '\r\n');
end


% Create summary file
fid = fopen(filename, 'w');
fprintf(fid, filecontents);
fclose(fid);

end

function str = getPlatformInfo()
archstr = computer('arch');
if ispc
   str = [archstr ' (Microsoft Windows)'];
elseif ismac
   str = [archstr ' (Apple Mac OS)'];
elseif isunix
   str = [archstr ' (Linux)'];
end
end

