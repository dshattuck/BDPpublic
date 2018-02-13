% 
% BDP BrainSuite Diffusion Pipeline
% 
% Copyright (C) 2018 The Regents of the University of California and
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


function execDir = bdp_get_deployed_exec_dir()
% Returns the directory of the currently running executable if deployed,
% an empty string if not deployed (or if unable to determine the directory)
    execDir = '';
    if isdeployed
        if ispc
            [status, execDir] = system('path');
            if status == 0
                execDir = char(regexpi(execDir, 'Path=(.*?);', 'tokens', 'once'));
            end
        else
            execDir = getenv('BDPEXEDIR');
        end
    end
end
