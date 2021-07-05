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
            buildNo = str2double(varargin{i+1});
            if ~isequal(buildNo, int16(buildNo))
               error('build number must be integer!')
            end
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
   if ispc
      mcc -m -v BrainSuite_Diffusion_pipeline.m -a ..\mat_files\*
      % mcc -m -v dicom2nifti_Diffusion.m
      % mcc -m -v coregister_diffusion_mprage_pipeline -a ..\mat_files\*
      % mcc -m -v estimate_SH_FRT_FRACT_mprage
      % mcc -m -v estimate_tensors_mprages
      
      %    elseif ismac
      %       mcc -m -R -nodisplay -v BrainSuite_Diffusion_pipeline.m -a ../mat_files/*
      %       % mcc -m -v dicom2nifti_Diffusion.m
      %       % mcc -m -v coregister_diffusion_mprage_pipeline -a ../mat_files/*
      %       % mcc -m -v estimate_SH_FRT_FRACT_mprage
      %       % mcc -m -v estimate_tensors_mprage
      
   else % both Linux and Mac
      % Somehow mcc does not work from matlab in all of USC *nix computers! But it does work from
      % Unix command prompt. It uses mcc executable at [matlabroot() '/bin/mcc']
      
      bdp_path = search_rmpath('brainsuite-diffusion-pipeline');
      cmd_str = ['-I ' bdp_path];
      cmd_str = strrep(cmd_str, pathsep, ' -I ');
      cmd_str = [matlabroot(), '/bin/mcc -m ' cmd_str ' -v BrainSuite_Diffusion_pipeline.m '];
      
      mat_dir = [pwd '/../mat_files'];
      listing = dir(mat_dir);
      if length(listing)>2
         mat_str = [];
         for k = 3:length(listing)
            mat_str = [mat_str ' -a ' fullfile(mat_dir, listing(k).name)];
         end
         cmd_str = [cmd_str mat_str];
      end
      [status, result] = system(cmd_str,'-echo');
      addpath(bdp_path);
   end
   
   disp('Compiling done');
end


if package
   disp('Starting packaging');
   if ispc
      package_bdp_pc(bdp_version, buildNo, lic);
   elseif ismac
      package_bdp_mac(bdp_version, buildNo, lic);
   else
      package_bdp_linux(bdp_version, buildNo, lic);
   end
   disp('Packaging done.');
end
end


function package_bdp_pc(bdp_version, buildNo, lic)
workdir = setup_package(bdp_version, buildNo, lic);

copyfile('BrainSuite_Diffusion_pipeline.exe', [workdir filesep 'bdp.exe']);

zip(workdir, workdir);
rmdir(workdir, 's');
end


function package_bdp_linux(bdp_version, buildNo, lic)
workdir = setup_package(bdp_version, buildNo, lic);

copyfile('BrainSuite_Diffusion_pipeline', [workdir filesep 'bdp']);
bdp_create_shell_script([workdir filesep 'bdp.sh'], [workdir filesep 'bdpmanifest.xml']);

fileattrib([workdir filesep '*.sh'], '+x');

tar([workdir '.tar.gz'], workdir);
rmdir(workdir, 's');
end


function package_bdp_mac(bdp_version, buildNo, lic)
workdir = setup_package(bdp_version, buildNo, lic);

copyfile('BrainSuite_Diffusion_pipeline.app', [workdir filesep 'bdp.app']);
bdp_create_shell_script([workdir filesep 'bdp.sh'], [workdir filesep 'bdpmanifest.xml']);

fileattrib([workdir filesep '*.sh'], '+x');

tar([workdir '.tar.gz'], workdir);
rmdir(workdir, 's');
end


function directory = setup_package(bdp_version, buildNo, lic)
bdp_string = strrep(num2str(bdp_version), '.', 'p');
directory =  sprintf('bdp_%s_build%04d_%s', bdp_string, buildNo, get_platform());

mkdir(directory);
create_manifest(bdp_version, buildNo, fullfile(directory, 'bdpmanifest.xml'));
create_about(bdp_version, buildNo, fullfile(directory, 'About_BDP.txt'));

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


function create_manifest(bdp_version, buildNo, filename)
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
   '</bdpmanifest>\n'], num2str(bdp_version), num2str(buildNo, '%04d'), compile_date, mcr_version, platform);

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



function create_about(bdp_version, buildNo, filename)
% Merge README.txt and NOTICE.txt into About.txt with version info

fot = fopen(filename, 'w');

% add release name in readme part
fin = fopen(fullfile('..', 'README.txt'), 'r');
str_match = 'Created by Chitresh Bhushan, Divya Varadarajan, Justin P. Haldar,';
while ~feof(fin)
   tline = fgetl(fin);
   if strcmp(tline, str_match)
      fprintf(fot, 'This is version %s (build #%04d) of BDP, released on %s.\n\n', bdp_version, buildNo, datestr(now, 'dd-mmm-yyyy'));
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


