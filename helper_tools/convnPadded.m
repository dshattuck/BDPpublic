% 
% BDP BrainSuite Diffusion Pipeline
% 
% Copyright (C) 2019 The Regents of the University of California and
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


function C = convnPadded(A, B)
% Applies replicate padding before convolution. Output is same size as A.

padsize = (size(B)-1)/2;
padsize_pre = floor(padsize);
padsize_post = ceil(padsize);

A_padded = padarray(A, padsize_pre, 'replicate', 'pre');
A_padded = padarray(A_padded, padsize_post, 'replicate', 'post');

C = convn(A_padded, B, 'valid');

end
