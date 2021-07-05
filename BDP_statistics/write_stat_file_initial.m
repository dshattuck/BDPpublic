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


function write_stat_file_initial(stats_file_base, file_suffix)

ADC_fileID = fopen([stats_file_base '.mADC' file_suffix '.stat.csv'], 'w');
FA_fileID = fopen([stats_file_base '.FA' file_suffix '.stat.csv'], 'w');
MD_fileID = fopen([stats_file_base '.MD' file_suffix '.stat.csv'], 'w');
axial_fileID = fopen([stats_file_base '.axial' file_suffix '.stat.csv'], 'w');
radial_fileID = fopen([stats_file_base '.radial' file_suffix '.stat.csv'], 'w');
L2_fileID = fopen([stats_file_base '.L2' file_suffix '.stat.csv'], 'w');
L3_fileID = fopen([stats_file_base '.L3' file_suffix '.stat.csv'], 'w');
GFA_fileID = fopen([stats_file_base '.FRT_GFA' file_suffix '.stat.csv'], 'w');

init_str = ['ROI_ID,Missing voxels,Mean (GM+WM),Var (GM+WM),Used voxels (GM+WM),'...
   'Mean (WM),Var (WM),Used Voxels (WM),Mean (GM),Var (GM),Used voxels (GM),Comments\n'];

fprintf(ADC_fileID, init_str);
fprintf(MD_fileID, init_str);
fprintf(FA_fileID, init_str);
fprintf(axial_fileID, init_str);
fprintf(radial_fileID, init_str);
fprintf(L2_fileID, init_str);
fprintf(L3_fileID, init_str);
fprintf(GFA_fileID, init_str);


fclose(ADC_fileID);
fclose(FA_fileID);
fclose(MD_fileID);
fclose(axial_fileID);
fclose(radial_fileID);
fclose(L2_fileID);
fclose(L3_fileID);
fclose(GFA_fileID);

end
