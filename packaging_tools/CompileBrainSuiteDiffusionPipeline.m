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

% dws 24Aug2026 - removing build number from comparison because we have switched to git hashes
function CompileBrainSuiteDiffusionPipeline(varargin)
% Usage: 
%    CompileBrainSuiteDiffusionPipeline 
%    CompileBrainSuiteDiffusionPipeline --package 14aRC1 --build 1234
%    CompileBrainSuiteDiffusionPipeline --package 14aRC1 --build 1234 --lic GPL
%    CompileBrainSuiteDiffusionPipeline --package 14aRC1 --build 1234 --lic GPL --no-compile
%
% Probably, first need to cd to packaging_tools

restoredefaultpath();
cd('..');
addpath(genpath(pwd));
search_rmpath('.git');
cd('packaging_tools');


package = false;
compile = true;
lic = 'GPL';

if ~ismember(nargin, [0 4 6 7 5])
   error('Incorrect input arguments. Need either 0, 4, 5, 6, or 7 arguments!')
   
elseif nargin>0   
   i = 1;
   while(i<=nargin)
      switch varargin{i}
         case '--package'
            package = true;
            bdp_version = varargin{i+1};
            i = i + 2;
            
         case '--build'
            package = true;
            buildHash = varargin{i+1}
            % str2double(varargin{i+1});
            % if ~isequal(buildNo, int16(buildNo))
            %    error('build number must be integer!')
            % end
            i = i + 2;
            
         case '--no-compile'
            compile = false;
            i = i + 1;
            
         case '--lic'
            lic = varargin{i+1};
            if ~ismember(lic, {'GPL', 'BST'})
               error('Unknown lic: %s.\nSupported licenses are GPL and BST.');
            end
            i = i + 2;
            
         otherwise
            error('Unknown argument: %s', varargin{i})
      end
   end
end



if compile
   if ismac
    disp('Building on macOS. Configuring SIP-proof runtime paths...');
    relInfo = matlabRelease; % e.g., 'R2025b'
    matlabFolderName = sprintf('MATLAB_%s.app', relInfo.Release); 
    [mcrMajor, mcrMinor] = mcrversion; % e.g., 'v252'
    mcrFolderName = sprintf('v%d%d', mcrMajor, mcrMinor); 
    archSuffix = computer('arch'); % e.g., 'maci64' or 'maca64'
    fullMatlabBase = fullfile('/Applications', matlabFolderName);
    runtimeBase    = fullfile('/Applications/MATLAB/MATLAB_Runtime', mcrFolderName);

    rpaths = { ...
        ['-add_rpath,' fullfile(fullMatlabBase, 'bin', archSuffix)], ...
        ['-add_rpath,' fullfile(fullMatlabBase, 'runtime', archSuffix)], ...
        ['-add_rpath,' fullfile(fullMatlabBase, 'sys/os', archSuffix)], ...
        ['-add_rpath,' fullfile(runtimeBase, 'bin', archSuffix)], ...
        ['-add_rpath,' fullfile(runtimeBase, 'runtime', archSuffix)], ...
        ['-add_rpath,' fullfile(runtimeBase, 'sys/os', archSuffix)] ...
    };
    macLinkerFlags = [{'-R'}, {rpaths{1}}, {'-R'}, {rpaths{2}}, {'-R'}, {rpaths{3}}, ...
                      {'-R'}, {rpaths{4}}, {'-R'}, {rpaths{5}}, {'-R'}, {rpaths{6}}];
                  
    % Merge with your existing standard mcc arguments
    mccArgs = [{'-m', '-v', 'BrainSuite_Diffusion_pipeline.m', '-a', '../mat_files/*'}, macLinkerFlags];
    mcc(mccArgs{:})

      % mcc -m -v BrainSuite_Diffusion_pipeline.m -a ../mat_files/*
   else % both Linux and Windows
		mcc -m -v BrainSuite_Diffusion_pipeline.m -a ../mat_files/*
   end
   
   disp('Compiling done');
end


if package
   disp('Starting packaging');
   if ispc
      package_bdp_pc(bdp_version, buildHash, lic);
   elseif ismac
      package_bdp_mac(bdp_version, buildHash, lic);
   else
      package_bdp_linux(bdp_version, buildHash, lic);
   end
   disp('Packaging done.');
end
end


function package_bdp_pc(bdp_version, buildHash, lic)
workdir = setup_package(bdp_version, buildHash, lic);

copyfile('BrainSuite_Diffusion_pipeline.exe', [workdir filesep 'bdp.exe']);

zip(workdir, workdir);
rmdir(workdir, 's');
end


function package_bdp_linux(bdp_version, buildHash, lic)
workdir = setup_package(bdp_version, buildHash, lic);

copyfile('BrainSuite_Diffusion_pipeline', [workdir filesep 'bdp']);
bdp_create_shell_script([workdir filesep 'bdp.sh'], [workdir filesep 'bdpmanifest.xml']);

fileattrib([workdir filesep '*.sh'], '+x');

tar([workdir '.tar.gz'], workdir);
rmdir(workdir, 's');
end


function package_bdp_mac(bdp_version, buildHash, lic)
workdir = setup_package(bdp_version, buildHash, lic);

copyfile('BrainSuite_Diffusion_pipeline.app', [workdir filesep 'bdp.app']);
bdp_create_shell_script([workdir filesep 'bdp.sh'], [workdir filesep 'bdpmanifest.xml']);

fileattrib([workdir filesep '*.sh'], '+x');

tar([workdir '.tar.gz'], workdir);
rmdir(workdir, 's');
end


function directory = setup_package(bdp_version, buildHash, lic)
bdp_string = strrep(num2str(bdp_version), '.', 'p');
directory =  sprintf('bdp_%s_build_%s_%s', bdp_string, buildHash, get_platform());

mkdir(directory);
create_manifest(bdp_version, buildHash, fullfile(directory, 'bdpmanifest.xml'));
create_about(bdp_version, buildHash, fullfile(directory, 'About_BDP.txt'));

% copy correct lic to License.txt
switch lic
   case 'GPL'
      lic_file = 'gpl-2.0.txt';
      lic_short = 'GNU General Public License, version 2';
      
   case 'BST'
      lic_file = 'BST-2.0.txt';
      lic_short = 'BrainSuite Software License, Version 2.0';
      
   otherwise
      error('Unknown lic: %s.\nSupported licenses are GPL and BST.');
end
copyfile(fullfile('..', 'docs', lic_file), fullfile(directory, 'License.txt'));

bdpGenerateHTMLreadme(fullfile(directory, 'ReadMe.html'), fullfile(directory, 'bdpmanifest.xml'), lic_short, ...
   fullfile(directory, 'License.txt'), fullfile(directory, 'About_BDP.txt'));

setLineEndings(fullfile(directory, 'bdpmanifest.xml'));
setLineEndings(fullfile(directory, 'About_BDP.txt'));
setLineEndings(fullfile(directory, 'License.txt'));
end


function create_manifest(bdp_version, buildHash, filename)
compile_date = datestr(now, 'yyyy-mm-dd');
mcr_version = get_mcr_version();
platform = get_platform();

manifest = sprintf(...
   ['<?xml version="1.0" encoding="UTF-8"?>\n' ...
   '<bdpmanifest>\n' ...
   '\t<version>%s</version>\n'...
   '\t<build>%s</build>\n'...
   '\t<date>%s</date>\n'...
   '\t<mcrversion>%s</mcrversion>\n'...
   '\t<platform>%s</platform>\n'...
   '</bdpmanifest>\n'], num2str(bdp_version), buildHash, compile_date, mcr_version, platform);

fid = fopen(filename, 'w');
fprintf(fid, manifest);
fclose(fid);
end


function mcr_version = get_mcr_version()
[major, minor, update] = mcrversion();
mcr_version = [num2str(major) '.' num2str(minor)];
if update ~= 0
   mcr_version = [mcr_version '.' num2str(update)];
end
end


function platform = get_platform()
platform = computer('arch');

if strcmp(platform, 'glnxa64')
   platform = 'linux';
end
end



function create_about(bdp_version, buildHash, filename)
% Merge README.txt and NOTICE.txt into About.txt with version info

fot = fopen(filename, 'w');

% add release name in readme part
fin = fopen(fullfile('..', 'README.txt'), 'r');
str_match = 'Created by Chitresh Bhushan, Divya Varadarajan, Justin P. Haldar,';
while ~feof(fin)
   tline = fgetl(fin);
   if (startsWith(tline,'This is release'))
      tline = fgetl(fin);
      if (tline=="")
         continue;
      end;
   end
   if strcmp(tline, str_match)
      fprintf(fot, 'This is version %s (build #%04d) of BDP, released on %s.\n\n', bdp_version, buildHash, datestr(now, 'dd-mmm-yyyy'));
   end
   fprintf(fot, '%s\n', tline);
end
fclose(fin);

fin = fopen(fullfile('..', 'NOTICE.txt'), 'r');
while ~feof(fin)
   tline = fgetl(fin);
   fprintf(fot, '%s\n', tline);
end
fclose(fin);
fclose(fot);
end


