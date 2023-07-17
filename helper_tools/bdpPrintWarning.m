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


function bdpPrintWarning(hdr, msg, wdt)
% Prints warning on command line outputs.

if ~exist('wdt', 'var')
   wdt = 80;
end
sep_str(1:wdt) = '*';

hdr = ['WARNING : ' hdr];
sz = length(hdr);

if wdt>sz
   blk(1:ceil((wdt-sz)/2)) = ' ';
else
   blk = '';
end
hdr = ['*' blk hdr '\n'];
strout = bdp_linewrap(['*  ' msg], wdt-5, '\n*  ');

fprintf('\n%s\n', sep_str);
fprintf(hdr);
fprintf('*\n');
fprintf(strout);
fprintf('\n%s\n', sep_str);

end
