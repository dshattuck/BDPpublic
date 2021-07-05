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


function bdpPrintSectionHeader(hdr, wdt)
% Prints section header. For BDP command line outputs.

if ~exist('wdt', 'var')
   wdt = 80;
end
sep_str(1:wdt) = '=';
sz = length(hdr);

if sz <= wdt
   blk(1:floor((wdt-sz)/2)) = ' ';
   hdr = [blk hdr '\n'];
   
else % sz>wdt
   k = strfind(hdr(floor(sz/2):end), ' ');
   md = floor(sz/2)+k(1)-2;
   hdr1 = hdr(1:md);
   hdr2 = hdr(md+1:end);   
   
   blk1(1:floor((wdt-length(hdr1))/2)) = ' ';
   blk2(1:floor((wdt-length(hdr2))/2)) = ' ';
   
   hdr = [blk1 hdr1 '\n ' blk2 hdr2 '\n'];   
end

fprintf('\n%s\n', sep_str);
fprintf(hdr);
fprintf('%s\n', sep_str);

end
