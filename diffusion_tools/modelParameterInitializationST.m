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


function [D,V] = modelParameterInitializationST(nDir,nParam,nIso)
      
%Eigen vectors
u = electrostatic_repulsion(nDir-2);  % generateIPEDdirSingleShell(nDir-2,1);
u = squeeze(u);
u = [u;1 0 0;0 1 0];
% h = displayDiffusionDirections(u);
%     saveas(h,[dataloc 'eigen_vector_dir_N' num2str(nDir)]);
    
u = squeeze(u);
for nu = 1:nDir,
    null_u = null(u(nu,:));
    V(:,:,nu) = [u(nu,:)' null_u];
    % Check orthonormality
    A =  V(:,:,nu)'* V(:,:,nu);
    if sum(sum(A - eye(size(A,1)) < 1e-3)) ~= 9
        disp('ST Warning - eigen vector direction does not look orthonormal. Check images.')
    end
   %[V(:,:,nu) r e] = qr([u(nu,:);0 1 0; 1 0 0]');
end;


%Diffusion tensor matrix
for nu = 1:nDir,
    e1_aniso = 0.6+0.8*rand(nParam-nIso, 1);
    e2_aniso =  0.1 +0.2*rand(nParam-nIso, 1);
    e1_iso =  1 + 2*rand(nIso, 1);

    E1(:,nu) = [e1_aniso;e1_iso];
    E2(:,nu) = [e2_aniso;e1_iso];
    E3(:,nu) = [e2_aniso;e1_iso];

    for num = 1:nParam,
        E = [E1(num,nu) 0 0; 0 E2(num,nu) 0;0 0 E3(num,nu)]*10^-3; % mm^2/sec  
        D(:,:,num,nu) = V(:,:,nu)*E*V(:,:,nu)';
    end;
end;

Dmat = D;
D = reshape(D,[3,3,nDir*nParam]);
end
