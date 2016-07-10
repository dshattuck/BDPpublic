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


function [R, N] = shore_odf_factor(zeta,rad_ord)
    ind = 1;
    cz = 2*(4*pi^2*zeta)^1.5;
    for n = 0:rad_ord, %Radial order
        nInd = 1;
        for l = 0:2:n, % Ang order
            for m = -l:l,
                % The analytical formula of the integral : Eq C.2, Merlet,
                % 2013
                R(:,ind) = (((-1)^(n - l/2))/cz)*(((cz*factorial(n-l))/gamma(n+1.5))^0.5)*((gamma(l/2+1.5)*gamma(n+1.5))/(gamma(l+1.5)*factorial(n-l)))*(0.5^(-l/2 - 1.5))*(HyperGeometric2F1([-n+l,l/2 + 1.5],l+1.5,2));
                  %R(:,ind) = (((-1)^(n - l/2))/cz)*(((cz*factorial(n-l))/gamma(n+1.5))^0.5)*((gamma(l/2+1.5)*gamma(n+1.5))/(gamma(l+1.5)*factorial(n-l)))*(0.5^(-l/2 - 1.5))*(taylora2f1(-n+l,0,l/2 + 1.5,0,l+1.5,0,2,0,1e-6));
                N(ind) = nInd;
                ind = ind+1;
                nInd = nInd+1;
            end;
        end;
    end;
%     basis = repmat(R,[size(Snew,1),1]).*Snew; 
end
