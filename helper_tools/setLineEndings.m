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


function setLineEndings(filename, lineEnding)
% Sets the line endings of a text file to desired line-ending.
% NOTE: This function OVERWRITES the input file.
%
% Usage:
%   setLineEndings(filename) % uses current OS to infer lineEnding
%   setLineEndings(filename, lineEnding)
%
% Valid values of lineEndings:
%   - 'CRLF' or 'win': Windows line endings (\r\n)
%   - 'LF' or 'unix' : Unix line endings (\n) for Mac and Linux

fid = fopen(filename, 'r');
if (fid == -1)
   fprintf('Could not open file %s. Make sure that it is a valid file.\n', escape_filename(filename));
   return;
end

if nargin<2
   if ispc()
      lineEnding = 'win';
   else % unix
      lineEnding = 'unix';
   end
end

lineEnding = lower(lineEnding);
if ismember(lineEnding, {'crlf', 'win'})
   lineEnding = sprintf('\r\n');
else
   lineEnding = sprintf('\n');
end

fileContents = '';
line = fgetl(fid);
while (ischar(line))
   fileContents = [fileContents line lineEnding];
   line = fgetl(fid);
end
fclose(fid);

% overwrite contents
fid = fopen(filename, 'w');
fprintf(fid, fileContents);
fclose(fid);

end
