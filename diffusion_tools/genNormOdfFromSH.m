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


%Inputs:
%SHcoeff - Spherical harmonic coefficients that were stored by BDP
%oDir (optional) - ODF directions. Dimension - Nx3, where N is the number of ODF directions 
%Outputs:
% odf - This output contains the calculated ODF. ODF is a 4D matrix.
%    Size of ODF  = size of dwi vol x N.
% u - ODF directions
% This code assumes 45 coefficients (SH order 8).

function [odf, u] = genNormOdfFromSH(SHcoeff, oDir, nSH)

    sz=size(SHcoeff);
    
    %ODF directions
    if nargin<2,
        load('oDir_default.mat');
    else 
        u = oDir;
        clear oDir;
    end;
    
    % Spherical harmonic basis
    if nSH == 45
        HarmonicOrder = 8;
    else
        HarmonicOrder = 6;
    end;
    nu = size(u,1);
    [S,L] = sph_harm_basis([u(:,1),u(:,2),u(:,3)],HarmonicOrder,2);
    norm_odf = reshape(SHcoeff,[],nSH)*S';
    norm_odf = norm_odf./repmat(max(norm_odf,[],2),[1 size(S,1)]);
    norm_odf(isnan(norm_odf)) = 0;
    
    odf = reshape(norm_odf,sz(1),sz(2),sz(3),nu);

end
