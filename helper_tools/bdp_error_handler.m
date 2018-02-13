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


function bdp_error_handler(err)
% Sort through the message ID of errors and quit generously when the error id
% starts with 'BDP:', showing/adding relevant messages.
BDP_URL = 'http://brainsuite.org/processing/diffusion/pipeline/';
BDP_FLAG_URL = 'http://brainsuite.org/processing/diffusion/flags/';
BDP_FILE_FORMAT_URL = 'http://brainsuite.org/processing/diffusion/file-formats/';

error_id = err.identifier;
error_msg = [err.message '\n'];
error_title = '';
error_help = '';


switch error_id
   case 'BDP:ExpectedFileNotFound' % when an expected file is not found, like svreg labels
      error_title = '*          FILE NOT FOUND             *\n';
      error_help = ['The file(s) are required to run BDP using the given input parameters. '...
         'Check to make sure that the file exists. You may need to run  '...
         'BDP or BrainSuite extraction sequence again with appropriate options  '...
         'in order to generate the file(s).\n'];
      
   case 'BDP:FileDoesNotExist'
      error_title = '*         FILE DOES NOT EXIST         *\n';
      error_help = ['Check to make sure that the file exists and that you spelled '...
         'its filename and path correctly\n'];
      
   case 'BDP:InvalidFile'
      error_title = '*             INVALID FILE            *\n';
      error_help = ['BDP relies on pre-defined file format and filename pattern. Please '...
         'refer to error message above. You can find more details of file format at \n', BDP_FILE_FORMAT_URL];
      
   case 'BDP:FlagError'
      error_title = '*       CHECK YOUR INPUT FLAGS        *\n';
      error_help = {['BDP encountered incorrect usage of an input or a flag which it '...
         'doesn''t recognize or doesn''t support anymore. Please refer to error message above and ' ... 
         'visit the BrainSuite website at following url for documentation '...
         'of BDP flags:\n'], BDP_FLAG_URL, '\n\n'};
      
   case 'BDP:MandatoryInputNotFound'
      error_title = '*   A MANDATORY INPUT IS NOT DEFINED  *\n';
      error_help = {['BDP could not find any flag defining a mandatory input. '...
         'Please refer to error message above. You can visit the BrainSuite website at '...
         'following url for documentation of BDP Usage:\n'], BDP_FLAG_URL, '\n\n'};
      
   case 'BDP:UnknownFlag'
      error_title = '*         UNKNOWN INPUT FLAG          *\n';
      error_help = {['BDP encountered an input flag it doesn''t recognize, often caused by '...
         'a typo or by following a flag that requires more information (e.g. '...
         '--nii, which should be followed by the location of a NIfTI file) with '...
         'an additional flag. '], ...
         'Visit the BrainSuite website at \n', BDP_FLAG_URL,...
         '\nfor more details.\n'};
      
   case 'BDP:UnsupportedDicom'
      error_title = '*          UNSUPPORTED DICOM          *\n';
      error_help = ['It may be easiest to first convert your DICOMs to NIfTI and then try '...
         'running BDP in NIfTI mode (this will require text files of the '...
         'b-vectors and b-values, such as those provided by dcm2nii\n'];
      
   case 'BDP:DicomInconsistency'
      error_title = '*  MULTIPLE SCANS IN SAME DIRECTORY?   *\n';
      error_help = {['At least two of the DICOMs in the above directory had information in '...
         'their headers suggesting that they are from different sequences. BDP '...
         'assumes that all of the DICOMs in a directory belong to a single '...
         'sequence, so make sure each sequence''s DICOMs are in their own '...
         'directory (BDP can handle multiple DICOM directories listed after the '...
         '-d flag).\n\n'],...
         ['If you think you''re recieving this error by mistake (i.e. each '...
         'directory only contains the DICOMs from a single sequence), it may be ' ...
         'easiest to first convert your DICOMs to NIfTI and then try running BDP '...
         'in NIfTI mode (this will require text files of the b-vectors and '...
         'b-values, such as those provided by dcm2nii.\n']};
      
   case 'BDP:DicomInvalidFolder'
      error_title = '*        INVALID DICOM FOLDER         *\n';
      error_help = ['The specified dicom folder is not valid for reading dicoms. Please '...
         'refer to the error message above and make appropriate changes.\n'];
      
   case 'BDP:CheckNiftiFile:WrongInput'
      error_title = '*      CHECK YOUR INPUT (NIFTI)       *\n';
      error_help = 'Make sure the NIfTI filename is a single alphanumeric string.';
      
   case 'BDP:CheckNiftiFile:WrongFileName'
      error_title = '* INCORRECT EXTENSION FOR NIFTI FILE  *\n';
      error_help = ['Make sure you are using a NIfTI-format file, and that it has the proper '...
         'extension (.nii / .nii.gz / .img / .hdr)\n'];
      
   case 'BDP:CheckNiftiFile:HeaderError'
      error_title = '*        NIFTI FILE HEADER ERROR      *\n';
      error_help = ['BDP requires information about the scan''s orientation and resolution '...
         'that is normally found within the header of the NIFTI file. It looks '...
         'like the header does not have all the information. Please check the '...
         'input NIFTI file and make sure it has correct NIfTI-1 headers.\n'];
      
   case 'BDP:InconsistentDiffusionParameters'
      error_title = '*  Inconsistent Diffusion Parameters  *\n';
      error_help = ['Check to make sure that bvec/bval or bmat file have correct number of entries '...
         'corresponding to the diffusion scan file. '...
         'Check to make sure gradient file contains "0, 0, 0" row(s)/col(s) for b=0 images.\n'];
      
   case 'BDP:LowMemoryMachine'
      error_title = '*          NOT ENOUGH MEMORY          *\n';
      error_help = {['BDP requires about 6GB of memory (RAM + virtual memory) to run properly. '...
         'Try quitting some unnecessary programs currently running, or increasing '...
         'the amount of virtual memory available (advanced--search online for '...
         'documentation for your systerm if you want to do this). If this is not '...
         'possible, then you can try running BDP with either the --low-memory or  '...
         '--ignore-memory flags.\n '], ...
         ['--low-memory will run distortion correction at a lower resolution, '...
         'possibly decreasing the accuracy of distortion correction.\n\n'],...
         ['--ignore-memory will skip this memory check, possibly leading to a crash '...
         'if BDP runs out of memory.\n']};
      
   otherwise
      
      if errorInMasking(err)
         error_msg = bdp_linewrap(['BDP encountered an error while estimating the brain-mask for ' ...
            'the input diffusion volume.\n']);
         error_title = '*         AUTO-MASKING FAILED         *\n';
         error_help = ['Please define a mask for diffusion volume by using flag --dwi-mask <mask_filename>. The '...
            'mask can be generated and hand edited in BrainSuite interface.\n'];
      
      else
         % Something unexpected has happened and we'll need the full
         % error message from the user, so just rethrow it
         rethrow(err);
      end
end

fprintf(1, '\n\n');
fprintf(1, '***************************************\n');
fprintf(1, '*                                     *\n');
fprintf(1, '*          Error running BDP          *\n');
fprintf(1, '*                                     *\n');
fprintf(1, error_title);
fprintf(1, '*                                     *\n');
fprintf(1, '***************************************\n\n');
fprintf(1, ['Error message:\n' error_msg]);
fprintf(1, '\n');
fprintf(1, ['Error help/resolution:\n' bdp_linewrap(error_help)]);
fprintf(1, '\n');
fprintf(1, '***************************************\n\n');
end


function out = errorInMasking(err)
% Check if the error was raised during masking process

msk_func = {'maskHeadPseudoHist', 'mask_head_pseudo', 'maskDWI', 'mask_b0_setup'};
stack_func = {};

for k = 1:length(err.stack)
   stack_func{k} = err.stack(k).name;
end

Lia = ismember(msk_func, stack_func);

if any(Lia)
   out = true;
else
   out = false;
end

end

