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


function [I1out, low, high] = normalize_intensity(I1, percentile_range, I1_mask)
% Normalize images in range [0, 1]. The upper and lower cutoff intensities are decided by percentile
% as given in PERCENTILE_RANGE (0-100) inside the Mask (if specified)

percentile_range = percentile_range/100;
I1 = double(I1);

if ~exist('I1_mask','var')
   I1_mask = true(size(I1));
else
   I1_mask = I1_mask>0;
end

I1_m = I1(I1_mask);

I1_m = sort(I1_m(:), 'ascend');
low = I1_m(max(floor(length(I1_m)*percentile_range(1)),1));
high = I1_m(ceil(length(I1_m)*percentile_range(2)));

if low==high
   I1out = ones(size(I1));
else
   I1out = double((I1-low)/(high-low));
   I1out(I1out<0) = 0;
   I1out(I1out>1) = 1;
end

end
