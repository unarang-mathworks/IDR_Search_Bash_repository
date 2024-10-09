
function asbCopyAndStartFlightGear(blk,mdl,action,varargin)
% ASBCOPYANDSTARTFLIGHTGEAR This is a helper function for the HL-20
% example. It makes sure that the FlightGear base directory is available
% and that the HL-20 geometry is available. If the geometry is not
% available, it will attempt to copy the geometry from the MATLAB
% installation to the FlightGear aircraft directory. Finally, it will
% attempt to start FlightGear by creating a batch file and run it.
% Copyright 2014-2021 The MathWorks, Inc.
% Use Simulink Project API to get the current project:
    p = slproject.getCurrentProject;
    % Get Variant object from Data Dictionary
    myDictionaryObj = Simulink.data.dictionary.open('asbhl20Data.sldd');
    dDataSectObj = getSection(myDictionaryObj,'Design Data');
    switch action
      case 'CopyStart'
        % Obtain FlighGear directories
        [FGHL20Directory,FGExecFile,FGAircraftDirectory,~] = FGDirectories(mdl);
        % Check that the FlightGear base directory exists
        if exist(FGExecFile,'file')
            statusCopy = 1;
            % Check for existence of the HL-20 geometry in the FlightGear directory
            % and if it does not exist proceed to copy the folder from the MATLAB
            % installation to the FlightGear installation.
            if ~exist(FGHL20Directory,'dir')
                [statusFG,messageFG]=fileattrib(FGAircraftDirectory);
                if statusFG
                    if messageFG.UserWrite
                        % Get the HL20 folder location
                        HL20Source = [p.RootFolder filesep 'support' filesep 'HL20'];
                        [statusCopy,messageCopy] = copyfile(HL20Source,...
                                                            fullfile(FGAircraftDirectory,'HL20'),'f');
                        if ~statusCopy
                            error(message('aeroblks_demos_hl20:asbhl20:copyFail',messageCopy,...
                                          '<a href="matlab:helpview([docroot,''/toolbox/aeroblks/aeroblks.map''],''hl20_flight_gear_help'')">Run the HL-20 Example with FlightGear</a>'));
                        end
                    end
                else
                    error(message('aeroblks_demos_hl20:asbhl20:FGAircraftDirectoryNotFound',messageFG));
                end
            end
            % Proceed to create the batch file in the current directory and launch
            % FlightGear.
            if statusCopy
                % Obtain Output File name from the model
                runfg_out = get_param([mdl '/Viewer and Feedback/FlightGear/Generate Run Script'],'OutputFileName');
                % Check for current directory writing permissions for current user
                workDir = fullfile(p.RootFolder,'work');
                [~,messagePWD] = fileattrib;
                if messagePWD.UserWrite
                    % Generate batch file
                    bh = get_param([mdl '/Viewer and Feedback/FlightGear/Generate Run Script'],'Handle');
                    aerogenfgrunscript(bh);
                    % Move file from current directory to the work
                    % directory
                    if ~strcmp(pwd,workDir)
                        movefile(fullfile(pwd,runfg_out),workDir);
                    end
                    % Perform system call for batch file that starts up FlightGear
                    if exist(fullfile(workDir,runfg_out),'file')
                        if ispc
                            statusSys = system([fullfile(workDir,runfg_out) '&']);
                            % Set Variant to FlightGear
                            evalin(dDataSectObj,'VSS_VISUALIZATION = 1;');
                        else
                            % Get current directory
                            oldDir = pwd;
                            % Go to work directory and execute batch file
                            cd(workDir);
                            statusSys = system(['./' runfg_out '&']);
                            % Return to old directory
                            cd(oldDir);
                            % Set Variant to FlightGear
                            evalin(dDataSectObj,'VSS_VISUALIZATION = 1;');
                        end
                        if statusSys~=0
                            error(message('aeroblks_demos_hl20:asbhl20:systemFail'));
                        end
                    else
                        error(message('aeroblks_demos_hl20:asbhl20:batchFail'));
                    end
                end
            end
        else
            % Set Variant to Previously Saved Data
            evalin(dDataSectObj,'VSS_VISUALIZATION = 0;');
            error(message('aeroblks_demos_hl20:asbhl20:baseFail'));
        end
      case 'Check'
        % Extra parameter for source
        sourceCall = varargin{1};
        % Obtain FlightGear executable location
        [~,FGExecFile,~,FGBaseDirectory] = FGDirectories(mdl);
        % Get FlightGear base directory enabledness
        MaskEnables = get_param(blk,'MaskEnables');
        % Get button parameters
        MaskObject = get_param(blk,'MaskObject');
        installButton = MaskObject.getDialogControl('installFG');
        updateButton = MaskObject.getDialogControl('updateFG');
        launchButton = MaskObject.getDialogControl('launchFG');
        % Establish logic depending on FlightGear executable's existence
        if exist(FGExecFile,'file')
            % Set block color
            set_param(blk,'ForegroundColor','green');
            set_param(blk,'BackgroundColor','green');
            % Set block name
            FGStatus = 'Start FlightGear';
            % Set button enables
            launchButton.Enabled = 'on';
            installButton.Enabled = 'off';
            updateButton.Enabled = 'on';
            % Set edit enables only if they are different
            if ~strcmp(MaskEnables{1},'off')
                MaskEnables{1} = 'off';
                set_param(blk,'MaskEnables',MaskEnables);
            end
            if strcmp(sourceCall,'button')
                % Set Variant to FlightGear
                evalin(dDataSectObj,'VSS_VISUALIZATION = 1;');
                % Success dialog if the check is performed using the button
                msgbox(getString(message('aeroblks_demos_hl20:asbhl20:FGDirectoryFound')),...
                       getString(message('aeroblks_demos_hl20:asbhl20:FGBaseFoundTitle')));
            end
            % Sync FlightGear base directory at the top with the one in the
            % Generate Run-Script block
            FGBase = get_param(blk,'baseFG');
            FGBaseCheck = get_param([mdl '/Viewer and Feedback/FlightGear/Generate Run Script'],...
                                   'FlightGearBaseDirectory');
            % Only do the set_param if the values are different
            if ~strcmp(FGBase,FGBaseCheck)
                set_param([mdl '/Viewer and Feedback/FlightGear/Generate Run Script'],...
                         'FlightGearBaseDirectory',FGBase);
            end
        else
            % Set block color
            set_param(blk,'ForegroundColor','red');
            set_param(blk,'BackgroundColor','red');
            % Set block name
            FGStatus = 'Install FlightGear';
            % Set button enables
            launchButton.Enabled = 'off';
            installButton.Enabled = 'on';
            updateButton.Enabled = 'on';
            % Set edit enables ony if they are different
            if ~strcmp(MaskEnables{1},'on')
                MaskEnables{1} = 'on';
                set_param(blk,'MaskEnables',MaskEnables);
            end
            if strcmp(sourceCall,'button')
                if exist(FGBaseDirectory,'dir')
                    % Throw error to either downgrade the version in the
                    % FlightGear blocks or upgrade to the latest install
                    FGVersion = get_param(sprintf([mdl '/Viewer and Feedback/FlightGear/Pack\nnet_fdm Packet\nfor FlightGear']),...
                                         'FlightGearVersion');
                    errordlg(getString(message('aeroblks_demos_hl20:asbhl20:FGFail',FGVersion,FGVersion)),...
                             getString(message('aeroblks_demos_hl20:asbhl20:FGExecutableNotFoundTitle')));
                else
                    % Throw error dialog if the check is performed using the button
                    errordlg(getString(message('aeroblks_demos_hl20:asbhl20:baseFail')),...
                             getString(message('aeroblks_demos_hl20:asbhl20:FGBaseNotFoundTitle')));
                end
                % Set Variant to Previously Saved Data
                evalin(dDataSectObj,'VSS_VISUALIZATION = 0;');
            end
        end
        FGAttribute = get_param(blk,'AttributesFormatString');
        if ~strcmp(FGAttribute,FGStatus)
            set_param(blk,'AttributesFormatString',FGStatus);
        end
    end
end
function [FGHL20Directory,FGExecFile,FGAircraftDirectory,FGBaseDirectory] = FGDirectories(mdl)
% Local helper function to determine FlightGear's key directory and file
% locations
% Obtain FlightGear Version
    try
        FGVersion = get_param(sprintf([mdl '/Viewer and Feedback/FlightGear/Pack\nnet_fdm Packet\nfor FlightGear']),...
                             'FlightGearVersion');
        % Determine if different path should be used in case that the
        % versions are 3.0 or lower for Windows and 3.2 or lower for Mac
        switch computer
          case {'PCWIN64','PCWIN'}
            versions = {'v2.0','v2.4','v2.6','v2.8','v2.10','v2.12','v3.0'};
          case 'MACI64'
            versions = {'v2.0','v2.4','v2.6','v2.8','v2.10','v2.12','v3.0',...
                        'v3.2'};
        end
        if any(strcmp(FGVersion,versions))
            pathFlag = false;
        else
            pathFlag = true;
        end
    catch
        pathFlag = true;
    end
    % Get and define required directories
    FGBaseDirectory = get_param([mdl '/FlightGear'],'baseFG');
    switch computer
      case 'MACI64'
        if pathFlag
            FGExecFile = fullfile(FGBaseDirectory,'FlightGear.app','Contents','MacOS','fgfs');
        else
            FGExecFile = fullfile(FGBaseDirectory,'FlightGear.app','Contents','Resources','fgfs.sh');
        end
        FGAircraftDirectory = fullfile(FGBaseDirectory,'FlightGear.app','Contents','Resources','data','Aircraft');
      case 'PCWIN64'
        if pathFlag
            FGExecFile = fullfile(FGBaseDirectory,'bin','fgfs.exe');
        else
            FGExecFile32 = fullfile(FGBaseDirectory,'bin','Win32','fgfs.exe');
            FGExecFile64 = fullfile(FGBaseDirectory,'bin','Win64','fgfs.exe');
            if exist(FGExecFile32,'file')
                FGExecFile = FGExecFile32;
            else
                FGExecFile = FGExecFile64;
            end
        end
        FGAircraftDirectory = fullfile(FGBaseDirectory,'data','Aircraft');
      case 'GLNXA64'
        FGExecFile = fullfile(FGBaseDirectory,'bin','fgfs');
        FGAircraftDirectory = fullfile(FGBaseDirectory,'data','Aircraft');
    end
    FGHL20Directory = fullfile(FGAircraftDirectory,'HL20');
end
