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


function Dodf = gauss_dti_odf(D,delta,r,type)
for nparam = 1:size(D,3)
    if(type == 1) % radial projection
        Dodf(:,nparam) = (sum(r*inv(D(:,:,nparam)).*r,2)).^(-1/2)./(8*pi*delta*sqrt(det(D(:,:,nparam))));    %1/Z*sqrt(pi*delta) , Z: normalization constant % tuch 2004
    else
        Dodf(:,nparam) = (sum(r*inv(D(:,:,nparam)).*r,2)).^(-3/2)./(4*pi*sqrt(det(D(:,:,nparam)))); % check ODF
    end;
end;
end
