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


function html_str = bdp_usage_toTable(fname)
% Wrapper around bdp_usage to return/write a html table of the Usage text.

usageMsg = bdp_usage(true);

html_str = ['<table class="flags" width="100%%">\n<thead>\n<tr>\n<th class="header" width="35%%">Flags</th>\n' ...
   '<th class="header" width="65%%">Flag Description</th>\n</tr>\n</thead>\n'];

% Divide in sub-sections
loc = strfind(usageMsg, '\n=====');
loc = [1 loc length(usageMsg)];

for k = 2:length(loc)-1
   temp_str = usageMsg(loc(k-1):loc(k)-1);
   pp = strfind(temp_str, '\n\n');
   sub_title = temp_str(pp(end)+4:end);
   html_str = [html_str '<thead>\n<tr>\n<th class="header" colspan="2">\n' sub_title '</th>\n</tr>\n</thead>\n'];
   
   
   % Divide in flags
   html_str = [html_str '<tbody>\n'];
   section_str = usageMsg(loc(k):loc(k+1)-1);
   flg_loc = strfind(section_str, '\n\n');   
   for x = 1:length(flg_loc)-2
      temp_str = section_str(flg_loc(x):flg_loc(x+1)-1);
      pp = strfind(temp_str, '\n\t');
      flag = temp_str(5:pp(1)-1);      
      flag = strrep(flag, '<', '&lt;');
      flag = strrep(flag, '>', '&gt;');
      flag = strrep(flag, '\n', '<br>'); 
      
      flag_desc = temp_str(pp(1)+4:end);      
      flag_desc(isspace(flag_desc)) = ' ';      
      flag_desc = strrep(flag_desc, '<', '&lt;');
      flag_desc = strrep(flag_desc, '>', '&gt;');
      flag_desc = regexprep(flag_desc, ' (\-[^ ,.]+)', ' <code>$1</code>');
      flag_desc = regexprep(flag_desc, '(["''])(\S+)(["''])', '$1<code>$2</code>$3');
      html_str = [html_str '<tr>\n<td class="flags-td" style="vertical-align:middle"><code>' flag '</code></td>\n<td class="flags-td">' flag_desc '</td>\n</tr>\n'];            
   end
   html_str = [html_str '</tbody>\n'];
end

html_str = [html_str '</tbody>\n</table>\n'];

if exist('fname', 'var')
   fid = fopen(fname, 'w');
   fprintf(fid, html_str);
   fclose(fid);
end

end





