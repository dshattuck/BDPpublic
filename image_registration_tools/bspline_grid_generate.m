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


function O_trans = bspline_grid_generate(Spacing, sizeI, M)
% This function creates grid of control points for a uniform 3D b-spline. 
% 
% Inputs
%    Spacing: vector of length 3, representing space between adjacent control points (in unit of
%             voxels) along three dimensions of the image. 
%    sizeI: vector with the sizes of the image for which control point would be generated
%    M : The (inverse) transformation from rigid registration (defined wrt to the origin at the
%        center of the image)
%  
%  outputs,
%    O: control grid of Uniform b-spline 
%

if(length(Spacing)==2)
   error('This function does not support 2D grid points.')
else
    % Determine grid spacing
    dx = Spacing(1);
    dy = Spacing(2);
    dz = Spacing(3);
    
    if(mod(sizeI(1)-1,dx) + mod(sizeI(2)-1,dy) + mod(sizeI(3)-1,dz))~=0
       error('Size and spacing must be exact.');
    end
    
    % Calculate te grid coordinates (make the grid)
    [X,Y,Z] = ndgrid(0:dx:sizeI(1),0:dy:sizeI(2),0:dz:sizeI(3));    
    O_trans = cat(4, X, Y, Z);
    
    if(exist('M','var')),
        % Calculate center of the image
        mean = sizeI/2;

        % Make center of the image coordinates 0,0
        xd=O_trans(:,:,:,1)-mean(1); 
        yd=O_trans(:,:,:,2)-mean(2);
        zd=O_trans(:,:,:,3)-mean(3);

        % Calculate the rigid transformed coordinates
        O_trans(:,:,:,1) = mean(1) + M(1,1) * xd + M(1,2) *yd + M(1,3) *zd + M(1,4)* 1;
        O_trans(:,:,:,2) = mean(2) + M(2,1) * xd + M(2,2) *yd + M(2,3) *zd + M(2,4)* 1;
        O_trans(:,:,:,3) = mean(3) + M(3,1) * xd + M(3,2) *yd + M(3,3) *zd + M(3,4)* 1;
    end
end
    
    
