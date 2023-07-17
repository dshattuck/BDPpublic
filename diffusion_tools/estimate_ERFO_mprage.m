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


  function estimate_ERFO_mprage(data_file, target_file, affinematrixfile, bMatrices, user_options)
% Computes ODFs using ERFO. Saves the output in BrainSuite friendly format. 
%
%  No eddy current or motion correction.
%
%  data_file - 4D nifti diffusion file name
%  target_file - bfc file name (this will be also used as mask)
%  affinematrixfile - file name of .mat file saved after rigid registration of diffusion and
%                     bfc file
%  bMatrices - .bmat file name or array of matrices (3x3xN)
%  user_options - optional input for Spherical harmonic parameters (See below for default options)

workdir = tempname;
mkdir(workdir);

% setting up the defaults options
opt = struct( ... 
   'HarmonicOrder', 8, ...
   'estimate_odf_ERFO', true, ...
   'diffusion_time', 2.5*10^-3, ...
   'snr', 35,...
   'ERFO_out_dir', fullfile(fileparts(data_file), 'ERFO'), ...
   'mprage_coord_suffix', '.T1_coord', ...
   'bval_ratio_threshold', 45, ...
   't1_mask_file', target_file, ...
   'save_fib', false, ...
   'run_dsi_studio', false, ...
   'dsi_path',[], ...
   'tracking_params', [] ...
    );

fprintf('\nEstimating ERFO ODFs in T1-coordinate...');

% set options using user_options
if exist('user_options', 'var')
   if isfield(user_options, 'file_base_name')
      opt.ERFO_out_dir = fullfile(fileparts(user_options.file_base_name), 'ERFO');
   end
   
   fnames = fieldnames(opt);
   for iname = 1:length(fnames)
      if isfield(user_options, fnames{iname})
         opt = setfield(opt, fnames{iname}, getfield(user_options, fnames{iname}));
      end
   end
end


fname = fileBaseName(data_file);
subname = fname;
ERFO_output_file_base = fullfile(opt.ERFO_out_dir, fname);
if opt.estimate_odf_ERFO && ~exist(opt.ERFO_out_dir, 'dir'), mkdir(opt.ERFO_out_dir); end

% Apply the rigid transform to header of dwi file
load(affinematrixfile);
data_file_transformed = fullfile(workdir, [Random_String(15) '.nii.gz']);
[~,Tnew] = affine_transform_nii(data_file, M_world, origin, data_file_transformed);
clear Tnew;

% load bmatrices
if ischar(bMatrices)
   bMatrices = readBmat(bMatrices);
end

% load data and corresponding grid points
[dataIn, ~, ~, ~, res_dwi, Tdwi] = get_original_grid_data(data_file_transformed);
[~, X_target, Y_target, Z_target, res_target, T_target] = get_original_grid_data(target_file);

dwi_vol_size = size(dataIn);
target_vol_size = size(X_target);
nDir = dwi_vol_size(4);

if nDir~=size(bMatrices, 3)
   error('BDP:InconsistentDiffusionParameters', ['Number of diffusion image should be exactly same' ...
      'as number of bMatrices/bvec (in .bmat/.bvec file, if any).']);
end

% Rotate bmatrices
for iDir = 1:nDir 
   Rmat = (T_target*diag(1./[res_target 1])) \ (Tdwi*diag(1./[res_dwi 1]));
   Rmat = Rmat(1:3, 1:3);
   bMatrices(:,:,iDir) = Rmat*bMatrices(:,:,iDir)*(Rmat');
end

% Find diffusion encoding direction (same as largest eigen vector of bMatrices)
DEout = checkDiffusionEncodingScheme(bMatrices, opt.bval_ratio_threshold);
ind = 1:nDir; %find(~DEout.zero_bval_mask);
q = zeros(numel(ind),3);
del_t = opt.diffusion_time;
for i = 1:numel(ind)
    [V,D] = eig(bMatrices(:,:,ind(i)));
    [maxb,tmp] = max(diag(D));
    q(i,:) = V(:,tmp);
    qrad(i) = sqrt(maxb/(4*pi^2*del_t));
    bval(i) = maxb;
end

% template 3D volume
vd = load_untouch_nii_gz(target_file,true);
temp3 = vd;
temp3.img = [];
temp3.hdr.dime.dim(1) = 3;
temp3.hdr.dime.dim(5) = 1;

vd = load_untouch_nii_gz(opt.t1_mask_file);
targetMask = vd.img>0;
clear vd

% dilate mask
% pix = 2;
% [x1,y1,z1] = ndgrid(-pix:pix);
% se2 = (sqrt(x1.^2 + y1.^2 + z1.^2) <=pix);
% targetMask = imdilate(targetMask>0, se2)>0;

% get location in original grid of datafile
c(1,:) = X_target(:); clear X_target;
c(2,:) = Y_target(:); clear Y_target;
c(3,:) = Z_target(:); clear Z_target;
c(4,:) = 1;
c = Tdwi\c;
X_dwi_target = reshape(c(1,:), target_vol_size);
Y_dwi_target = reshape(c(2,:), target_vol_size);
Z_dwi_target = reshape(c(3,:), target_vol_size);
clear c

% Voxel indexing starts from 0
[X_dwi, Y_dwi, Z_dwi] = ndgrid(0:dwi_vol_size(1)-1, 0:dwi_vol_size(2)-1,  0:dwi_vol_size(3)-1);

% ERFO Computation
HarmonicOrder = opt.HarmonicOrder;
lambda = 0.006;
snr = opt.snr;

% ERFO basis
erfoOdfBasis = calcErfoTx(q,snr,q,bval',del_t);
[S,L] = sph_harm_basis([q(:,1),q(:,2),q(:,3)],HarmonicOrder,2);
sphericalHarmonicMatrixReg = (S'*S+lambda*diag(L.^2.*(L+1).^2))\(S');

cpb = ConsoleProgressBar(); % Set progress bar parameters
cpb.setMinimum(1);     
cpb.setMaximum(target_vol_size(3)); 
cpb.start();
ivox = 0;
target_ind = [];
for slice = 1:target_vol_size(3)
   slice_z_coord = Z_dwi_target(:,:,slice);
   
   if max(slice_z_coord(:))>0 && min(slice_z_coord(:))<=dwi_vol_size(3)     
      msk = targetMask(:,:,slice);
      dwimages = zeros([sum(msk(:)) nDir]);
      
      % compute only inside mask
      X = X_dwi_target(:,:,slice);
      Y = Y_dwi_target(:,:,slice); 
      Z = Z_dwi_target(:,:,slice);
      
      X = X(msk);
      Y = Y(msk);
      Z = Z(msk);
      
      for iDir = 1:nDir
         dwimages(:,iDir) = interpn(X_dwi, Y_dwi, Z_dwi, double(dataIn(:,:,:,iDir)), X, Y, Z, 'linear', 0);
      end
      dwimages(~isfinite(dwimages))=0;

      % compute ERFO coefficients
      b0mean = mean(dwimages(:, DEout.zero_bval_mask),2);
      dwimages = dwimages(:, ind);      
      dwimages = dwimages./b0mean(:,ones(1,size(dwimages,2))); % normalize by b=0 image      
      dwimages(~isfinite(dwimages))=0;
      dwimages = permute(dwimages,[2,1]); % 1st dim is different diffusion weighting
      
	  odf = single(erfoOdfBasis'*dwimages);
	  odf(odf<0) = 0;
	  % Convert to SH coefficients
	  sh_erfo(:, ivox+1:ivox+size(dwimages,2)) = sphericalHarmonicMatrixReg*odf;
      
      msk_ind = find(msk);
      target_ind = [target_ind; msk_ind+(slice-1)*prod(target_vol_size(1:2))];
      ivox = ivox + size(dwimages,2);
   end
   
   text = sprintf('%d/%d slices done', slice, target_vol_size(3));
   cpb.setValue(slice); cpb.setText(text); 
end
cpb.stop();
fprintf('\n');
clear dwimages b0mean

erfo_fid = fopen([ERFO_output_file_base '.SH.ERFO' opt.mprage_coord_suffix '.odf'], 'w');
odf_fname = [subname '.SH.ERFO' opt.mprage_coord_suffix '.odf'];

disp('Writing ERFO ODF files to disk...')
temp3.img = zeros(target_vol_size);
for k = 1:size(sh_erfo,1),
    fname = sprintf('%s.SH.ERFO.%03d.nii.gz', ERFO_output_file_base, k);
    [~, name, ext] = fileparts(fname);
    fprintf(erfo_fid, '%s\n', [name, ext]);
    temp3.img(target_ind) = sh_erfo(k,1:length(target_ind));
    save_untouch_nii_gz(temp3, fname, 16);
end
fclose(erfo_fid);

if opt.save_fib
    disp('Writing ERFO ODF FIB files to disk...');
    op = [ opt.ERFO_out_dir '_FIB']; mkdir(op);
    opname = [subname '.SH.ERFO.FIB' opt.mprage_coord_suffix];
    bsOdfFibFileFAST(target_file,opt.ERFO_out_dir,odf_fname,'./',op,opname,0,0,1,targetMask);
end

if opt.run_dsi_studio & opt.save_fib
    if ~isempty(opt.dsi_path)
        disp('Running DSI studio');
    %     dsi_path = './dsi_studio_build';
        op = opt.ERFO_out_dir;
        opname = [subname '.SH.ERFO.TRK' opt.mprage_coord_suffix];
        fib_file = [opt.ERFO_out_dir '_FIB/' subname '.SH.ERFO.FIB' opt.mprage_coord_suffix '.fib'];
        DSI_tracking(fib_file, opt.tracking_params,opt.dsi_path,op,opname,opt);
    else
        msg = {'\n Skipping running tracking because DSI studio installation path is set to an empty string. Please check the installation path. You can re-run bdp with --tracking_only flag and run dsi studio tracking only.BDP will assume FIB file already exists and jump straight to tracking.', '\n'};
        fprintf(bdp_linewrap(msg));  
    end
end
rmdir(workdir, 's');
fprintf('Estimated ERFO ODFs written to disk.\n\n')
end
