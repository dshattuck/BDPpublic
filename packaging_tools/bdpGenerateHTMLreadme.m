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


function bdpGenerateHTMLreadme(readme_filename, manifestFile, lic_short, lic_file, about_file)
% Generates a readme html file, which is the single-file detailed documentation of BDP and
% BDP-flags. This html file is intended to be included with the packaged BDP release.
% This function should be typically called from CompileBrainSuiteDiffusionPipeline() and first need
% to cd to <bdp>/packaging_tools. 

if nargin == 1
    manifestFile = 'bdpmanifest.xml';
end

% generate html text for usage part
usage_msg = bdp_usage(manifestFile);
usage_table = bdp_usage_toTable();

ind1 = strfind(usage_msg, 'Usage:');
version_info = deblank(sprintf(usage_msg(1:ind1-1)));

ind2 = strfind(usage_msg, '--help');
cmd_usage = deblank(sprintf(usage_msg(ind1+7:ind2+5)));

usage_txt = ['<h2>Usage</h2>\n<p>' version_info '</p>\n<pre>' htmlEncode(cmd_usage) '</pre><br>\n' ...
   '<h2>Flag description</h2>\n<p>' version_info '</p>\n<br<br>\n' usage_table];

% footer text
footer_txt = ['<div class="footer">\n\t' version_info '\n</div>'];

% load other text files
changelog_txt = getTxtContent(fullfile('..', 'docs', 'bdpchangelog.txt'));
lic_txt = getTxtContent(lic_file);
about_txt = getTxtContent(about_file);


fid = fopen(fullfile('..', 'docs', 'BDP_readme_skeleton.html'), 'r');
if fid<0
   error('Could not open BDP_readme_skeleton.html');
end

fileContents = '';
line = escapeSpecialChars(fgetl(fid));
while (ischar(line))
   
   if ~isempty(strfind(line, '<!-- USAGE AND FLAGS -->'))
      line = strrep(line, '<!-- USAGE AND FLAGS -->', usage_txt);
   
   elseif ~isempty(strfind(line, '<!-- CHANGELOG -->'))
      line = strrep(line, '<!-- CHANGELOG -->', htmlEncode(changelog_txt));
      
   elseif ~isempty(strfind(line, '<!-- FOOTER -->'))
      line = strrep(line, '<!-- FOOTER -->', footer_txt);
   
   elseif ~isempty(strfind(line, '<!-- LIC SHORT -->'))
      line = strrep(line, '<!-- LIC SHORT -->', htmlEncode(lic_short));
      
   elseif ~isempty(strfind(line, '<!-- LICENSE -->'))
      line = strrep(line, '<!-- LICENSE -->', htmlEncode(lic_txt));
            
   elseif ~isempty(strfind(line, '<!-- ABOUT -->'))
      line = strrep(line, '<!-- ABOUT -->', htmlEncode(about_txt));
   end
   
   fileContents = [fileContents line '\n'];
   line = escapeSpecialChars(fgetl(fid));
end
fclose(fid);


fidW = fopen(readme_filename, 'w');
fprintf(fidW, fileContents);
fclose(fidW);
end

function s = escapeSpecialChars(s)
% Escapes special characters for fprintf

if isempty(s)
   return
else
   s = strrep(s, '''', '''''');
   s = strrep(s, '%', '%%');
   s = strrep(s, '\', '\\');
end
end


function txt = getTxtContent(fname)
fid = fopen(fname, 'r');
txt = '';
while ~feof(fid)
   tline = escapeSpecialChars(fgetl(fid));
   txt = [txt tline '\n'];
end

fclose(fid);
end

function txt = htmlEncode(txt)

if isempty(txt)
   return
else
   txt = strrep(txt, '<', '&lt;');
   txt = strrep(txt, '>', '&gt;');
end
end

