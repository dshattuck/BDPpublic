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


function [t_epi, M, O_trans, Spacing] = EPI_correct_files_registration_BDP17(epi_filename, struct_filename, epi_output_filename, ...
                                                                struct_output_filename, options)
% Estimates the distortion due to B0 field inhomogenity in EPI scans using
% one dimenstional non-rigid bspline registration.
%

% Check/set input options
defaultoptions = struct(...
   'similarity','mi', ...
   'rigid_similarity', 'bdp', ... 
   'struct_mask', [], ...
   'epi_mask', [], ...
   'pngout', true, ...
   'overlay_mode', 'redgreen',...  % 'rview'/'redgreen'/'greenblue'/'yellowblue'
   'reslice_to_static', false, ...
   'reg_res', 1.4,...
   'num_threads', 4, ...  % number of parallel processing threads to use
   'dense_grid', true,... % if the image should be sampled on dense grid
   'step_size', 10000, ...  % step size for gradient descent
   'step_size_scale_iter',0.85,... % for gradient descent
   'intensity_correct', true,...
   'MaxFunEvals', 10, ... % max number of gradient evaluation
   'phase_encode_direction', 'y-', ...
   'Penalty', [5e-4 1e-8 0], ...
   'debug', false, ...
   'verbose', true);


if(~exist('options','var')),
    options = defaultoptions;
else
    tags = fieldnames(defaultoptions);
    for i=1:length(tags)
        if(~isfield(options,tags{i})),  options.(tags{i})=defaultoptions.(tags{i}); end
    end
    if(length(tags)~=length(fieldnames(options))),
        warning('BDP:UnknownOptions', 'Unknown options found.');
    end
end

if length(options.reg_res)>1
   error('options.reg_res should be scalar');
end

workDir = tempname; %[pwd '/temp_workdir_' Random_String(10)];
mkdir(workDir);

temp_file = [workDir '/' Random_String(15)];
% overlay_init = [remove_extension(struct_filename) '.initial'];
overlay_rigid = [remove_extension(epi_filename) '.distorted'];
overlay_out = [remove_extension(epi_filename) '.corrected'];
workdir_struct_file = [workDir '/struct_moved.nii.gz'];
workdir_struct_mask = [workDir '/struct_moved_mask.nii.gz'];
workdir_epi_file =  [workDir '/epi.nii.gz'];
workdir_epi_mask =  [workDir '/epi_mask.nii.gz'];


% Global variables
global bins nthreads parzen_window_size;
bins = 200;
nthreads = options.num_threads; % no of threads to use for multithreading parts
parzen_window_size = 10;

global log_lookup1 scale1 range1;
global log_lookup2 scale2 range2;

load 'log_lookup.mat';
scale1 = ones(bins*bins,1)/range1(1);
scale2 = ones(2*bins, 1)/range2(1);


% = = = = = = set/load masks = = = = = = = %
disp('Loading data...')

% extract b=0 image from diffusion images
dwi = load_untouch_nii_gz(epi_filename);
if dwi.hdr.dime.dim(1) > 3
   dwi.img = dwi.img(:,:,:,1);
   dwi.hdr.dime.dim(1) = 3;
   dwi.hdr.dime.dim(5) = 1;
   epi_b0_filename = save_untouch_nii_gz(dwi, [remove_extension(epi_filename) '.0_diffusion.nii.gz']);
else
   epi_b0_filename = epi_filename;
end
clear dwi

if isempty(options.epi_mask)
   options.epi_mask = [remove_extension(epi_b0_filename) '.mask.nii.gz'];
   mask_head_pseudo(epi_b0_filename, options.epi_mask);
   copyfile(options.epi_mask, workdir_epi_mask);
else
   interp3_nii(options.epi_mask, epi_b0_filename, workdir_epi_mask, 'nearest');
end


% = = = = Initial rigid registration = = = = %
reg_options = struct( ...
   'moving_mask', options.struct_mask, ...
   'static_mask', workdir_epi_mask, ...
   'pngout', options.pngout, ...
   'verbose', options.verbose, ...
   'similarity', options.rigid_similarity, ...
   'dof', 6,... 
   'nthreads', options.num_threads);

[M_world, origin] = register_files_affine(struct_filename, epi_b0_filename, struct_output_filename, reg_options);
fprintf('Rigid registration done.\n')

% = = = = = = = = = EPI correction = = = = = = = = %
fprintf('Setting up data for non-rigid registration based distortion correction...')

if options.dense_grid
   options.reg_res = 0.6; % set dense grid
end

% % dilate structural mask to accomodate signal from CSF
% pix = 2;
% [x,y,z] = ndgrid(-pix:pix);
% se2 = (sqrt(x.^2 + y.^2 + z.^2) <=pix);
% struct_mask.img = imdilate(struct_mask.img>0, se2)>0;

% load EPI data, mask
epi_mask = load_untouch_nii_gz(workdir_epi_mask);
epi_data = load_untouch_nii_gz(epi_b0_filename, true, workDir);
epi_res = abs(epi_data.hdr.dime.pixdim(2:4));

struct_data = [remove_extension(struct_output_filename) '.headr_transform.nii.gz'];
struct_mask = affine_transform_nii(options.struct_mask, inv(M_world), origin);

% First interpolate at EPI grid 
[~, x_epi, y_epi, z_epi] = get_original_grid_data(epi_mask);
struct_data = myreslice_nii(struct_data, 'linear', x_epi, y_epi, z_epi);
struct_mask = myreslice_nii(struct_mask, 'nearest', x_epi, y_epi, z_epi);
struct_data(struct_mask<=0) = 0;
clear x_epi y_epi z_epi

% Interpolate data on dense grid (in epi plane)
grid_res = (options.reg_res)./epi_res; % units - voxels in EPI image
epi_size =  size(epi_mask.img);
dense_epi_res = options.reg_res*[1 1 1];

[X_dense_epi, Y_dense_epi, Z_dense_epi] = ndgrid(0:grid_res(1):(epi_size(1)-1), 0:grid_res(2):(epi_size(2)-1), 0:grid_res(3):(epi_size(3)-1));
[x_epi, y_epi, z_epi] = ndgrid(0:(epi_size(1)-1), 0:(epi_size(2)-1), 0:(epi_size(3)-1));
epi_data = interpn(x_epi, y_epi, z_epi, double(epi_data.img), X_dense_epi, Y_dense_epi, Z_dense_epi, 'linear', 0);
epi_mask = interpn(x_epi, y_epi, z_epi, double(epi_mask.img), X_dense_epi, Y_dense_epi, Z_dense_epi, 'nearest', 0);
struct_data = interpn(x_epi, y_epi, z_epi, double(struct_data), X_dense_epi, Y_dense_epi, Z_dense_epi, 'linear', 0);
struct_mask = interpn(x_epi, y_epi, z_epi, double(struct_mask), X_dense_epi, Y_dense_epi, Z_dense_epi, 'nearest', 0);
clear x_epi y_epi z_epi X_dense_epi Y_dense_epi Z_dense_epi

[bb_1, bb_2, bb_3] = find_bounding_box((epi_mask>0) | (struct_mask>0));
epi_mask = epi_mask(bb_1, bb_2, bb_3);
struct_mask = struct_mask(bb_1, bb_2, bb_3);

% Normalize images 
if options.similarity(1) == 's'
   [~, m_low, m_high] = normalize_intensity(epi_data(bb_1, bb_2, bb_3), [1 99.9], epi_mask);
   epiImg = double((epi_data(bb_1, bb_2, bb_3)-m_low)/(m_high-m_low));
   sImg = double((struct_data(bb_1, bb_2, bb_3)-m_low)/(m_high-m_low));
   sImg(sImg<0) = 0;
   epiImg(epiImg<0) = 0;
elseif options.similarity(1) == 'm'
   [~, lw, hg] = normalize_intensity(struct_data(bb_1, bb_2, bb_3), [0.01 99.9], struct_mask);
   sImg = double((struct_data(bb_1, bb_2, bb_3)-lw)/(hg-lw));
   [~, lw, hg] = normalize_intensity(epi_data(bb_1, bb_2, bb_3), [0.001 98.5], epi_mask);
   epiImg = double((epi_data(bb_1, bb_2, bb_3)-lw)/(hg-lw));
end
size_struct_data = size(struct_data);
clear epi_data m_low m_high lw hg struct_data

% permute data to make 1st dimension the phase encode dim of EPI
switch options.phase_encode_direction
   case {'x', 'x-'}
      permute_vec = [1 2 3 4];
   case {'y', 'y-'}
      permute_vec = [2 1 3 4];
   case {'z', 'z-'}
      permute_vec = [3 2 1 4];
   otherwise
      error('Unknown options.phase_encode_direction')
end

epiImg = permute(epiImg, permute_vec);
epi_mask = permute(epi_mask, permute_vec);
sImg = permute(sImg, permute_vec);
struct_mask = permute(struct_mask, permute_vec);
dense_epi_res = dense_epi_res(permute_vec(1:3));
grid_res_scale = permute(grid_res, permute_vec);

switch options.phase_encode_direction
   case {'x-', 'y-', 'z-'}
      epiImg = flipdim(epiImg, 1);
      epi_mask = flipdim(epi_mask, 1);
      sImg = flipdim(sImg, 1);
      struct_mask = flipdim(struct_mask, 1);
end


% Initial change in EPI mask to include regions which were removed due
% to distortion
epi_mask_mod = epi_mask>0 | struct_mask>0;
[epi_bb_1, epi_bb_2, epi_bb_3] = find_bounding_box(epi_mask>0);
temp = true(size(epi_mask));
temp(:,epi_bb_2, epi_bb_3) = false;
epi_mask_mod(temp) = 0; % throw away slices which are not in epi
clear struct_mask epi_mask epi_bb_1 epi_bb_2 epi_bb_3 temp

% registration
non_rigid_options = struct('Similarity', 'mi', ...
             'Penalty', options.Penalty, ... %: Thin sheet of metal smoothness penalty, default in 2D 1e-3 ,
             'Spacing', 2.^(round(log2(15./dense_epi_res))), ... % bspline control point spacing
             'Verbose', 0, ...
             'dense_grid', options.dense_grid, ...
             'step_size', options.step_size, ...
             'moving_mask', false, ...
             'step_size_scale_iter', options.step_size_scale_iter,...
             'intensity_correct', options.intensity_correct,...
             'MaxFunEvals', options.MaxFunEvals, ... 
             'debug', options.debug ...
             );
                     
if options.verbose
   non_rigid_options.Verbose = 2;
end
                     
% fix image size by padding zeros
input_size = size(epiImg);
pix_diff = ceil(input_size./non_rigid_options.Spacing).*non_rigid_options.Spacing +1 - input_size;
st_pix = floor(pix_diff/2)+1;
end_pix = st_pix + input_size - 1;

epiImgP = zeros(input_size + pix_diff);
sImgP = zeros(input_size + pix_diff);
non_rigid_options.MaskMoving = false(input_size + pix_diff);
non_rigid_options.MaskStatic = false(input_size + pix_diff);

epiImgP(st_pix(1):end_pix(1), st_pix(2):end_pix(2), st_pix(3):end_pix(3)) = epiImg; %epiImg_neg;
sImgP(st_pix(1):end_pix(1), st_pix(2):end_pix(2), st_pix(3):end_pix(3)) = sImg;
non_rigid_options.MaskMoving(st_pix(1):end_pix(1), st_pix(2):end_pix(2), st_pix(3):end_pix(3)) = (epi_mask_mod>0);
non_rigid_options.MaskStatic(st_pix(1):end_pix(1), st_pix(2):end_pix(2), st_pix(3):end_pix(3)) = (epi_mask_mod>0);
clear epiImg sImg input_size pix_diff epi_mask_mod

% Visualize input images
if options.pngout
   overlay_volumes2png(sImgP, epiImgP, [0 1], overlay_rigid, options.overlay_mode, [30 99]);
   overlay_volumes2png(epiImgP, sImgP, [0 1], [overlay_rigid '.edgeM'], 'edge');
   overlay_volumes2png(sImgP, epiImgP, [0 1], [overlay_rigid '.edgeD'], 'edge');
end

% Sigmoid correction
c = 2.3;
s = 2;
if options.pngout || options.debug 
   epiImgP_old = single(epiImgP); % save some memory
end
epiImgP = ((1./(1+exp(-epiImgP.*c)))-0.5).*s;
% sImgPS = ((1./(1+exp(-sImgP.*c)))-0.5).*s;
% epiImgS = ((1./(1+exp(-epiImg.*c)))-0.5).*s;
% sImgS = ((1./(1+exp(-sImg.*c)))-0.5).*s;
% sImgPS = sImgP;
% sImgPS(sImgP>1) = 1;

if options.debug   
   hist_bin = -0.25:0.005:3;
   figure; n = histc(epiImgP_old(non_rigid_options.MaskStatic>0), hist_bin);
   plot(hist_bin, n, '--g', 'LineWidth',2); hold on;
   n = histc(epiImgP(non_rigid_options.MaskStatic>0), hist_bin);
   plot(hist_bin, n, 'g', 'LineWidth',2); hold on;
   
   n = histc(sImgP(non_rigid_options.MaskStatic>0), hist_bin);
   plot(hist_bin, n, '--b', 'LineWidth',2); hold on;
   n = histc(sImgP(non_rigid_options.MaskStatic>0), hist_bin);
   plot(hist_bin, n, 'b', 'LineWidth',2); hold off;
   xlim([-0.25 2]); ylim([0 15e4]); title('Histogram (common mask)')
   legend('Original EPI','Sigmoid modified EPI', 'Original MRAGE','Sigmoid modified MPRAGE')
end
clear n c s hist_bin

fprintf('Done.\n')

global img_range; 
img_range = [0 1];

% Pseudo-invert the modality of epi
% pix = 3;
% [x,y,z] = ndgrid(-pix:pix);
% se1 = (sqrt(x.^2 + y.^2 + z.^2) <=pix);
% epi_errod_mask = imdilate(epiImgPS>0, se1)>0;
% epi_errod_mask = imerode(epi_errod_mask, se1)>0;
% se1(:,:,[1 2 3 5 6 7]) = 0;
% epi_errod_mask = imerode(epi_errod_mask, se1)>0;
% epiImgPS_neg = zeros(size(epiImgPS));
% epiImgPS_neg(epiImgPS>0 & (epiImgPS>0.35 | epi_errod_mask>0)) = 1-epiImgPS(epiImgPS>0 & (epiImgPS>0.35 | epi_errod_mask>0));

% opt.MaskMoving = sImgPS>0 | epiImgPS>0;
% opt.MaskStatic = sImgPS>0 | epiImgPS>0; 

% All positive inside the common mask 
% epiImgPS(opt.MaskMoving>0 & epiImgPS<0) = 0;
% sImgPS(opt.MaskStatic>0 & sImgPS<0) = 0;

disp('Non-rigid registration started...')

[~, O_trans, Spacing, M, B] = EPI_correct_bspline_registration(epiImgP, sImgP, dense_epi_res, non_rigid_options);

% Visualize output images - Apply transform to unscaled image (before sigmoid scaling)
if options.pngout
   t_x = B(:,:,:,1);
   [x_g, y_g, z_g] = ndgrid(1:size(epiImgP, 1), 1:size(epiImgP,2), 1:size(epiImgP,3));
   x_g = x_g + t_x;
   
   Ireg = interpn(epiImgP_old, x_g, y_g, z_g, 'linear', 0);
   
   if options.intensity_correct
      [~, crct_grd] = gradient(t_x,  dense_epi_res(1), dense_epi_res(2), dense_epi_res(3)); % to be replaced by analytical gradient
      Ireg = Ireg .* (1+crct_grd);
   end
   
   overlay_volumes2png(sImgP, Ireg, [0 1], overlay_out, options.overlay_mode, [30 99]);
   overlay_volumes2png(Ireg, sImgP, [0 1], [overlay_out '.edgeM'], 'edge');
   overlay_volumes2png(sImgP, Ireg, [0 1], [overlay_out '.edgeD'], 'edge');
end
clear  x_g y_g z_g crct_grd sImgP Ireg epiImgP epiImgP_old epiImgPS t_x
clear global log_lookup1
clear global log_lookup2
clear global scale1
clear global scale2

% t_x in original grid 
t_x = B(st_pix(1):end_pix(1), st_pix(2):end_pix(2), st_pix(3):end_pix(3),1);
clear B
switch options.phase_encode_direction
   case {'x-', 'y-', 'z-'}
      t_x = -1 * flipdim(t_x, 1); % multiplied by -1 to account for the flipping
end
t_x = permute(t_x, permute_vec);

t_x_dense = zeros(size_struct_data);
t_x_dense(bb_1, bb_2, bb_3) = t_x;
clear t_x B

[X_dense_epi, Y_dense_epi, Z_dense_epi] = ndgrid(0:grid_res(1):(epi_size(1)-1), 0:grid_res(2):(epi_size(2)-1), 0:grid_res(3):(epi_size(3)-1));
[x_epi, y_epi, z_epi] = ndgrid(0:(epi_size(1)-1), 0:(epi_size(2)-1), 0:(epi_size(3)-1));
t_epi = interpn(X_dense_epi, Y_dense_epi, Z_dense_epi, double(t_x_dense), x_epi, y_epi, z_epi, 'cubic', 0);
t_epi = grid_res_scale(1)*t_epi; % scale correctly to reflect displacement in original grid
clear t_x X_dense_epi Y_dense_epi Z_dense_epi x_epi y_epi z_epi

% transform original image and save
epi_orig = load_untouch_nii_gz(epi_filename, true, workDir);
epi_orig_res =  epi_orig.hdr.dime.pixdim(2:4);

[x_g, y_g, z_g] = ndgrid(1:size(epi_orig.img,1), 1:size(epi_orig.img,2), 1:size(epi_orig.img,3));
switch options.phase_encode_direction
   case {'x', 'x-'}
      x_g = x_g + t_epi;
      if options.intensity_correct
         [~, crct_grd] = gradient(t_epi,  epi_orig_res(1), epi_orig_res(2), epi_orig_res(3));
      end
   case {'y', 'y-'}
      y_g = y_g + t_epi;
      if options.intensity_correct
         [crct_grd] = gradient(t_epi,  epi_orig_res(1), epi_orig_res(2), epi_orig_res(3));
      end
   case {'z', 'z-'}
      z_g = z_g + t_epi;
      if options.intensity_correct
         [~, ~, crct_grd] = gradient(t_epi,  epi_orig_res(1), epi_orig_res(2), epi_orig_res(3));
      end
   otherwise
      error('options.phase_encode_direction has to be x/x-/y/y-/z/z-');
end

moving_out = epi_orig;
moving_out.img = zeros(size(epi_orig.img));
for k = 1:size(epi_orig.img,4)
   moving_out.img(:,:,:,k) = interpn(double(epi_orig.img(:,:,:,k)), x_g, y_g, z_g, 'cubic', 0);
   if options.intensity_correct
      moving_out.img(:,:,:,k) = moving_out.img(:,:,:,k) .* (1+crct_grd);
   end
end

% save corrected data
moving_out.hdr.dime.scl_slope = 0;
moving_out.hdr.dime.scl_inter = 0;
save_untouch_nii_gz(moving_out, epi_output_filename, workDir);

% save distortion map
moving_out.img = t_epi;
moving_out.hdr.dime.dim(1) = 3;
moving_out.hdr.dime.dim(5) = 1;
save_untouch_nii_gz(moving_out, [remove_extension(epi_output_filename) '.distortion.map.nii.gz'], 64, workDir);

rmdir(workDir, 's');

end


function [Ireg,O_trans,Spacing,M,B] = EPI_correct_bspline_registration(Imoving,Istatic,res,Options)
%
% Performs 1D non-linear registration for EPI distortion correction. First
% dimension of the input image should be the phase encode dimension.
%
% Inputs,
%   Imoving : The image which will be registerd
%   Istatic : The image on which Imoving will be registered
%   Options : Registration options, see help below
%
% Outputs,
%   Ireg : The registered moving image
%   Grid: The b-spline controlpoints, can be used to transform another
%       image in the same way: I=bspline_transform(Grid,I,Spacing);
%   Spacing: The uniform b-spline knot spacing
%	 M : The affine transformation matrix
%   B : The backwards transformation fields
%
% Options,
%   Options.Similarity: Similarity measure (error) used can be set to:
%               sd : Squared pixel distance
%               mi : Normalized (Local) mutual information
%   Options.Penalty: Thin sheet of metal smoothness penalty, default in 2D 1e-3 ,
%				default in 3D, 1e-5
%               if set to zero the registration will take a shorter time, but
%               will give a more distorted transformation field.
%   Options.Interpolation: Linear (default) or Cubic, the final result is
%               always cubic interpolated.
%   Options.Grid: Initial B-spline controlpoints grid, if not defined is initalized
%               with an uniform grid. 
%   Options.Spacing: Spacing of initial B-spline grid in pixels 1x2 [sx sy] or 1x3 [sx sy sz]
%               sx, sy, sz must be powers of 2, to allow grid refinement.
%   Options.MaskMoving: Imoving mask
%   Options.MaskStatic: Istatic mask
%   Options.Verbose: Display Debug information 0,1 or 2
%

% Disable warning
warning('off', 'MATLAB:maxNumCompThreads:Deprecated')

% Process inputs
defaultoptions = struct('Similarity',[], ...
                        'Penalty',1e-5,...
                        'MaxRef',2,...
                        'Grid',[],...
                        'Spacing',[],...
                        'MaskMoving',[],...
                        'MaskStatic',[],...
                        'Verbose',2,...
                        'Interpolation','Linear',...
                        'Scaling',[1 1 1],...
                        'dense_grid', false,... % if the image is sampled on dense grid
                        'step_size', 5e4, ...  % step size for gradient descent
                        'step_size_scale_iter',0.7,... % for gradient descent
                        'moving_mask', true,...
                        'intensity_correct', true,...
                        'MaxFunEvals', 10, ... % max number of gradient evaluation
                        'debug', false ...
                        );  


if(~exist('Options','var')), Options=defaultoptions;
else
   tags = fieldnames(defaultoptions);
   for i=1:length(tags),
      if(~isfield(Options,tags{i})), Options.(tags{i})=defaultoptions.(tags{i}); end
   end
   if(length(tags)~=length(fieldnames(Options))),
      warning('image_registration:unknownoption','unknown options found');
   end
end

% Set parameters
type = Options.Similarity;
O_trans = Options.Grid; 
Spacing = Options.Spacing;
MASKmoving = Options.MaskMoving; 
MASKstatic = Options.MaskStatic;

% Start time measurement
if Options.Verbose>0 
   t_corr = tic();
end

% Check similarity measure.
if(isempty(type)),
   error('Specify the type of images.');
end



% Register the moving image affine to the static image
% if(~strcmpi(Options.Registration(1),'N'))
%     M=affine_registration(O_trans,Spacing,Options,Imoving,Istatic,MASKmoving,MASKstatic,type,Points1,Points2,PStrength,IS3D);
% else M=eye(4);
% end

% Rigid registration
%M_rigid = rigid_registration(Imoving, Istatic, MASKmoving,MASKstatic, Options);
M=eye(4);
% global cst_err cst_reg  cst_penlty cst_grad cst_grad_reg cst_grad_penlty
% cst_err = []; cst_reg =[]; cst_penlty =[]; 
% cst_grad =[];cst_grad_reg =[]; cst_grad_penlty =[];



% Make the initial b-spline registration grid
[O_trans,Spacing,MaxItt] = Make_Initial_Grid(O_trans,Spacing,Options,Imoving, M);

% Register the moving image nonrigid to the static image
[O_trans,Spacing] = nonrigid_registration(O_trans, Spacing, Options, Imoving, Istatic, res, ...
                              MASKmoving, MASKstatic, type, MaxItt);


% Transform the input image with the found optimal grid.
[t_x, t_y, t_z] = bspline_phantom_endpoint_deformation(O_trans, size(Imoving), Spacing);
[x_g, y_g, z_g] = ndgrid(1:size(Imoving,1), 1:size(Imoving,2), 1:size(Imoving,3));
x_g = x_g + t_x;

B(:,:,:,1)=t_x; B(:,:,:,2)=t_y; B(:,:,:,3)=t_z;
Ireg = interpn(Imoving, x_g, y_g, z_g, 'cubic', 0);

if Options.intensity_correct
   [~, crct_grd] = gradient(t_x,  res(1), res(2), res(3));
   Ireg = Ireg.*(1+crct_grd);
end


% figure; plot(abs(cst_err), 'r'); hold on 
% plot(cst_reg, 'g'); hold on 
% plot(cst_penlty, 'b');
% title('error')
% figure; plot(cst_grad, 'r'); hold on 
% plot(cst_grad_reg, 'g'); hold on 
% plot(cst_grad_penlty, 'b');
% title('grad')


% End time measurement
if Options.Verbose>0
   disp(['Completed EPI_correct_bspline_registration() in ' num2str(toc(t_corr)) ' seconds.']);
   drawnow();
end

end

function [O_trans,Spacing,MaxItt]=Make_Initial_Grid(O_trans,Spacing,Options,Imoving,M)
if(isempty(O_trans)),
   
   if(isempty(Options.Spacing))
      % Calculate max refinements steps
      MaxItt=min(floor(log2(size(Imoving)/4)));
      
      % set b-spline grid spacing in x,y and z direction
      Spacing=[2^MaxItt 2^MaxItt 2^MaxItt];
   else
      % set b-spline grid spacing in x and y direction
      Spacing=round(Options.Spacing);
      t=Spacing; MaxItt=0; while((nnz(mod(t,2))==0)&&(nnz(t<4)==0)), MaxItt=MaxItt+1; t=t/2; end
   end
   
   % Make the Initial b-spline registration grid
   %O_trans=make_init_grid(Spacing,size(Imoving),M);
   O_trans = bspline_grid_generate(Spacing,size(Imoving),M);
   
else
   MaxItt=0;
   TestSpacing=Spacing;
   while(mod(TestSpacing,2)==0), TestSpacing=TestSpacing/2; MaxItt=MaxItt+1; end
   
   % Calculate center of the image
   mean=size(Imoving)/2;
   % Make center of the image coordinates 0,0
   xd=O_trans(:,:,:,1)-mean(1); yd=O_trans(:,:,:,2)-mean(2); zd=O_trans(:,:,:,3)-mean(3);
   % Calculate the rigid transformed coordinates
   O_trans(:,:,:,1) = mean(1) + M(1,1) * xd + M(1,2) *yd + M(1,3) *zd + M(1,4)* 1;
   O_trans(:,:,:,2) = mean(2) + M(2,1) * xd + M(2,2) *yd + M(2,3) *zd + M(2,4)* 1;
   O_trans(:,:,:,3) = mean(3) + M(3,1) * xd + M(3,2) *yd + M(3,3) *zd + M(3,4)* 1;
end
% Limit refinements steps to user input
if(Options.MaxRef<MaxItt), MaxItt=Options.MaxRef; end
end

function [O_trans,Spacing] = nonrigid_registration(O_trans, Spacing, options, Imoving, Istatic, res, MASKmoving, MASKstatic, type, MaxItt, x_rigid)
% Non-rigid b-spline grid registration
if(options.Verbose>0), disp('Start non-rigid EPI_correct_bspline_registrationgid b-spline grid registration'); drawnow; end

% set registration options.
reg_options = struct('type', type, ...
                     'penaltypercentage', options.Penalty, ...
                     'interpolation', options.Interpolation, ...
                     'scaling', options.Scaling, ...
                     'verbose', (options.Verbose>0), ...
                     'step', 0.1, ... % step for numerical gradient
                     'intensity_correct', options.intensity_correct, ...
                     'moving_mask', options.moving_mask);

if(strcmpi(type,'sd')), reg_options.centralgrad=false; end

% set optimization options (function minimization computation)
fmin_options = struct('GradObj','on', ...
                      'GoalsExactAchieve',0, ...
                      'StoreN',10, ...
                      'HessUpdate','lbfgs',...%,'steepdesc' ...
                      'Display','off', ...
                      'MaxIter',7, ...
                      'DiffMinChange',0.001, ...
                      'DiffMaxChange',1, ...
                      'MaxFunEvals',options.MaxFunEvals, ...
                      'TolX',1e-2, ...
                      'TolFun',1e-14, ...
                      'GradConstr', true, ...
                      'step_size', options.step_size, ...
                      'step_size_scale_iter', options.step_size_scale_iter);
                   
if(options.Verbose>0), fmin_options.Display='iter'; end

if(options.dense_grid)
   refine_flag = [ 0      1     0];
   blur_flag   = [ 1      1     0];
   blur_param  = [2.5     1     1];
   resize_scl  = [0.5    0.5    1];
else
   refine_flag = [ 0     0     1     0];
   blur_flag   = [ 1     1     1     0];
   blur_param  = [3     2.4   1.7    1];
   resize_scl  = [0.5    1    1     1];
end

for iter = 1:length(blur_flag)
   if blur_flag(iter) == 1
      Hsize = round(2*blur_param(iter))+1;
      ISmoving = imgaussian(Imoving,Hsize/5,[Hsize Hsize Hsize]);
      ISstatic = imgaussian(Istatic,Hsize/5,[Hsize Hsize Hsize]);
      fmin_options.step_size = options.step_size / (1.8^(iter-1));
   else
      ISmoving = Imoving; %imgaussian(Imoving, 0.5, 0.3*[1 1 1]);
      ISstatic = Istatic; %imgaussian(Istatic, 0.5, 0.3*[1 1 1]);
      fmin_options.step_size = 1e4;
      fmin_options.MaxFunEvals = 3;
   end
   
   if refine_flag(iter) == 1
      [O_trans,Spacing] = bspline_refine_grid(O_trans, Spacing, size(Imoving));
      %reg_options.penaltypercentage = reg_options.penaltypercentage*10;
   end
   
   if resize_scl(iter) ~= 1.0
      MASKmovingsmall = my_imresize3d(MASKmoving, resize_scl(iter), [], 'nearest')>0;
      MASKstaticsmall = my_imresize3d(MASKstatic, resize_scl(iter), [], 'nearest')>0;
      ISmoving_small = my_imresize3d(ISmoving, resize_scl(iter), [],'linear');
      ISstatic_small = my_imresize3d(ISstatic, resize_scl(iter), [],'linear');
   else
      MASKmovingsmall = MASKmoving;
      MASKstaticsmall = MASKstatic;
      ISmoving_small = ISmoving;
      ISstatic_small = ISstatic;
   end
   
   Spacing_small = Spacing*resize_scl(iter);
   O_trans = O_trans*resize_scl(iter);
   ISres = res/resize_scl(iter);
   
   if (options.Verbose>0),
      disp(['Current Grid size : ' num2str(size(O_trans,1)) 'x' num2str(size(O_trans,2)) 'x' num2str(size(O_trans,3)) ]); drawnow;
   end
   

   % Reshape O_trans from a matrix to a vector.
   O_trans1 = squeeze(O_trans(:,:,:,1));
   sizes1 = size(O_trans1);
   O_trans1 = O_trans1(:);

   % Start the b-spline nonrigid registration optimizer
%    O_trans1 = fminlbfgs(@(x)EPI_correct_bspline_registration_gradient(x, sizes1, O_trans, Spacing_small, ISmoving_small, ISstatic_small, ISres, ...
%                                                             MASKmovingsmall, MASKstaticsmall, reg_options), O_trans1, fmin_options);

   O_trans1 = gradient_descent(@(x)bspline_analytic_grad_MI_EPI_BDP17(x, sizes1, O_trans, Spacing_small, ISmoving_small, ISstatic_small, ISres, ...
                                                            MASKmovingsmall, MASKstaticsmall, reg_options), O_trans1, fmin_options);

   % Reshape O_trans from a vector to a matrix
   O_trans1 = reshape(O_trans1, sizes1);
   O_trans(:,:,:,1) = O_trans1;
   
   
   
   % save current output
   if options.debug
      [t_x, t_y, t_z] = bspline_phantom_endpoint_deformation(O_trans, size(ISmoving_small), Spacing_small);
      clear t_y t_z
      [x_g, y_g, z_g] = ndgrid(1:size(ISmoving_small,1), 1:size(ISmoving_small,2), 1:size(ISmoving_small,3));
      x_g = x_g + t_x;
      
      Ireg = interpn(ISmoving_small, x_g, y_g, z_g, 'linear', 0);
      
      if options.intensity_correct
         [~, crct_grd] = gradient(t_x,  ISres(1), ISres(2), ISres(3));
         Ireg = Ireg.*(1+crct_grd);
      end
      
      overlay_volumes2png(ISstatic_small, Ireg, [0 1], ['bspline' num2str(iter)]);
      clear crct_trsfm x_g y_g z_g t_x t_y t_z
      overlay_control_points2png(ISmoving_small, O_trans, Spacing_small, ['bspline-knots' num2str(iter)])
   end
   
   % control points in original size
   O_trans = O_trans/resize_scl(iter);
   
   fprintf('%d/%d iterations completed.\n', iter, length(blur_flag));
end
end
