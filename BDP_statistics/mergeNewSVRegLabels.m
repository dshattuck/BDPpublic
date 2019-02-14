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


function [out_file, lbl] = mergeNewSVRegLabels(input_label_file, output_label_file)
% Merges the sub-divided labels created by SVReg.
% New Cortical ROIs: 120 - 501
%                    1100 - 1501 (GM sub-division)
%                    2100 - 2501 (WM sub-division)
%
% Sub-cortical ROIs: 600-999
% White matter (cerebrum): 2000
%

lbl = load_untouch_nii_gz(input_label_file);

gm_msk = lbl.img>=1100 & lbl.img<=1501;
wm_msk = lbl.img>=2100 & lbl.img<=2501;

lbl.img(gm_msk) = lbl.img(gm_msk) - 1000;
lbl.img(wm_msk) = lbl.img(wm_msk) - 2000;

out_file = save_untouch_nii_gz(lbl, output_label_file);

end
