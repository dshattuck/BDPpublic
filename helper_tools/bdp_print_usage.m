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


function bdp_print_usage(verbose, outFile, manifestFile)

if nargin == 0
   verbose = false;
   fid = 1; % No file given, so print to screen
elseif nargin == 1
   if ischar(verbose)
      outFile = verbose;
      verbose = false;
   else
      fid = 1;
   end
end

if exist('outFile', 'var')
   try
      fid = fopen(outFile, 'w');
   catch err
      error('BDP:FileDoesNotExist', 'Could not create %s for writing usage message', outFile);
   end
end

if exist('manifestFile', 'var')
   usageMsg = bdp_usage(verbose, manifestFile);
else
   usageMsg = bdp_usage(verbose);
end

fprintf(fid, usageMsg);
