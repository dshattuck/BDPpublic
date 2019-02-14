% 
% BDP BrainSuite Diffusion Pipeline
% 
% Copyright (C) 2019 The Regents of the University of California and
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


function [p0] = electrostatic_repulsion(N,ploton)
% generates the coordinates of N different points on the surface of the
% 2-sphere of radius 1, where the distribution of the points minimizes the
% Coulombic energy
ploton =0;
Nstep = max(round(1000*N/20),1000);
step = 0.01;
minimal_step=1e-10;

p0 = rand(N,3)*2-1;
p0 = p0./repmat(sqrt(sum(abs(p0).^2,2)),[1,3]);
p1 = zeros(N,3);
f = zeros(N,3);
pp0 = p0;
pp1 = p1;

e0 = get_coulomb_energy(p0,N);
for k= 1:Nstep
    f = get_forces(p0,N);
    d = diag(f*p0');
    f = f-repmat(d,[1,3]).*p0;
    p1 = p0+f*step;
    p1 = p1./repmat(sqrt(sum(abs(p1).^2,2)),[1,3]);
    e = get_coulomb_energy(p1,N);
    if (e >=e0)
        step = step/2;
        if (step < minimal_step)
            break;
        end
    else
        p0=p1;
        e0=e;
        step = step*2;
    end
    if ploton == 1
        plot3(p0(:,1),p0(:,2),p0(:,3),'.');axis equal;axis tight;drawnow
    end;
end
return;


function e = get_coulomb_energy(p,N)
e=0;
for i = 1:N
    for j=i+1:N
            e = e+ 2/norm(p(i,:)-p(j,:))+2/norm(p(i,:)+p(j,:));
    end
end
return;


function f = get_forces(p,N)
f = zeros(N,3);
for i = 1:N
    for j = i+1:N
        r = p(i,:)-p(j,:);
        l = 1/norm(r)^2;
        
        f(i,:) = f(i,:)+r*l;
        f(j,:) = f(j,:)-r*l;
        
        r = p(i,:)+p(j,:);
        l = 1/norm(r)^2;
        
        f(i,:) = f(i,:)+r*l;
        
        r = -p(i,:)-p(j,:);
        l = 1/norm(r)^2;
        
        f(j,:) = f(j,:)-r*l;
    end
end
return;
