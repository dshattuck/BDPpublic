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


% This function reads the Spherical Harmonic (SH) coefficient files
% specified in filename.odf file saved by BrainSuite.
% It then multiplies the SH basis function and returns the ODF.
% Inputs :
% filepath - Full path to filename.odf : e.g. 'c:\data\FRACT\'
% filename - Name of the .odf file with extension : e.g. 'example.odf'
% Outputs:
% SH coeff - Spherical harmonic coefficients stored by BDP
function [SHcoeff nodf]= readBSodf(filepath, filename)
    fid = fopen([filepath '/' filename], 'r');
    ncell = textscan(fid, '%s\n'); fclose(fid);
    nodf = numel(ncell{1});
    
    fid = fopen([filepath '/' filename], 'r');
    disp('Reading SH coefficient files...')
    for num = 1:nodf,
        fname = fgets(fid);
        if exist([filepath '/' fname(1:end-1)])
            nii = load_untouch_nii_gz([filepath '/' fname(1:end-1)]);
            SHcoeff(:,:,:,num) = nii.img;
            disp(['SH coefficient file' num2str(num) ' done.']);
        end;
    end;
    disp('Done');
end
