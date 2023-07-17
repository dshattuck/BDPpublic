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


function DSI_tracking(fib_file,txt_cmd,dsi_path,op,opname,opts)
% Function to run the DSI Studio tracking using command prompt
% txt_cmd: dsi studio parameters
% dsi_path: The path of DSI Studio application

%% check opts
% GQI paper defaults : default_trk_cmd{1} = '--method=0 --seed_count=800000 --seed_plan=1 --interpolation=0 --threshold_index=qa --fa_threshold=0.01 --thread_count=1 --step_size=1 --turning_angle=60 --min_length=30 --max_length=800';
% fract tuning: default_trk_cmd{2} = '--method=0 --seed_count=800000 --seed_plan=1 --interpolation=0 --threshold_index=qa --fa_threshold=0.01 --thread_count=1 --step_size=1 --turning_angle=45 --min_length=20 --max_length=450';

% Based on initial evaluation of a dataset with bval=1000, Jones 30 direction, 2.5mm3 voxels, 3T 8channel head coil Phillips Achieva.
default_trk_cmd{1} = '--method=0 --seed_count=400000 --seed_plan=1 --interpolation=0 --threshold_index=qa --thread_count=1 --step_size=.25 --turning_angle=50 --fa_threshold=0.1 --min_length=10 --max_length=800 --smoothing=.9';
default_trk_cmd{2} = ' --method=0 --seed_count=400000 --seed_plan=1 --interpolation=0 --threshold_index=qa --thread_count=1 --step_size=.25 --turning_angle=60 --fa_threshold=0.25 --min_length=10 --max_length=800 --smoothing=.9';

if isempty(txt_cmd)
    txt_cmd = default_trk_cmd;
end;

%% Get the command
% txt_cmd = parseCSVfile(optsFile);
N = length(txt_cmd); % number of commands
trk_file = dir([op '_TRK*']);
if isempty(trk_file)
    ntrk=0;
else
    ntrk = length(trk_file);
end

%% setup
for nsub=1:N
    ntrk = ntrk +1;
    opdir = [op '_TRK' num2str(ntrk)];
    mkdir(opdir);
    trk_op = [opname '_' num2str(ntrk) '.trk'];
    if ispc
        ds_cmds{nsub} =[opts.dsi_path '/dsi_studio --action=trk --source=' fib_file ' ' char(txt_cmd(nsub)) ' --output=' opdir '/' trk_op]
    elseif ismac || isunix
        ds_cmds{nsub} =[opts.dsi_path '/dsi_studio --action=trk --source=' fib_file ' ' char(txt_cmd(nsub)) ' --output=' opdir '/' trk_op]
    end
    fid = fopen([opdir '/' opname '_params.txt'],'w');
    fprintf(fid,'%s', char(ds_cmds(nsub)));
    fclose(fid);
end

%% run dsi
for nsub=1:N
    cmd=char(ds_cmds(nsub))
    system(cmd);
end

end
