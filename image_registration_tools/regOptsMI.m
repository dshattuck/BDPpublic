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


function CFn_opts = regOptsMI(opts)
% returns options for NMI-registration as structure 

CFn_opts.nbins = opts.nbins;
CFn_opts.win_width = opts.parzen_width;
CFn_opts.nthreads = opts.nthreads;
CFn_opts.log_lookup = opts.log_lookup;
CFn_opts.log_thresh = opts.log_thresh;

if opts.log_lookup
   load('log_lookup.mat');
   CFn_opts.log_lookup1 = log_lookup1;
   CFn_opts.log_lookup2 = log_lookup2;
   CFn_opts.range1 = range1;
   CFn_opts.range2 = range2;
   CFn_opts.scale1 = ones(opts.nbins*opts.nbins,1)/range1(1);
   CFn_opts.scale2 = ones(2*opts.nbins, 1)/range2(1);
   clear log_lookup1 log_lookup2 range1 range2
end
end
