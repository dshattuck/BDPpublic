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


function [ diagN ] = n_shore(radial_order )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

F = radial_order / 2;
n_c = round(1 / 6.0 * (F + 1) * (F + 2) * (4 * F + 3));
diagN = zeros(n_c,1);

counter = 1;
for n = 0:radial_order,
    for l = 0:2:n,
        for m = -l:l,
            diagN(counter) = (n * (n + 1))^2;
            counter = counter + 1;
        end;
    end;
end;
diagN=diag(diagN);

end

