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


function A_erfo = calcErfoTx(u,snr,qdir,bval,del_t)
disp('Preparing ERFO ODF training model... This may take a few minutes.')
%% Data Model
Ndir = 150;
Nparam = 3400; %250; %5000; %100;%
Niso = 25; % odf isbi :25;
D = modelParameterInitializationST(Ndir,Nparam,Niso);

%% Analytical ODF
type=2;
odf = gauss_dti_odf(D,[],u,type)';

%% Choosing parameters - eliminating ~0 tensors
for np = 1:Nparam*Ndir,
e = eig(D(:,:,np));
if min(e) > 1e-4,
e_ind(np)=1;
else
e_ind(np) = 0;
end;
end;
ind = find(e_ind == 1);
D = D(:,:,ind);
odf = odf(ind,:);
Nparam_actual = length(ind);
clear e_ind; clear ind; clear np;

%% Noise 
sigma1 = (1/snr);

%% Q-space
qn = repmat(sqrt(bval/(4*pi^2*del_t)),[1 size(qdir,2)]).*qdir;

%% Optimization
lambda = 1; %:0.1:2; %4.45*10^8; %linspace(1,1.3,5);
Eq = gauss_dti_Eq(D,del_t,qn)';
disp('Training model loaded');
disp('Beginning ERFO Training');
A_erfo = [Eq;lambda*sigma1*sqrt(Nparam_actual)*eye(size(qn,1))]\[odf;zeros(size(qn,1),size(u,1))];
disp('Training Done');
end
