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


function run_tracking_only(data_file,opts)
if ~isempty(opts.dsi_path)    
    subname = fileBaseName(data_file);
    if opts.estimate_odf_ERFO
        disp('ERFO: Running DSI studio');
        opts.ERFO_out_dir = fullfile(fileparts(opts.file_base_name), 'ERFO');
        op = opts.ERFO_out_dir;
        opname = [subname '.SH.ERFO.TRK' opts.mprage_coord_suffix];
        fib_file = [opts.ERFO_out_dir '_FIB/' subname '.SH.ERFO.FIB' opts.mprage_coord_suffix '.fib'];
        DSI_tracking(fib_file, opts.tracking_params,opts.dsi_path,op,opname,opts);
    end
    if opts.estimate_odf_3DSHORE
        disp('3DSHORE: Running DSI studio');
        opts.SHORE_out_dir = fullfile(fileparts(opts.file_base_name), '3DSHORE');
        op = opts.SHORE_out_dir;
        opname = [subname '.SH.3DSHORE.TRK' opts.mprage_coord_suffix];
        fib_file = [opts.SHORE_out_dir '_FIB/' subname '.SH.3DSHORE.FIB' opts.mprage_coord_suffix '.fib'];
        DSI_tracking(fib_file, opts.tracking_params,opts.dsi_path,op,opname,opts);
    end
    if opts.estimate_odf_GQI
        disp('GQI: Running DSI studio');
        opts.GQI_out_dir = fullfile(fileparts(opts.file_base_name), 'GQI');
        op = opts.GQI_out_dir;
        opname = [subname '.SH.GQI.TRK' opts.mprage_coord_suffix];
        fib_file = [opts.GQI_out_dir '_FIB/' subname '.SH.GQI.FIB' opts.mprage_coord_suffix '.fib'];
        DSI_tracking(fib_file, opts.tracking_params,opts.dsi_path,op,opname,opts);
    end
    if opts.estimate_odf_FRT
        disp('FRT: Running DSI studio');
        opts.FRT_out_dir = fullfile(fileparts(opts.file_base_name), 'FRT');
        op = opts.FRT_out_dir;
        opname = [subname '.SH.FRT.TRK' opts.mprage_coord_suffix];
        fib_file = [opts.FRT_out_dir '_FIB/' subname '.SH.FRT.FIB' opts.mprage_coord_suffix '.fib'];
        DSI_tracking(fib_file, opts.tracking_params,opts.dsi_path,op,opname,opts);
    end
    if opts.estimate_odf_FRACT
        disp('FRACT: Running DSI studio');
        opts.FRACT_out_dir = fullfile(fileparts(opts.file_base_name), 'FRACT');
        op = opts.FRACT_out_dir;
        opname = [subname '.SH.FRACT.TRK' opts.mprage_coord_suffix];
        fib_file = [opts.FRACT_out_dir '_FIB/' subname '.SH.FRACT.FIB' opts.mprage_coord_suffix '.fib'];
        DSI_tracking(fib_file, opts.tracking_params,opts.dsi_path,op,opname,opts);
    end 
else
    msg = {'\n Skipping running tracking because DSI studio installation path is set to an empty string. Please check the installation path. You can re-run bdp with --tracking_only flag and run dsi studio tracking only.BDP will assume FIB file already exists and jump straight to tracking.', '\n'};
    fprintf(bdp_linewrap(msg));  
end
end
