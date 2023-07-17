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


function bsOdfFibFileFAST(nii_file,odf_fpath,odf_fname,d_loc,op,opname,FlipFlag_X,FlipFlag_Y,FlipFlag_Z,mask)
% Direct reconstruction from huge image data
% In this function, 4 FA components (FA0~FA3) are used
% Parameters:
% 	nii_fpath: the filepath of the image volume
%   nii_fname: the filename of the image volume
%   odf_fpath: the filepath of the ODF file from BrainSuite
%   odf_fname: the filename of the ODF file from BrainSuite
%   d_loc = './';
%   op: directory to store the fib results
%   opname: result file name
%   FlipFlag_X/FlipFlag_Y/FlipFlag_Z:(no default) 0: no flipping, 1: flip. Adjust the flags for flipping ODF to your input dataest. 
%   mask_path: mask file
% addpath(genpath(pwd))
% addpath(genpath('../'))

% nii = load_nii_BIG_Lab([nii_fpath nii_fname]);
nii = load_untouch_nii_gz(nii_file);

[odf_faces,odf_vertices] = getOdfSurf();

if nargin < 11
    mask = zeros(size(nii.img)) + 255;
end;

% you may need to change the dimension, number of diffusion images, and voxel size
dim = nii.hdr.dime.dim(2:4);
voxel_size = nii.hdr.dime.pixdim(2:4);

fa0 = zeros(dim);
fa1 = zeros(dim);
fa2 = zeros(dim);
fa3 = zeros(dim);

index0 = zeros(dim);
index1 = zeros(dim);
index2 = zeros(dim);
index3 = zeros(dim);

max_dif = zeros(dim(1),dim(2));

% load ODF into redBSodf to get SHcoeff
[SHcoeff, nSH] = readBSodf(odf_fpath, odf_fname);
SHcoeff = flip(SHcoeff,2); mask = flip(mask,2);
SHcoeff = flip(SHcoeff,1); mask = flip(mask,1);

for ndir = 1:size(SHcoeff,4)
    temp = SHcoeff(:,:,:,ndir);
    temp(mask == 0) = 0;
    SHcoeff(:,:,:,ndir) = temp;
end;
clear temp;

for z = 1:dim(3)
    sche=round(100*double(z)/dim(3));
    if rem((sche),5)==0
        fprintf('Processing layers in Superior-Inferior direction.... %d%% finished.\n',sche);
    end
    ODF = double(squeeze(genNormOdfFromSH(SHcoeff(:,:,z,:),odf_vertices',nSH)));
    ODF(ODF<0) = 0;
    
    p = find_peak(ODF,odf_faces,dim);                     
    
    for evp = 1:size(p(:),1)
        pxy = p{evp};
        pxy_c = pxy;
        for c = 1: size(pxy,3)
            for s = c+1:size(pxy,3)
                if isequal(odf_vertices(:,pxy(1,1,c)), -1*odf_vertices(:,pxy(1,1,s)))
                pxy_c(1,1,s) = 0;
                end;
            end;
        end;
        p{evp} = nonzeros(pxy_c);
    end;
    
    max_dif = 1; %genNormOdfFromSHgenNormOdfFromSHmax(max_dif,mean(ODF,3));
    min_odf = min(ODF,[],3); 

    for x=1:dim(1)             
        for y=1:dim(2)

            clear d
            d=p{x,y};
            if ~isempty(d)
                fa0(x,y,z) = ODF(x,y,d(1))-min_odf(x,y);
                index0(x,y,z) = d(1)-1;
            else
                fa0(x,y,z) = 0;
                index0(x,y,z) = 0;
            end;

            if length(d) > 1
                fa1(x,y,z) = ODF(x,y,d(2))-min_odf(x,y);
                index1(x,y,z) = d(2)-1;
            end

            if length(d) > 2
                fa2(x,y,z) = ODF(x,y,d(3))-min_odf(x,y);
                index2(x,y,z) = d(3)-1;
            end
       
            if length(d) > 3
                fa3(x,y,z) = ODF(x,y,d(4))-min_odf(x,y);
                index3(x,y,z) = d(4)-1;
            end            
        end
    end
    clear p
            
end

max_dif=max(max_dif(:));

fa0 = reshape(fa0/max_dif,1,[]);
fa1 = reshape(fa1/max_dif,1,[]);
fa2 = reshape(fa2/max_dif,1,[]); 
fa3 = reshape(fa3/max_dif,1,[]); 

index0 = reshape(index0,1,[]);
index1 = reshape(index1,1,[]);
index2 = reshape(index2,1,[]);
index3 = reshape(index3,1,[]);

dimension =dim;

% flipping
dir = odf_vertices;
if FlipFlag_X==1
   dir(1,:) = dir(1,:)*-1; 
end
if FlipFlag_Y==1
   dir(2,:) = dir(2,:)*-1; 
end
if FlipFlag_Z==1
   dir(3,:) = dir(3,:)*-1; 
end
odf_vertices = dir;

save([op '/' opname '.fib'],'dimension','voxel_size','fa0','fa1','fa2','fa3','index0','index1','index2','index3','odf_vertices','odf_faces','-v4');

end
