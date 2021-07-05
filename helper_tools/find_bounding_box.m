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


function [bb_1, bb_2, bb_3] = find_bounding_box(mask, pad_vox)
% Returns the indices representing bounding box of input 3D-mask. 
% pad_vox is the number of voxels to be padded around the actual bounding box. 

msk_stat = regionprops(mask>0 , 'BoundingBox'); % returns center of border voxels (outside the box) 
tmp_stat = zeros(size(msk_stat,1),6);
for k = 1:size(msk_stat,1)
   tmp_stat(k,:) = msk_stat(k).BoundingBox;
end
tmp_stat(:,4:6) = tmp_stat(:,1:3) + tmp_stat(:,4:6);
msk_stat = [min(tmp_stat(:,1:3),[],1) max(tmp_stat(:,4:6),[], 1)];

if exist('pad_vox', 'var')
   msk_stat = [max(ceil(msk_stat([2, 1, 3]) - pad_vox), 1) min(floor(msk_stat([5, 4, 6]) + pad_vox), size(mask))];
else
   msk_stat = [ceil(msk_stat([2, 1, 3])) min(floor(msk_stat([5, 4, 6])), size(mask))];
end

bb_1 = msk_stat(1):msk_stat(4);
bb_2 = msk_stat(2):msk_stat(5);
bb_3 = msk_stat(3):msk_stat(6);

end
