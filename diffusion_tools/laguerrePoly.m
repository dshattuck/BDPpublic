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


% Calculates Generalized Laguerre polynomial
% Szeg�: Orthogonal Polynomials, 1958, (5.1.10)
function L = laguerrePoly(n,a,x)
l=zeros(n+1);          
if(n==0)
    l(1,:)=1;
else
    l(1,:)=[zeros(1,n), 1];
    l(2,:)=[zeros(1, n-1), -1, (a+1)];
    for i=3:n+1
        A1 = 1/(i-1) * (conv([zeros(1, n-1), -1, (2*(i-1)+a-1)], l(i-1,:)));
        A2 = 1/(i-1) * (conv([zeros(1, n), ((i-1)+a-1)], l(i-2,:)));
        B1=A1(length(A1)-n:1:length(A1));
        B2=A2(length(A2)-n:1:length(A2));
        l(i,:)=B1-B2;
     end;
end
L=polyval(l(n+1,:),x); 
