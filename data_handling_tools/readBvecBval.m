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


function [bvec, bval] = readBvecBval(bvec_file, bval_file)
% bvec is nDirx3. bval is nDirx1

% load bvec
if exist(bvec_file, 'file')~=2
   error('BDP:FileDoesNotExist', ['The bvec file does not exist: ' escape_filename(bvec_file)]);
end

try
   bvec = load(bvec_file, '-ascii');
   sz = size(bvec);
   if sz(1)~=3 && sz(2)~=3
      err_msg = {['One dimesion of the gradient vectors in bvec file must be of size 3: ' escape_filename(bvec_file)], ...
         '\n', 'Please make sure that the file has either 3 rows or 3 columns of numbers.'};
      error('BDP:InvalidFile', bdp_linewrap(err_msg))
   end
   if sz(2) ~= 3
      bvec = transpose(bvec);
   end
catch err
   if strncmp(err.identifier, 'BDP:', 4) % when BDP error rethrow it
      rethrow(err);
   else
      err_msg = {['The bvec file does not seems to contain valid gradient vectors: ' escape_filename(bvec_file)], ...
         '\n', ['The generate error message is: ' err.message]};
      error('BDP:InvalidFile', bdp_linewrap(err_msg))
   end
end


% load bval
if exist('bval_file', 'var')
   if exist(bval_file, 'file')~=2
      error('BDP:FileDoesNotExist', ['The bval file does not exist: ' escape_filename(bval_file)]);
   end
   
   try
      bval = load(bval_file, '-ascii');
      if ~isvector(bval)
         err_msg = {['One dimesion of the bval file must be of size 1: ' escape_filename(bval_file)], ...
            '\n', 'Please make sure that the file has either 1 row or 1 column of numbers.'};
         error('BDP:InvalidFile', bdp_linewrap(err_msg))
      end
      bval = bval(:);
      
      if size(bvec,1)~=length(bval)
         err_msg = {'Number of values in bvec and bval files do not match.', ...
            ['\nbval file: ' escape_filename(bval_file)], ...
            ['\nbvec file: ' escape_filename(bvec_file) '\n'], ...
            ['Please make sure that the files have equal number of entries corresponding '...
            'to diffusion encoding directions.']};
         error('BDP:InvalidFile', bdp_linewrap(err_msg))
      end
      
   catch err
      if strncmp(err.identifier, 'BDP:', 4) % when BDP error rethrow it
         rethrow(err);
      else
         err_msg = {['The bval file does not seems to be in valid format: ' escape_filename(bval_file)], ...
            '\n', ['The generate error message is: ' err.message]};
         error('BDP:InvalidFile', bdp_linewrap(err_msg))
      end
   end
end


end
