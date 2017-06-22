% 
% BDP BrainSuite Diffusion Pipeline
% 
% Copyright (C) 2017 The Regents of the University of California and
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


function csvwriteBDP(fname, hdr, M, col1, col_end)
% csv writer for BDP stat files. Not a generic function - supports csv files
% in a structured manner. See csvreadBDP.
% 
%  -----------------------------------------------
%  |                    hdr                      |
%  ----------------------------------------------- 
%  |       :                           :         |
%  |       :                           :         |
%  |       :                           :         |
%  | col1  :                           :         |
%  |       :             M             : col_end |
%  |       :                           :         |
%  |       :                           :         |
%  |       :                           :         |
%  |       :                           :         |
%  -----------------------------------------------
%

sz = size(M);

if nargin<4
   col1 = cell(sz(1), 0);
   col_end = cell(sz(1), 0);
elseif nargin<5
   col_end = cell(sz(1), 0);
end

ncol = length(hdr);
if ncol~=(sz(2) + size(col1,2) + size(col_end,2))
   error('column size does not match hdr');
end

fid = fopen(fname, 'w');

% write header
fprintf(fid, '%s', hdr{1});
for c = 2:ncol
   fprintf(fid, ',%s', hdr{c});
end
fprintf(fid,'\n');


for r = 1:sz(1)
   temp_str = num2str(M(r,:),'%05.10f,');
   temp_str(end) = []; % throw away last comma
   
   if ~isempty(col1)
      temp_str = [col1{r} ',' temp_str];
   end
   
   if ~isempty(col_end)
      temp_str = [temp_str ',' col_end{r}];
   end
   
   fprintf(fid, '%s\n', temp_str);
end

fclose(fid);
end
