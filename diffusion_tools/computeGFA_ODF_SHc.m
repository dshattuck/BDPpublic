% 
% BDP BrainSuite Diffusion Pipeline
% 
% Copyright (C) 2016 The Regents of the University of California and
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


function GFA = computeGFA_ODF_SHc(c, Pf)
% Computes GFA from (modified) SH coefficients of ODFs.
% c  - first dim of c should be SH coefficients. SHc should be ordered 'naturally'. Other dim are spatial.
%
% Pf - scaling parameter for (SH coefficients of DWI-fit); Eg: 2*pi*P_k(0) term in eq(1) of the paper
%    below. Vector of same length as dim-1 of c. 
%
% GFA - computed GFA values. Length of first dim would be always 1. 
%
% J. Cohen-Adad et al., "Detection of multiple pathways in the spinal cord using q-ball imaging."
%      NeuroImage, 42 (2008): 739 - 749, DOI: http://dx.doi.org/10.1016/j.neuroimage.2008.04.243  
%

cSize = size(c);
c = reshape(c, cSize(1), []);
[nterms, nvox] = size(c);

% Normalize for scaling parameter - get SHc for DWI data fit
Pf = Pf(:);
c = c ./ Pf(:, ones(1, nvox));

% GFA
c = c.^2;
GFA = sqrt(1 - (c(1,:)./sum(c,1)));

GFA(~isfinite(GFA)) = 0;
GFA = reshape(GFA, [1 cSize(2:end)]);

end
