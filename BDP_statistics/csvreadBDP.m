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


function [hdr, M, col1, col_end] = csvreadBDP(fname)
% csv reader for BDP stat files. Assumes csv files to be saved by BDP.
% Not a generic function - supports csv files written in a structured
% manner: 
%
%   * header row defines number of columns, and is returned as hdr - a cell array of string
%   * Only first and last column can contain non-numeric data (excluding header)
%   * If first and last column are non-numeric, they are returned as
%     non-empty cell arrays: col1, col_end
%   * M is numeric part (includes first and last column when they are numeric)
%   * An empty cell (or column) is considered non-numeric!
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


% read header
fid = fopen(fname, 'r');
colhdr = fgetl(fid);
colhdr = textscan(colhdr, '%s', 'Delimiter', ',');
hdr = colhdr{1};

% read rest of csv file
nCol = length(hdr);
tline = fgetl(fid);
data = {};
while ischar(tline)
   temp = textscan(tline, '%s', 'Delimiter', ',');
   t2 = cell(1,nCol);
   t2(1:length(temp{1})) = temp{1}';
   data = [data; t2];
   tline = fgetl(fid);
end
fclose(fid);


% if col1 is numeric, keep it in data
col1 = data(:,1);
tf = cellfun(@isNumericString, col1);
num_flag = all(tf);
if num_flag
   col1 = cell(length(col1), 0);
else
   data(:,1) = [];
end


% if last col is numeric, keep it in data
col_end = data(:,end);
tf = cellfun(@isNumericString, col_end);
num_flag = all(tf);
if num_flag
   col_end = cell(length(col_end), 0);
else
   data(:,end) = [];
end

M = cellfun(@str2double, data);
end


function tf = isNumericString(s)
% checks if the input is a string representing number in matlab sense

if isempty(s)
   tf = false;
else
   try
      x = eval(['[' s ']']);
      tf = true;
   catch exception %#ok
      tf = false;
      x = [];
   end
end
end

