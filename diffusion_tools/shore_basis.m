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


% This function returns the SHORE basis.
function [ basis,R,Snew,N ] = shore_basis(qrad, qcart,rad_ord,zeta) 
    basis = [];
    % Angular part of the basis - Spherical harmonics
    [S,L] = sph_harm_basis(qcart,rad_ord,2);
    Snew=[];
    ind = 1;
    for n = 0:rad_ord, %Radial order
        nInd = 1;
        for l = 0:2:n, % Ang order
            Snew =[Snew S(:,L==l)];
            for m = -l:l,
                % Radial part
                R(:,ind) = ((2*factorial(n-l))/(zeta^1.5*gamma(n+1.5)))^(0.5)*(qrad.^2/zeta).^(l/2).*exp(-(qrad.^2)/(2*zeta)).*...
                    laguerrePoly(n-l,l+0.5,(qrad.^2/zeta));
                N(ind) = nInd;
                ind = ind+1;
                nInd = nInd+1;
            end;
        end;
    end;
    basis = R.*Snew;    
end
