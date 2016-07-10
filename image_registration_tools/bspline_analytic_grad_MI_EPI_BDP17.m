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


function [O_error, O_error_grad] = bspline_analytic_grad_MI_EPI_BDP17(O_grid1, Osize1, O_grid, Spacing, Imv, Ist, res, maskImv, maskIst, options)
% Function registration_gradient. This function will calculate a registration
% error value and gradient after b-spline non-rigid registration
% of two images / volumes.
%
% inputs,
%   O_grid1: (Unknown variable) x-coordinate of b-spline control grid
%                              (reshaped to one long vector.)
%   Osize1: size of O_grid1 - to reshape O_grid1 to matrix format.
%   O_grid: b-spline control grid (x-coordinate is dummy and is overwritten
%                                  by O_grid1)
%   Spacing: The spacing in x,y,z direction of the b-spline grid knots
%   Imv, Ist: Moving and static input images (must have same size)
%   res: resolution (mm) per voxel in x,y,z direction (vector of length 3)
% 
%   options: Struct with options
%       type: Type of image similarity(error) measure used
%               (see image_difference.m) (default 'sd')
%       penaltypercentage Percentage of penalty smoothness (bending energy
%               of thin sheet of metal) (default 0.01)
%       step: Delta step used for error gradient (default 0.01)
%       centralgrad: Calculate derivatives with central instead of forward
%               gradient (default true)
%       interpolation Type of interpolation used, linear (default) or
%               cubic.
%       scaling: Scaling of dimensions 1x2 or 1x3 (like mm/px), to
%               be used in smoothness penalty
%       verbose : Display information (default false)
%   MaskImv: Mask for Imv (transformed in the same way as Imv)
%   MaskIst: Mask for Ist
%
% outputs,
%   O_error: The registration error value
%   O_error_grad: The registration error gradient
%


% Check/set input options
defaultoptions = struct('type','sd', ...
                        'penaltypercentage',0.01, ...
                        'step',0.01, ...
                        'centralgrad',true, ...
                        'interpolation','linear', ...
                        'scaling', res, ...
                        'verbose', false, ...
                        'intensity_correct', true, ...
                        'moving_mask', true);
                     
if(~exist('options','var')),
   options=defaultoptions;
else
   tags = fieldnames(defaultoptions);
   for i=1:length(tags)
      if(~isfield(options,tags{i})),  options.(tags{i})=defaultoptions.(tags{i}); end
   end
   if(length(tags)~=length(fieldnames(options))),
      warning('EPI_correct_bspline_registration_gradient:unknownoption','unknown options found');
   end
end

% Check if there is any Mask input
if(~exist('maskImv','var') || ~exist('maskIst','var'))
   error('EPI_correct_bspline_registration_gradient:No_mask','Masks are required for registation')
end


type = options.type;   % Type of image similarity(error) measure used
penaltypercentage = options.penaltypercentage; % Percentage of penalty smoothness (bending energy of thin sheet of metal)
step = options.step;  % Delta step used for error gradient
centralgrad = options.centralgrad;  % Central gradient or (faster) forward gradient

% Interpolation used linear or cubic
if(strcmpi(options.interpolation(1),'l')), interpolation_mode=0; else interpolation_mode=2; end

% Convert Grid vector to grid matrix
O_grid1 = reshape(O_grid1,Osize1);
O_grid(:,:,:,1) = O_grid1;


% Calculate penalty smoothness (bending energy of thin sheet of metal)
if(max(penaltypercentage)>0)
   if ( nargout > 1 )
      [SO_error, SO_grad] = bspline_penalty_metal_bending_EPI(O_grid, size(Imv), options.scaling, penaltypercentage);
   else
      SO_error = bspline_penalty_metal_bending_EPI(O_grid, size(Imv), options.scaling, penaltypercentage);
   end
end



% Transform (& intensity correct) Imv & MaskImv with the b-spline transformation
[t_x, t_y, t_z] = bspline_phantom_endpoint_deformation(O_grid, size(Imv), Spacing);
clear t_y t_z

[x_g, y_g, z_g] = ndgrid(1:size(Imv,1), 1:size(Imv,2), 1:size(Imv,3));
x_g = x_g + t_x;


if (options.intensity_correct)
   [~, crct_grd] = gradient(t_x,  res(1), res(2), res(3)); % to be replaced by analytical gradient
   Imv_w = interpn(Imv, x_g, y_g, z_g, 'linear', 0);
   Imv_t = Imv_w .* (1+crct_grd);
   if (nargout==1), clear Imv_w crct_grd; end
   
else
   Imv_t = interpn(Imv, x_g, y_g, z_g, 'linear', 0);
   
end
clear t_x


if options.moving_mask
   maskImv_t = interpn(single(maskImv), x_g, y_g, z_g, 'linear', 0)>0;
else
   maskImv_t = maskImv;
end
clear x_g y_g z_g

% Calculate the current registration error
if(strcmpi(type,'mi'))
   %    [O_error, log_hist_mv, log_hist_st, log_hist12, MI_num, MI_den] = registration_error_mutual_info(Imv, Ist, maskImv_t, ...
   %                                                                                         maskIst, t_x, res, options.intensity_correct);
   [O_error, log_hist_mv, log_hist_st, log_hist12, MI_num, MI_den] = registration_error_mutual_info(Imv_t, Ist, maskImv_t, ...
                                                              maskIst);

else
   O_error = registration_error_squared_differences(Imv_t, Ist, maskImv_t, maskIst);
end


% if(options.verbose)
%    disp(['Error' num2str(O_error)]);
%    disp(['Smoothness Error' num2str(SO_error)]);
% end

% global cst_err cst_reg  cst_penlty cst_grad cst_grad_reg cst_grad_penlty

% Add penalty to total error
if(max(penaltypercentage)>0),
   O_error = O_error + SO_error;
%    cst_reg(end+1) = SO_error;
%    cst_penlty(end+1) = SO_error;
end
% cst_err(end+1) = O_error;

% determine the gradient.
if ( nargout > 1 )
   
   if strcmpi(type, 'mi')
      if (options.intensity_correct)
         O_error_grad = registration_gradient_mutual_info_intensity_correct(Spacing, res, Ist, Imv_t, Imv_w, crct_grd, size(O_grid), maskIst, maskImv_t,...
                                                                             log_hist_mv, log_hist12, MI_num, MI_den);
      else
         O_error_grad = registration_gradient_mutual_info(Spacing, res, Ist, Imv_t, size(O_grid), maskIst, maskImv_t,...
                                                                  log_hist_mv, log_hist12, MI_num, MI_den);
      end
      
   else
      O_error_grad = error_gradient3d(Spacing, Imv, Ist, res, Imv_t, O_grid, maskImv, maskIst, maskImv_t,...
         interpolation_mode, step, centralgrad, type);
   end
   
%    if(options.verbose)
%       disp(['Abs Mean Error Gradient' num2str(mean(abs(O_error_grad(:))))]);
%       disp(['Abs Max  Error Gradient' num2str(max(abs(O_error_grad(:))))]);
%       disp(['Abs Max  Smoothness Gradient' num2str(max(abs(SO_grad(:))))]);
%       disp(['Abs Mean Smoothness Gradient' num2str(mean(abs(SO_grad(:))))]);
%    end
   
   
   % Add smoothness penalty gradient
   if(max(penaltypercentage)>0)
      O_error_grad = O_error_grad + SO_grad;
      %       cst_grad_reg(end+1) = mean(abs(SO_grad(:)));
      %       cst_grad_penlty(end+1) = mean(abs(SO_grad(:)));
   end
   
   %    cst_grad(end+1) = mean(abs(O_error_grad(:)));
   
   O_error_grad = O_error_grad(:);
else
   %    cst_grad(end+1) = cst_grad(end);
   %    if ~isempty(cst_grad_reg)
   % %       cst_grad_reg(end+1) = cst_grad_reg(end);
   % %       cst_grad_penlty(end+1) = cst_grad_penlty(end);
   %    end
end

end

function [regAx,regAy,regAz,regBx,regBy,regBz]=regioninfluenced3D(i,j,k,O_uniform,sizeI)
% Calculate pixel region influenced by a grid node
irm=i-2; irp=i+2;
jrm=j-2; jrp=j+2;
krm=k-2; krp=k+2;
irm=max(irm,1); jrm=max(jrm,1); krm=max(krm,1);
irp=min(irp,size(O_uniform,1)); jrp=min(jrp,size(O_uniform,2)); krp=min(krp,size(O_uniform,3));

regAx=O_uniform(irm,jrm,krm,1);
regAy=O_uniform(irm,jrm,krm,2);
regAz=O_uniform(irm,jrm,krm,3);
regBx=O_uniform(irp,jrp,krp,1);
regBy=O_uniform(irp,jrp,krp,2);
regBz=O_uniform(irp,jrp,krp,3);

if(regAx>regBx), regAxt=regAx; regAx=regBx; regBx=regAxt; end
if(regAy>regBy), regAyt=regAy; regAy=regBy; regBy=regAyt; end
if(regAz>regBz), regAzt=regAz; regAz=regBz; regBz=regAzt; end

regAx=max(regAx,1); regAy=max(regAy,1); regAz=max(regAz,1);
regBx=max(regBx,1); regBy=max(regBy,1); regBz=max(regBz,1);
regAx=min(regAx,sizeI(1)); regAy=min(regAy,sizeI(2)); regAz=min(regAz,sizeI(3));
regBx=min(regBx,sizeI(1)); regBy=min(regBy,sizeI(2)); regBz=min(regBz,sizeI(3));
end

%
% Note :
%   Control points only influence their neighbor region. Thus when calculating
%   the gradient with finited difference, multiple control points (with a spacing
%   between them of 4) can be moved in one finite difference deformation step, and
%   only the pixels in the neigbourhood of a control point  are used to calculate
%   the finite difference.
%
function O_grad = error_gradient3d(Spacing, I1, I2, res, I_init, O_grid, maskI1, maskI2, mask_init, ...
                                   interpolation_mode, step, centralgrad,type)
%O_uniform = make_init_grid(Spacing,size(I1));
O_uniform = bspline_grid_generate(Spacing,size(I1),eye(4));
O_grad = zeros(size(O_grid(:,:,:,1)));

for zi=0:(4-1),
   for zj=0:(4-1),
      for zk=0:(4-1),
         O_gradpx=O_grid;
         if(centralgrad)
            O_gradmx=O_grid;
         end
         
         %Set grid movements of every fourth grid node.
         for i=(1+zi):4:size(O_grid,1),
            for j=(1+zj):4:size(O_grid,2),
               for k=(1+zk):4:size(O_grid,3),
                  O_gradpx(i,j,k,1)=O_gradpx(i,j,k,1)+step;
                  if(centralgrad)
                     O_gradmx(i,j,k,1)=O_gradmx(i,j,k,1)-step;
                  end
               end
            end
         end

         % Transform (& intensity correct) Imv & MaskImv with the b-spline transformation
         [t_x, t_y, t_z] = bspline_phantom_endpoint_deformation(O_gradpx, size(I1), Spacing);
         [x_g, y_g, z_g] = ndgrid(1:size(I1,1), 1:size(I1,2), 1:size(I1,3));
         x_g = x_g + t_x;
         
         [~, crct_grd] = gradient(t_x,  res(1), res(2), res(3)); % to be replaced by analytical gradient
         I_gradpx = interpn((1+crct_grd).*I1, x_g, y_g, z_g, 'linear', 0);
         mask_gradpx = interpn(single(maskI1), x_g, y_g, z_g, 'nearest', 0)>0;

         if(centralgrad)
            error('This should never appear')
            %             [t_x, t_y, t_z] = bspline_phantom_endpoint_deformation(O_gradmx, size(I1), Spacing);
            %             [~, crct_grd] = gradient(t_x,  res(1), res(2), res(3));
            %             crct_trsfm(:,:,:,1) = t_x;
            %             crct_trsfm(:,:,:,2) = t_y;
            %             crct_trsfm(:,:,:,3) = t_z;
            %             I_gradmx = movepixels(I1./(1-crct_grd), crct_trsfm,interpolation_mode);
            %             mask_gradmx = movepixels(single(maskI1), crct_trsfm,interpolation_mode)>0;
         end
         
         for i=(1+zi):4:size(O_grid,1),
            for j=(1+zj):4:size(O_grid,2),
               for k=(1+zk):4:size(O_grid,3),
                  
                  if(strcmpi(type,'mi'))
                     [regAx,regAy,regAz,regBx,regBy,regBz] = regioninfluenced3D(i,j,k,O_uniform,size(I1));
                     MaskNum = numel(I1);

                     % Determine the registration error due to local change in region
                     I_gradpx_local = I_init; 
                     mask_gradpx_local = mask_gradpx;
                     I_gradpx_local(regAx:regBx,regAy:regBy,regAz:regBz) = I_gradpx(regAx:regBx,regAy:regBy,regAz:regBz);
                     mask_gradpx_local(regAx:regBx,regAy:regBy,regAz:regBz) = mask_gradpx(regAx:regBx,regAy:regBy,regAz:regBz);
                     E_gradpx = image_difference_mask(I_gradpx_local, I2, 'mi', mask_gradpx_local, maskI2, MaskNum);
                     
                     if(centralgrad)
                        I_gradmx_local = I_init;
                        mask_gradmx_local = mask_gradmx;
                        I_gradmx_local(regAx:regBx,regAy:regBy,regAz:regBz) = I_gradmx(regAx:regBx,regAy:regBy,regAz:regBz);
                        mask_gradmx_local(regAx:regBx,regAy:regBy,regAz:regBz) = mask_gradmx(regAx:regBx,regAy:regBy,regAz:regBz);
                        E_gradmx = image_difference_mask(I_gradmx_local, I2, 'mi', mask_gradmx_local, maskI2, MaskNum);
                     else
                        E_grid = image_difference_mask(I_init, I2, 'mi', mask_init, maskI2, MaskNum);
                     end
                     
                     % Calculate the error registration gradient.
                     if(centralgrad)
                        O_grad(i,j,k,1) = (E_gradpx-E_gradmx)/(step*2);
                     else
                        O_grad(i,j,k,1) = (E_gradpx-E_grid)/step;
                     end
                     
                  else % have to fix mask thing for else part
                     [regAx,regAy,regAz,regBx,regBy,regBz] = regioninfluenced3D(i,j,k,O_uniform,size(I1));

                     % Determine the registration error in the region
                     E_gradpx =  registration_error_squared_differences(I_gradpx(regAx:regBx,regAy:regBy,regAz:regBz), ...
                               I2(regAx:regBx,regAy:regBy,regAz:regBz),mask_gradpx(regAx:regBx,regAy:regBy,regAz:regBz), ...
                               maskI2(regAx:regBx,regAy:regBy,regAz:regBz));
                     
                     % Mask some regions from the registration error measure
                     E_grid =  registration_error_squared_differences(I_init(regAx:regBx,regAy:regBy,regAz:regBz),...
                               I2(regAx:regBx,regAy:regBy,regAz:regBz),mask_init(regAx:regBx,regAy:regBy,regAz:regBz), ...
                               maskI2(regAx:regBx,regAy:regBy,regAz:regBz));
    
                     % Calculate the error registration gradient.
                     O_grad(i,j,k,1) = (E_gradpx-E_grid)/step;

                  end
               end
            end
         end
      end
   end
end

end


function err = registration_error_squared_differences(V,U,VMask,UMask)
msk = VMask>0 | UMask>0;
img_diff_sq = (V(msk)-U(msk)).^2;
err = sum(img_diff_sq(:));

end


function [err, log_histV, log_histU, log_histVU, MI_num, MI_den] = registration_error_mutual_info(Imv, Ist, maskImv, ...
                                                                                       maskIst, t_x, res, intensity_correct)
% registration error based on normalized mutual information. Estimates
% joint pdf  using cubic b-spline parzen window.
%
%      err = (H(V) + H(U)) / H(V,U)
% 

global bins nthreads img_range; %=128;

if isempty(bins), bins = 128; end
if isempty(nthreads), nthreads = 4; end
if isempty(img_range), img_range = [0 1]; end

range = img_range;


Mask = maskImv>0 & maskIst>0;
clear maskImv maskIst

Um = Ist(Mask);
Vm = Imv(Mask);
clear Ist Imv Mask

% num_jit = 10;
% [x_g, y_g, z_g] = ndgrid(1:size(Imv,1), 1:size(Imv,2), 1:size(Imv,3));
% histVU = zeros(bins, bins);
% for jit_i = 1:num_jit
%    jit = rand(size(t_x))-0.5; % jitter to remove interpolation artifact
%    Txg = t_x + jit;
%    
%    if (intensity_correct)
%       [~, crct_grd] = gradient(t_x,  res(1), res(2), res(3)); % to be replaced by analytical gradient
%       Imv_t = interpn((1+crct_grd).*Imv, (Txg+x_g), y_g, z_g, 'nearest', 0);
%    else
%       Imv_t = movepixels(Imv, crct_trsfm, 0);
%    end
%    
%    Vm = Imv_t(Mask);
%    
%    histVU = histVU + mutual_histogram_parzen_multithread_double(double(Vm), double(Um), double(range(1)), double(range(2)), double(bins), double(nthreads));
% end
% histVU = double(histVU/num_jit);

histVU = mutual_histogram_parzen_multithread_double(double(Vm), double(Um), double(range(1)), double(range(2)), double(bins), double(nthreads));
histVU = double(histVU);
clear Vm Um

histV = double(sum(histVU, 1));
histU = double(sum(histVU, 2));


% Calculate fast log (lookup table)
global log_lookup1 scale1 range1 ;
global log_lookup2 scale2 range2 ;

log_histVU = zeros(size(histVU));
ind_0 = (histVU<range1(1));
log_histVU(ind_0) = log(range1(1));
ind_1 = (histVU<=range1(2)) & ~ind_0;
ind_2 = (histVU>range1(2));
ind = histVU(ind_1).*scale1(ind_1);
log_histVU(ind_1) = log_lookup1(uint32(ind));
log_histVU(ind_2) = log(histVU(ind_2)); % outside lookup table

histV_histU = [histV(:); histU(:)];
log_histV_histU = zeros(size(histV_histU));
ind_0 = (histV_histU<range2(1));
log_histV_histU(ind_0) = log(range2(1));
ind_1 = (histV_histU<=range2(2)) & ~ind_0;
ind_2 = (histV_histU>range2(2));
ind = histV_histU(ind_1).*scale2(ind_1);
log_histV_histU(ind_1) = log_lookup2(uint32(ind));
log_histV_histU(ind_2) = log(histV_histU(ind_2)); % outside lookup table

log_histV = log_histV_histU(1:bins);
log_histU = log_histV_histU(bins+1:end);

p1log = histV(:) .* log_histV(:);
p2log = histU(:) .* log_histU(:);
p12log = histVU .* log_histVU;

% Calculate amount of Information
MI_num = sum(p1log) + sum(p2log);
MI_den = sum(p12log(:));

% Studholme, Normalized mutual information
if(MI_den==0)
   MI_den = eps;   
   %error('check this case.') 
end

err = -1*(MI_num/MI_den);
end



function O_grad = registration_gradient_mutual_info(Spacing, res, Ist_in, Imv_t_in, O_grid_size, MaskIst, MaskImv_t,...
                             log_hist_mv, log_hist12, MI_num, MI_den)
%                          
% Calculates the analytical gradient of (-ve) mutual information (w.r.t.
% uniform cubic bspline control points) 
%
% Does NOT include intensity correction terms.
%
% ONLY calculates the gradient for x-coordinated of control points. 
%


global bins nthreads img_range;

if isempty(bins), bins = 128; end
if isempty(img_range), img_range = [0 1]; end

mask = (MaskImv_t>0 & MaskIst>0);
clear MaskImv_t MaskIst
[~, Gx] = gradient(Imv_t_in, res(1), res(2), res(3));
clear Gy Gz
Gx = Gx(mask);

Ist = Ist_in(mask)*((bins-1)/(img_range(2)-img_range(1)));
Imv_t = Imv_t_in(mask)*((bins-1)/(img_range(2)-img_range(1)));
clear Ist_in Imv_t_in

h_Ist = zeros([length(Ist) 4]);
d_h_Imv = zeros([length(Ist) 4]);
h_Ist_index = zeros([length(Ist) 4], 'int16');
d_h_Imv_index = zeros([length(Ist) 4], 'int16');

for m = 1:4
   m_bin = m-1;
   
   Ist_msk = logical(mod(floor((Ist-m_bin)/2), 2));
   Ist_p = mod(Ist-m_bin, 2);
   Ist_p(Ist_msk) = Ist_p(Ist_msk)-2;
   Ist_p = abs(Ist_p);
   
   Imv_msk = logical(mod(floor((Imv_t-m_bin)/2), 2));
   Imv_p = mod(Imv_t-m_bin, 2);
   Imv_p(Imv_msk) = Imv_p(Imv_msk)-2;
   Imv_p = -1*Imv_p;
   
   h_Ist_m = zeros(size(Ist_p));
   d_h_Imv_m = zeros(size(Ist_p));
   
   msk = Ist_p<1;
   h_Ist_m(msk) = 0.5*(Ist_p(msk).^3) - Ist_p(msk).^2 + 2/3;
   h_Ist_m(~msk) = Ist_p(~msk).^2 - (Ist_p(~msk).^3)/6 - 2*Ist_p(~msk) + 4/3;
   
   msk = abs(Imv_p)<1;
   d_h_Imv_m(msk) = (3/2)*(abs(Imv_p(msk)).^2) - 2*abs(Imv_p(msk));
   d_h_Imv_m(~msk) = (-0.5)*(abs(Imv_p(~msk)).^2) + 2*abs(Imv_p(~msk)) - 2;
   d_h_Imv_m(Imv_p<0) = -1*d_h_Imv_m(Imv_p<0);
   
   h_Ist_index_m = m_bin + 4*floor((Ist+2-m_bin)/4);
   d_h_Imv_index_m = m_bin + 4*floor((Imv_t+2-m_bin)/4);
   
   msk = (Ist-m_bin)<0 | (Ist-m_bin+2)>=bins;
   h_Ist_m(msk) = 0; % not included 
   h_Ist_index_m(msk) = 1; % dummy, not included 
   
   msk = (Imv_t-m_bin)<0 | (Imv_t-m_bin+2)>=bins;
   d_h_Imv_m(msk) = 0; % not included 
   d_h_Imv_index_m(msk) = 1;  % dummy, not included 
   
   h_Ist(:,m) = h_Ist_m;
   d_h_Imv(:,m) = d_h_Imv_m;
   h_Ist_index(:,m) = h_Ist_index_m + 1; 
   d_h_Imv_index(:,m) = d_h_Imv_index_m + 1;
end
clear Imv_t Ist

% Remove out of index indices, if any
msk = (d_h_Imv_index>bins) | (d_h_Imv_index<0);
d_h_Imv_index(msk) = 1; % dummy, not included 
d_h_Imv(msk) = 0; % not included 

msk = (h_Ist_index>bins) | (h_Ist_index<0);
h_Ist_index(msk) = 1; % dummy, not included 
h_Ist(msk) = 0; % not included 

clear d_h_Imv_m d_h_Imv_index_m h_Ist_m h_Ist_index_m msk Ist_p Imv_p Imv_msk Ist_msk


O_grad = zeros(O_grid_size(1:3));

temp1 = 0:(1/Spacing(1)):1;
temp1 = 0.5*(temp1.^3) - (temp1.^2) + 4/6;
temp2 = (1-(1/Spacing(1))):(-1/Spacing(1)):0;
temp2 = (temp2.^3)/6;
Bu = [temp1 temp2];

temp1 = 0:(1/Spacing(2)):1;
temp1 = 0.5*(temp1.^3) - (temp1.^2) + 4/6;
temp2 = (1-(1/Spacing(2))):(-1/Spacing(2)):0;
temp2 = (temp2.^3)/6;
Bv = [temp1 temp2];

temp1 = 0:(1/Spacing(3)):1;
temp1 = 0.5*(temp1.^3) - (temp1.^2) + 4/6;
temp2 = (1-(1/Spacing(3))):(-1/Spacing(3)):0;
temp2 = (temp2.^3)/6;
Bw = [temp1 temp2];

xmin = -2*Spacing(1);
xmax = 2*Spacing(1)-1;

ymin = -2*Spacing(2);
ymax = 2*Spacing(2)-1;

zmin = -2*Spacing(3);
zmax = 2*Spacing(3)-1;

[bx, by, bz] = ndgrid((xmin:xmax), (ymin:ymax), (zmin:zmax));
b_prod = Bu(abs(bx)+1) .* Bv(abs(by)+1) .* Bw(abs(bz)+1);
clear bx by bz Bu Bv Bw O_grid1 temp1 temp2

b_prod = repmat(b_prod, floor(O_grid_size(1:3)/4));


[p1, p2] = ndgrid(1:4,1:4);
p1 = p1(:);
p2 = p2(:);

% 1st term of gradient
d_P1 = (sum(log_hist_mv(d_h_Imv_index).*d_h_Imv, 2) .* sum(h_Ist, 2)) * MI_den; %/npixels;

% 2nd term of gradient
linearInd = sub2ind([bins bins], d_h_Imv_index(:,p1), h_Ist_index(:,p2));
d_P2 = (sum(log_hist12(linearInd) .* d_h_Imv(:,p1) .* h_Ist(:,p2), 2)) * MI_num; %/npixels;
clear log_hist_mv log_hist12 d_h_Imv_index d_h_Imv h_Ist linearInd h_Ist_index h_Ist p2 p1

mask_size = size(mask);


for x=1:4
   for y=1:4
      for z=1:4 
         
         bspline_prod = circshift(b_prod, ([x y z]-3).*Spacing);
         pixs_rem = ((mod(O_grid_size(1:3), 4)-1).*Spacing) + 1;
         pixs_rem(pixs_rem<0) = 0;
         bspline_prod(end+1:end+pixs_rem(1), :, :) = bspline_prod(1:pixs_rem(1), :, :);
         bspline_prod(:, end+1:end+pixs_rem(2), :) = bspline_prod(:, 1:pixs_rem(2), :);
         bspline_prod(:, :, end+1:end+pixs_rem(3)) = bspline_prod(:, :, 1:pixs_rem(3));
         
         d_Imv_control_point = Gx .* bspline_prod(mask);       
         d_P = zeros(mask_size);
         d_P(mask) = (d_P1-d_P2) .* d_Imv_control_point;
         
         clear bspline_prod d_Imv_control_point
         
         for m = x:4:O_grid_size(1)
            for n = y:4:O_grid_size(2)
               for k = z:4:O_grid_size(3)
                  
                  loc = ([m n k]-1).*Spacing+1;
                  
                  xmin = max(1, loc(1)-2*Spacing(1));
                  xmax = min(mask_size(1), loc(1)+2*Spacing(1));
                  
                  ymin = max(1, loc(2)-2*Spacing(2));
                  ymax = min(mask_size(2), loc(2)+2*Spacing(2));
                  
                  zmin = max(1, loc(3)-2*Spacing(3));
                  zmax = min(mask_size(3), loc(3)+2*Spacing(3));
                  
                  t = false(mask_size);
                  t(xmin:xmax, ymin:ymax, zmin:zmax) = true;
                  
                  O_grad(m,n,k) = sum(d_P(t));
               end
            end
         end
         
         %          temp = registration_gradient_mutual_info_last_loop_multithread(d_P, O_grid_size, Spacing, size(d_P), [x y z],  nthreads);
         %          O_grad = O_grad + temp;
      end
   end
end

O_grad = O_grad.*(bins/(sum(mask(:))*MI_den^2));

end


function O_grad = registration_gradient_mutual_info_intensity_correct(Spacing, res, Ist_in, Imv_t_in, Imv_w_in, crct_grd, O_grid_size, ...
                                                                      MaskIst, MaskImv_t, log_hist_mv, log_hist12, MI_num, MI_den)
%                          
% Calculates the analytical gradient of (-ve) mutual information (w.r.t.
% uniform cubic bspline control points) 
%
% ONLY calculates the gradient for x-coordinated of control points. 
%


global bins nthreads img_range;

if isempty(bins), bins = 128; end
if isempty(img_range), img_range = [0 1]; end

mask = (MaskImv_t>0 & MaskIst>0);
clear MaskImv_t MaskIst

[~, Gx] = gradient(Imv_w_in, res(1), res(2), res(3));
clear Gy Gz
dTx_Gx = (1+crct_grd).*Gx;
dTx_Gx = dTx_Gx(mask);
Imv_w_in = Imv_w_in(mask);
clear Gx crct_grd

Ist = Ist_in(mask)*((bins-1)/(img_range(2)-img_range(1)));
Imv_t = Imv_t_in(mask)*((bins-1)/(img_range(2)-img_range(1)));
clear Ist_in Imv_t_in

h_Ist = zeros([length(Ist) 4]);
d_h_Imv = zeros([length(Ist) 4]);
h_Ist_index = zeros([length(Ist) 4], 'int16');
d_h_Imv_index = zeros([length(Ist) 4], 'int16');

for m = 1:4
   m_bin = m-1;
   
   Ist_msk = logical(mod(floor((Ist-m_bin)/2), 2));
   Ist_p = mod(Ist-m_bin, 2);
   Ist_p(Ist_msk) = Ist_p(Ist_msk)-2;
   Ist_p = abs(Ist_p);
   
   Imv_msk = logical(mod(floor((Imv_t-m_bin)/2), 2));
   Imv_p = mod(Imv_t-m_bin, 2);
   Imv_p(Imv_msk) = Imv_p(Imv_msk)-2;
   Imv_p = -1*Imv_p;
   
   h_Ist_m = zeros(size(Ist_p));
   d_h_Imv_m = zeros(size(Ist_p));
   
   msk = Ist_p<1;
   h_Ist_m(msk) = 0.5*(Ist_p(msk).^3) - Ist_p(msk).^2 + 2/3;
   h_Ist_m(~msk) = Ist_p(~msk).^2 - (Ist_p(~msk).^3)/6 - 2*Ist_p(~msk) + 4/3;
   
   msk = abs(Imv_p)<1;
   d_h_Imv_m(msk) = (3/2)*(abs(Imv_p(msk)).^2) - 2*abs(Imv_p(msk));
   d_h_Imv_m(~msk) = (-0.5)*(abs(Imv_p(~msk)).^2) + 2*abs(Imv_p(~msk)) - 2;
   d_h_Imv_m(Imv_p<0) = -1*d_h_Imv_m(Imv_p<0);
   
   h_Ist_index_m = m_bin + 4*floor((Ist+2-m_bin)/4);
   d_h_Imv_index_m = m_bin + 4*floor((Imv_t+2-m_bin)/4);
   
   msk = (Ist-m_bin)<0 | (Ist-m_bin+2)>=bins;
   h_Ist_m(msk) = 0; % not included 
   h_Ist_index_m(msk) = 1; % dummy, not included 
   
   msk = (Imv_t-m_bin)<0 | (Imv_t-m_bin+2)>=bins;
   d_h_Imv_m(msk) = 0; % not included 
   d_h_Imv_index_m(msk) = 1;  % dummy, not included 
   
   h_Ist(:,m) = h_Ist_m;
   d_h_Imv(:,m) = d_h_Imv_m;
   h_Ist_index(:,m) = h_Ist_index_m + 1; 
   d_h_Imv_index(:,m) = d_h_Imv_index_m + 1;
end
clear Imv_t Ist
% Remove out of index indices, if any
msk = (d_h_Imv_index>bins) | (d_h_Imv_index<0);
d_h_Imv_index(msk) = 1; % dummy, not included 
d_h_Imv(msk) = 0; % not included 

msk = (h_Ist_index>bins) | (h_Ist_index<0);
h_Ist_index(msk) = 1; % dummy, not included 
h_Ist(msk) = 0; % not included 

clear d_h_Imv_m d_h_Imv_index_m h_Ist_m h_Ist_index_m msk Ist_p Imv_p Imv_msk Ist_msk


O_grad = zeros(O_grid_size(1:3));

% cubic bspline kernal (from basis function & reparameterized coord)
temp1 = 0:(1/Spacing(1)):1;
temp1 = 0.5*(temp1.^3) - (temp1.^2) + 4/6; % b_2(u)
temp2 = (1-(1/Spacing(1))):(-1/Spacing(1)):0;
temp2 = (temp2.^3)/6; % b_0(u)
Bu = [temp1 temp2];

temp1 = 0:(1/Spacing(2)):1;
temp1 = 0.5*(temp1.^3) - (temp1.^2) + 4/6;
temp2 = (1-(1/Spacing(2))):(-1/Spacing(2)):0;
temp2 = (temp2.^3)/6;
Bv = [temp1 temp2];

temp1 = 0:(1/Spacing(3)):1;
temp1 = 0.5*(temp1.^3) - (temp1.^2) + 4/6;
temp2 = (1-(1/Spacing(3))):(-1/Spacing(3)):0;
temp2 = (temp2.^3)/6;
Bw = [temp1 temp2];

% derivative of cubic bspline kernal (direct form, NOT from basis)
temp1 = 1/Spacing(1):(1/Spacing(1)):1;
temp1 = 1.5*(temp1.^2) - 2*temp1;
temp2 = (1-(1/Spacing(1))):(-1/Spacing(1)):0;
temp2 = -0.5*(temp2.^2);
dBu = [temp1 temp2];
dBu = [-1*dBu(end:-1:1) 0 dBu];

xmin = -2*Spacing(1);
xmax = 2*Spacing(1)-1;

ymin = -2*Spacing(2);
ymax = 2*Spacing(2)-1;

zmin = -2*Spacing(3);
zmax = 2*Spacing(3)-1;

[bx, by, bz] = ndgrid((xmin:xmax), (ymin:ymax), (zmin:zmax));
b_prod = Bu(abs(bx)+1) .* Bv(abs(by)+1) .* Bw(abs(bz)+1);
db_prod = (dBu(bx-xmin+1) .* Bv(abs(by)+1) .* Bw(abs(bz)+1))./Spacing(1);
clear bx by bz Bu Bv Bw O_grid1 temp1 temp2

b_prod = repmat(b_prod, floor(O_grid_size(1:3)/4));
db_prod = repmat(db_prod, floor(O_grid_size(1:3)/4));


[p1, p2] = ndgrid(1:4,1:4);
p1 = p1(:);
p2 = p2(:);

% 1st term of gradient
d_P1 = (sum(log_hist_mv(d_h_Imv_index).*d_h_Imv, 2) .* sum(h_Ist, 2)) * MI_den; %/npixels;

% 2nd term of gradient
linearInd = sub2ind([bins bins], d_h_Imv_index(:,p1), h_Ist_index(:,p2));
d_P2 = (sum(log_hist12(linearInd) .* d_h_Imv(:,p1) .* h_Ist(:,p2), 2)) * MI_num; %/npixels;
dP1_dP2_diff = (d_P1-d_P2);

clear log_hist_mv d_h_Imv_index d_h_Imv h_Ist h_Ist_index linearInd log_hist12 p1 p2 d_P1 d_P2

mask_size = size(mask);

for x=1:4
   for y=1:4
      for z=1:4 
         
         bspline_prod = circshift(b_prod, ([x y z]-3).*Spacing);
         pixs_rem = ((mod(O_grid_size(1:3), 4)-1).*Spacing) + 1;
         pixs_rem(pixs_rem<0) = 0;
         bspline_prod(end+1:end+pixs_rem(1), :, :) = bspline_prod(1:pixs_rem(1), :, :);
         bspline_prod(:, end+1:end+pixs_rem(2), :) = bspline_prod(:, 1:pixs_rem(2), :);
         bspline_prod(:, :, end+1:end+pixs_rem(3)) = bspline_prod(:, :, 1:pixs_rem(3));
         bspline_prod = bspline_prod(mask);
         
         dbspline_prod = circshift(db_prod, ([x y z]-3).*Spacing);
         pixs_rem = ((mod(O_grid_size(1:3), 4)-1).*Spacing) + 1;
         pixs_rem(pixs_rem<0) = 0;
         dbspline_prod(end+1:end+pixs_rem(1), :, :) = dbspline_prod(1:pixs_rem(1), :, :);
         dbspline_prod(:, end+1:end+pixs_rem(2), :) = dbspline_prod(:, 1:pixs_rem(2), :);
         dbspline_prod(:, :, end+1:end+pixs_rem(3)) = dbspline_prod(:, :, 1:pixs_rem(3));
         dbspline_prod = dbspline_prod(mask);
         
         d_Imv_control_point = (dTx_Gx .* bspline_prod) + (Imv_w_in.*dbspline_prod);       
         d_P = zeros(mask_size);
         d_P(mask) = dP1_dP2_diff .* d_Imv_control_point;
         clear bspline_prod dbspline_prod d_Imv_control_point
         
         for m = x:4:O_grid_size(1)
            for n = y:4:O_grid_size(2)
               for k = z:4:O_grid_size(3)
         
                  loc = ([m n k]-1).*Spacing+1;
                  
                  xmin = max(1, loc(1)-2*Spacing(1));
                  xmax = min(mask_size(1), loc(1)+2*Spacing(1));
                  
                  ymin = max(1, loc(2)-2*Spacing(2));
                  ymax = min(mask_size(2), loc(2)+2*Spacing(2));
                  
                  zmin = max(1, loc(3)-2*Spacing(3));
                  zmax = min(mask_size(3), loc(3)+2*Spacing(3));
                  
                  t = false(mask_size);
                  t(xmin:xmax, ymin:ymax, zmin:zmax) = true;
                  
                  O_grad(m,n,k) = sum(d_P(t));
               end
            end
         end
         
         
         %          temp = registration_gradient_mutual_info_last_loop_multithread(d_P, O_grid_size, Spacing, size(d_P), [x y z],  nthreads);
         %          O_grad = O_grad + temp;
      end
   end
end

O_grad = O_grad.*(bins/(sum(mask(:))*MI_den^2));
end


function O_grad = registration_gradient_mutual_info_slow(Spacing, Ist, res, Imv_t, O_grid, MaskIst, MaskImv_t,...
                             log_hist_mv, log_hist_st, log_hist12, MI_num, MI_den)
                          
global bins;

[Gy, Gx, Gz] = gradient(Imv_t, res(1), res(2), res(3));
G = -1 * cat(4, Gx, Gy, Gz);
clear Gy Gz Gx

Ist = Ist*(bins-1);
Ist(Ist<-1) = -1;
Ist(Ist>bins) = bins;

Imv_t = Imv_t*(bins-1);
Imv_t(Imv_t<-1) = -1;
Imv_t(Imv_t>bins) = bins;

mask = (MaskImv_t>0 & MaskIst>0);
npixels = sum(mask(:));

O_grid1 = O_grid(:,:,:,1);
O_grad = zeros(size(O_grid1));

temp1 = 0:(1/Spacing(1)):1;
temp1 = 0.5*(temp1.^3) - (temp1.^2) + 4/6;
temp2 = (1-(1/Spacing(1))):(-1/Spacing(1)):0;
temp2 = (temp2.^3)/6;
Bu = [temp1 temp2];

temp1 = 0:(1/Spacing(2)):1;
temp1 = 0.5*(temp1.^3) - (temp1.^2) + 4/6;
temp2 = (1-(1/Spacing(2))):(-1/Spacing(2)):0;
temp2 = (temp2.^3)/6;
Bv = [temp1 temp2];

temp1 = 0:(1/Spacing(3)):1;
temp1 = 0.5*(temp1.^3) - (temp1.^2) + 4/6;
temp2 = (1-(1/Spacing(3))):(-1/Spacing(3)):0;
temp2 = (temp2.^3)/6;
Bw = [temp1 temp2];

l_bins = bins;
for x=1:size(O_grid,1)
   for y=1:size(O_grid,2)
      for z=1:size(O_grid,3)
         xloc = (x-1)*Spacing(1)+1;
         yloc = (y-1)*Spacing(2)+1;
         zloc = (z-1)*Spacing(3)+1;
         
         xmin = max(1, xloc-2*Spacing(1));
         xmax = min(size(Ist, 1), xloc+2*Spacing(1));
         
         ymin = max(1, yloc-2*Spacing(2));
         ymax = min(size(Ist, 2), yloc+2*Spacing(2));
         
         zmin = max(1, zloc-2*Spacing(3));
         zmax = min(size(Ist, 3), zloc+2*Spacing(3));
         
         Ist_part = Ist(xmin:xmax, ymin:ymax, zmin:zmax);
         Imv_part = Imv_t(xmin:xmax, ymin:ymax, zmin:zmax);
         Gx_part = G(xmin:xmax, ymin:ymax, zmin:zmax, 1);
         mask_part = mask(xmin:xmax, ymin:ymax, zmin:zmax);
         
         [bx, by, bz] = ndgrid((xmin:xmax)-xloc, (ymin:ymax)-yloc, (zmin:zmax)-zloc);
         bspline_prod = Bu(abs(bx)+1) .* Bv(abs(by)+1) .*Bw(abs(bz)+1);
         
         d_P = zeros(l_bins, l_bins);
         
         for m = 1:l_bins
            for n = 1:l_bins
               clear msk Imv_p Ist_p Gx_p
               msk = (abs(Ist_part-m-1)<2) & (abs(Imv_part-n-1)<2) & mask_part;
               
               if any(msk(:))
                  Ist_p = abs(m-1-Ist_part(msk));
                  Imv_p = n-1-Imv_part(msk);
                  Gx_p = Gx_part(msk) .* bspline_prod(msk);
                  
                  h_Ist = zeros(size(Ist_p));
                  d_h_Imv = zeros(size(Ist_p));
                  
                  msk_m = Ist_p<1;
                  h_Ist(msk_m) = 0.5*(Ist_p(msk_m).^3) - Ist_p(msk_m).^2 + 2/3;
                  h_Ist(~msk_m) = Ist_p(~msk_m).^2 - (Ist_p(~msk_m).^3)/6 - 2*Ist_p(~msk_m) + 4/3;
                  
                  msk_n = abs(Imv_p)<1;
                  d_h_Imv(msk_n) = (3/2)*(abs(Imv_p(msk_n)).^2) - 2*abs(Imv_p(msk_n));
                  d_h_Imv(~msk_n) = (-0.5)*(abs(Imv_p(~msk_n)).^2) + 2*abs(Imv_p(~msk_n)) - 2;
                  d_h_Imv(Imv_p<0) = d_h_Imv(Imv_p<0)*-1;
                  
                  d_P(n,m) = sum(h_Ist .* d_h_Imv .* Gx_p)/npixels;
               end
            end
         end
         O_grad(x,y,z) = (MI_num*log_hist12(:)'*d_P(:) - MI_den*log_hist_mv(:)'*sum(d_P,2))/(MI_den^2);
      end
   end
end
 
end
