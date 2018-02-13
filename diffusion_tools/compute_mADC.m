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


function adc = compute_mADC(dwi, DEout)
% dwi - dxn 2D matrix; d is number of diffusion weighting, n is number of voxels
% DEout - Output of checkDiffusionEncodingScheme()
% adc - mean ADC, 1xn

dwi = double(abs(dwi));
b0_mean = mean(dwi(DEout.zero_bval_mask,:), 1);

% throw away b=0 images
dwi = dwi(~DEout.zero_bval_mask,:);
bval = DEout.bval(~DEout.zero_bval_mask);

nDir = size(dwi, 1);
adc = zeros(size(b0_mean));
dwi_c = zeros(size(b0_mean)); % non_zero counter
for k = 1:nDir
   temp = abs(-1*log(dwi(k,:)./b0_mean)/bval(k));   
   msk = isfinite(temp);   
      
   % use only dwis which are >0 for stable estimate (& keep track of it)
   temp(~msk) = 0;
   dwi_c = dwi_c + double(msk);   
   adc = adc + temp;
end
adc(~isfinite(adc)) = 0;
adc = abs(adc)./dwi_c; % mean ADC

end
