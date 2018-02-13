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


function flag_cell = readFlagConfigFile(fname)
% Reads BDP flag configuration file and return the flag and parameters in a cell of strings. No
% checks. The file should follow following format: 
% 
%      # Any line starting with # is comment
%      <flag1> [<flag1 parameter>]
%      <flag2> [<flag2 parameter>] # rest of this line is also comment
%      <flagN> [<flagN parameter>]#This is also comment
%

if exist(fname, 'file')~=2   
   error('BDP:FileDoesNotExist', bdp_linewrap(['BDP could not find specified --flag-conf-file. Check to make sure '...
      'that the following file exits: ' escape_filename(fname)]));
end

% dirty workaround different line-endings
flag_str = '';
fid = fopen(fname, 'r');
tline = fgetl(fid);
while ischar(tline)
    flag_str = sprintf('%s\n%s', flag_str, tline);
    tline = fgetl(fid);
end
flag_str = sprintf('%s \n', flag_str);
fclose(fid);

% find comments & throw them away 
% s = regexprep(flag_str, '\s+#[^\n]*\n', '\n'); % shell script style comment rule
s = regexprep(flag_str, '#[^\n]*\n', '\n');

% separate flags
flag_cell = regexpi(s, '\s*(\S+)', 'tokens');

end
