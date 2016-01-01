% 
% BDP BrainSuite Diffusion Pipeline
% 
% Copyright (C) 2015 The Regents of the University of California and
% the University of Southern California
% 
% Created by Chitresh Bhushan, Justin P. Haldar, Anand A. Joshi, David W. Shattuck, and Richard M. Leahy
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


function CompileBDPMexFiles()

current_directory = pwd;

%% Demon Registration
cd(['..' filesep 'external_tools' filesep '+demon_registration']);
mex -v affine_transform_3d_double.c image_interpolation.c;
mex -v imgaussian.c;
cd(current_directory)

%% B-Spline Registration
cd(['..' filesep 'external_tools' filesep 'b-spline_registration' filesep 'functions']);
mex -v imgaussian.c;
% mex -v maxNumCompThreads.c;
mex -v squared_difference_double.c;
mex -v squared_difference_single.c;
cd(current_directory)

cd(['..' filesep 'external_tools' filesep 'b-spline_registration' filesep 'functions_affine']);
mex -v affine_transform_3d_double.c image_interpolation.c;
cd(current_directory);

%% image_registration_tools
cd(['..' filesep 'image_registration_tools']);
mex -v bspline_phantom_endpoint_deformation_3d_double.c image_interpolation.c;
mex -v mutual_histogram_parzen_multithread_double.c;
mex -v mutual_histogram_parzen_variable_size_multithread_double.c;
mex -v histogram_parzen_variable_size_multithread_double.c
mex -v bspline_phantom_endpoint_deformation_3d_double_only_x.c
mex -v affine_transform_3dvol_double.c image_interpolation.c;
mex -v bspline_repeated_endpoint_deformation_3d_double_only_x.c;
mex -v bspline_repeated_endpoint_deformation_3d_double_only_x_gradient.c;

cd(current_directory);

end
