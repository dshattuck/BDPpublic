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


% This function return the basis for GQI reconstruction
function [ basis ] = gqi_basis(sigma,l_delta,bval,qcart,pts,type,del_t)
if(size(qcart,1) == size(bval,1))
    sx = 1;
else
    sx = size(qcart,1);
end;

ld_ang = repmat(sqrt(bval*0.018),[sx size(pts',2)]); %0.01506

if(type == 1)
%      basis = repmat(Aq,[1 size(pts',2)])*l_delta.*sinc(sigma*ld_ang.*(qcart*pts')/pi);
    basis = sinc(sigma*ld_ang.*(qcart*pts')/pi);
else
    Aq = 4*pi*bval/(4*pi^2*del_t);
    x=sigma*ld_ang.*(qcart*pts');
    basis = (2*x.*cos(x) + (x .* x - 2).*sin(x))./(x.^3); %*x.*x);
    basis(x == 0) = 1/3;
    basis = (l_delta.^3)*repmat(Aq,[1 size(basis,2)]).*basis;
    
end;
end

