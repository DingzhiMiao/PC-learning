% function perceptual_category_learning(subjectID, subrun, feedback, ifeyelink)
clear;
ifeyelink = 0;
subjectID = 'hdzhdz';
subrun = 1;
feedback = 1;

%% initialize
commandwindow;

Screen('Preference','Verbosity',0);
Screen('Preference','SkipSyncTests',1);
Screen('Preference','VisualDebugLevel',0);
KbName('UnifyKeyNames');

rng('Shuffle')

%% Info.
filepath = pwd;
dataPath = [filepath '\..\data'];
subPath = [dataPath '\' subjectID];

if ~exist(subPath, 'dir')
    mkdir(subPath);
end

fileName = [dataPath '\pc_learning.dat'];

if exist([subPath '/config_file.mat'], 'file')
    load([subPath '/config_file.mat']);
else
    config = set_configuration(subPath);
end

block = 0;
if exist([subPath '/pc_learning.mat'],'file')
    load([subPath '/pc_learning.mat']);
end
block = block + 1;

height = 1024;
width = 768;
framerate = 60;
displaySize = [400 300];
distance = 1000;

ecc = 5;
totalTrials = 60;

initDiff = 20;
maxDiff = 25*sqrt(2);

freRange = [1 8];
oriRange = [0 90];

keyList = {KbName('1'),KbName('2')};

location = config.location;
task = config.task;
rule = config.rule;
type = config.type;

dur.iti = 0.8;
dur.stim = 0.2;
dur.rest = 2;
dur.delay = 0.2;
try
    if ifeyelink
        %% STEP 1
        % Initialization of the connection with the Eyelink Gazetracker.
        % exit program if this fails.
        initializedummy=0;
        if initializedummy~=1
            if Eyelink('initialize') ~= 0
                fprintf('error in connecting to the eye tracker');
                return;
            end
        else
            Eyelink('initializedummy');
        end
        
        %% STEP 2
        % Added a dialog box to set your own EDF file name before opening
        % experiment graphics. Make sure the entered EDF file name is 1 to 8
        % characters in length and only numbers or letters are allowed.
        
        while length(subject)>7
            disp('Enter your name with less characters (1 to 7 letters allowed)');
            subject = input('Enter the subject ID: ','s');
        end
        edfFile = ['PC' subject  num2str(block)];
        % the code are in case the subject wrongly input the argument which may replace the old data.
        while  2==exist([filepath '\raw_edf\' edfFile '.edf'],'file')
            disp('Run number was wrong, please check and input agian!');
        end
    end
    
    %% STEP 3  getDisplay
    HideCursor;
    set_test_gamma;
    
    Screens = Screen('Screens');
    ScnNbr = max(Screens);
    oldResolution = Screen('Resolution', ScnNbr, height, width, framerate, 32); % change resolution
    [wPtr, wRect] = Screen('OpenWindow', ScnNbr, 0,[],32,2);
    FlipInterval = Screen('GetFlipInterval',wPtr);
    [wCx,wCy] = WindowCenter(wPtr);
    
    Black = BlackIndex(ScnNbr);
    White = WhiteIndex(ScnNbr);
    Gray = round((White+Black)/2);
    
    rectWidth = round(wRect(3));
    h = round(wRect(3));
    v = round(wRect(4));
    
    PixelPerDeg=h/2/atand(displaySize(1)/2/distance);
    
    if ifeyelink
        %% STEP 4
        % Provide Eyelink with details about the graphics environment
        % and perform some initializations. The information is returned
        % in a structure that also contains useful defaults
        % and control codes (e.g. tracker state bit and Eyelink key values).
        el=EyelinkInitDefaults(wPtr);
        
        % Initialization of the connection with the Eyelink Gazetracker.
        % exit program if this fails.
        dummymode=0;
        if ~EyelinkInit(dummymode)
            fprintf('Eyelink Init aborted.\n');
            cleanup;  % cleanup function
            return;
        end
        
        [vv,vs]=Eyelink('GetTrackerVersion');
        fprintf('Running experiment on a ''%s'' tracker.\n', vs );
        
        % open file to record data to
        i = Eyelink('Openfile', edfFile);
        if i~=0
            printf('Cannot create EDF file ''%s'' ', edffilename);
            Eyelink( 'Shutdown');
            return;
        end
        
        Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox demo-experiment''');
        [eyewidth, eyeheight]=Screen('WindowSize', wPtr);
        
        %% STEP 5
        % SET UP TRACKER CONFIGURATION
        % Setting the proper recording resolution, proper calibration type,
        % as well as the data file content;
        Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, eyewidth-1, eyeheight-1);
        % Eyelink('message', 'DISPLAY_COORDS_FRAMERATE %ld %ld %ld %ld %ld', 0, 0, width-1, height-1, 100*FrameRate);
        % set calibration type.
        Eyelink('command', 'calibration_type = HV9');
        % set parser (conservative saccade thresholds)
        Eyelink('command', 'saccade_velocity_threshold = 35');
        Eyelink('command', 'saccade_acceleration_threshold = 9500');
        % set EDF file contents
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS');
        % set link data (used for gaze cursor)
        Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON');
        Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS');
        % allow to use the big button on the eyelink gamepad to accept the
        % calibration/drift correction target
        Eyelink('command', 'button_function 5 "accept_target_fixation"');
        % enable drift correct
        Eyelink('command', 'driftcorrect_cr_disable = OFF');
        Eyelink('command','screen_distance = %ld', distance*10);
        
        % make sure we're still connected.
        if Eyelink('IsConnected')~=1
            return;
        end;
        
        %% STEP 6
        % Calibrate the eye tracker
        % setup the proper calibration foreground and background colors
        el.backgroundcolour = Gray;
        el.foregroundcolour = White;
        EyelinkDoTrackerSetup(el);
        
    end
    
    %% define key
    TriggerKey = KbName('space');
    EscapeKey = KbName('ESCAPE');
    RepeatKey = KbName('7');
    DriftCorrestKey = KbName('8');
    badbutton = 'Twang.WAV';
    [yy, Fs]=audioread(badbutton);
    
    %% design the background fixation
    dotsXY = [wCx,wCy];
    FPsize = 0.3*PixelPerDeg;
    FPtype = 1;
    FPcolor = 255;
    
    %% gabor stimuli parameters
    contrast = 47;       %
    sigma = 0.68;
    phase = 90;          %
    patchxextd = ceil(10*PixelPerDeg);  % patch size
    patchyextd = ceil(10*PixelPerDeg);  % patch size
    locCx = patchxextd/2;
    locCy = patchyextd/2;
    
    offLocX = round(ecc*cosd(location)*PixelPerDeg);
    offLocY = round(-ecc*sind(location)*PixelPerDeg);
    
    %% staircase
    % Start some local variables used to control the staircase
    pStaircase.nUps=3;                   %3-> ~80% success 2->~70% success 1->~50% ssuccess
    pStaircase.initStep =2;              % calculated from after Inital steps dropped
    pStaircase.nChanges=2;               % Num. of reversals after which the step size changes to 1.
    pStaircase.nPractice=1;
    pStaircase.conditionScale = 1;       % This identifies the type of the scale of conditions vector, 0 for linear; 1 for logarithm scale.
    pStaircase.nReversals=10;            % Num. of reversals to end the staircase
    pStaircase.nCalc =6;                 % Num. of reversals used for computing final threshold
    pStaircase.initSetup=initDiff;
    pStaircase.testCondition=10.^[-1:0.05:1.8];
    pStaircase.step=pStaircase.testCondition(2)/pStaircase.testCondition(1);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Record the results of current data
    initValueIndex=find(pStaircase.testCondition>=(pStaircase.initSetup));
    history.testValue=pStaircase.testCondition(initValueIndex(1));
    
    history.isReversal=[0];       % whether is a reversal
    history.correct=[];           % correct or not in this trial
    history.nUp=[1];              % how many trials is accumulated to be correct
    history.UpOrDown=[];          % the trend of the psychometrics is up or down , only to calculate the reversals
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ifeyelink
        %% recorde block information at begining of the .edf file
        % Eyelink('message', 'Recorded variable: %s %s %s %s %s %s %s ', 'LocIndx', 'Ori','distance', 'Ecc', 'SizeInDeg', 'sf_narrow', 'sf_wide');
        % Eyelink('message', 'Value of variable: %d %d %d %d %d %d %d ', LocIndx, Ori_ref, distance, Ecc, SizeInDeg, round(100*sf_narrow), round(100*sf_wide));
        
        %% STEP 7.1
        % This supplies the title at the bottom of the eyetracker display
        % Eyelink('command', 'record_status_message "TRIAL %d"', trial);
        % Before recording, we place reference graphics on the host display
        % Must be offline to draw to EyeLink screen
        Eyelink('Command', 'set_idle_mode');
        % clear tracker display and draw box at center
        % EyeLink('Command', 'clear_screen 0');
        Eyelink('command', 'draw_box %d %d %d %d 15', width/2-50, height/2-50, width/2+50, height/2+50);
        
        %% STEP 7.2
        % Do a drift correction at the beginning of each trial
        % Performing drift correction (checking) is optional for
        % EyeLink 1000 eye trackers.
        EyelinkDoDriftCorrection(el,wCx,wCy);
        
        eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
        if eye_used == el.BINOCULAR % if both eyes are tracked
            eye_used = el.LEFT_EYE; % use left eye
        end
        
        %% STEP 7.3
        % start recording eye position (preceded by a short pause so that
        % the tracker can finish the mode transition)
        % The paramerters for the 'StartRecording' call controls the
        % file_samples, file_events, link_samples, link_events availability
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.05);
        Eyelink('StartRecording', 1, 1, 1, 1);
        % record a few samples before we actually start displaying
        % otherwise you may lose a few msec of data
    end
    
    %% The first display %%
    Screen('FillRect',wPtr,Gray,wRect);
    Screen('DrawDots',wPtr,[0,0], FPsize,FPcolor,dotsXY,FPtype);
    Screen('Flip',wPtr);
    
    %% Initialize the experiments
    [~, secs, keyCode] = KbCheck;
    touch = 0;
    while ~(touch&&(keyCode(TriggerKey) || keyCode(EscapeKey)))
        [touch, secs, keyCode] = KbCheck;
    end
    if keyCode(EscapeKey)
        Screen('CloseAll');
    end
    
    nTrials = 1;
    reversal = 0;
    eyeTrial = 0;
    
    while nTrials <= totalTrials
        redo = 1;
        eyeP = 0;
        dc = 0;
        
        difficulty = history.testValue(nTrials);
        if difficulty > maxDiff
            difficulty = maxDiff;
            history.testValue(nTrials) = maxDiff;
        end
        if ifeyelink
            Eyelink('Message', 'TRIALID %d', nTrials);
        end
        
        while redo==1
            phase1 = phase + rand*180;
            
            %% define orientation and spatial frequency
            % orientation frequency
            [ ori_std, freq_std, key] = Thres2Feature( type, difficulty );
            if task== 'RB'
                orientation = rule + ori_std/100*(oriRange(2)-oriRange(1))-(oriRange(2)-oriRange(1))/2;
            else
                orientation = ori_std/100*(oriRange(2)-oriRange(1))+oriRange(1);
            end
            frequency = ori_std/100*(freRange(2)-freRange(1))+freRange(1);
            orientation = -orientation;
            YesKey = keyList{key};
            NoKey = keyList{3-key};
            
            %% make gabor
            % grayscaleImageMatrix=MyGabor(PixelPerDeg, xor, xextd, yor, yextd, contrast, cycPerDeg, sigma, phase, tiltInDegrees, locCx, locCy)
            sti=MyGabor(PixelPerDeg, 1, patchxextd, 1, patchyextd, contrast, frequency, sigma, phase1, orientation, locCx, locCy);
            
            stiPatch=round((sti+1)/2*255);
            GaborStim=Screen('MakeTexture',wPtr,stiPatch);
            
            % Define Stimuli Location;
            PicRect=Screen('Rect',GaborStim);
            Pic_center=CenterRect(PicRect,wRect);
            PicLoc=OffsetRect(Pic_center,offLocX,offLocY);
            
            %% Run Trials
            % ITI
            Screen('FillRect',wPtr,Gray,wRect);
            Screen('DrawDots',wPtr,[0,0], FPsize,FPcolor,dotsXY,FPtype);
            Screen('Flip',wPtr);
            
            if ifeyelink
                WaitSecs(dur.iti-0.2);
                
                % make sure fixation
                tic
                while toc < 0.2
                    if Eyelink( 'NewFloatSampleAvailable') > 0
                        % get the sample in the form of an event structure
                        evt = Eyelink( 'NewestFloatSample');
                        if eye_used ~= -1 % do we know which eye to use yet?
                            % if we do, get current gaze position from sample
                            x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
                            y = evt.gy(eye_used+1);
                            rr = sqrt((x-wCx)^2+(y-wCy)^2);
                            % do we have valid data and is the pupil visible?
                            if x~=el.MISSING_DATA && y~=el.MISSING_DATA && evt.pa(eye_used+1)>0
                                if rr > PixelPerDeg*2
                                    eyeP = 1;
                                    break;
                                end
                            end
                        end % if sample available
                    end
                end
                if eyeP break; end
            else
                WaitSecs(dur.iti);
            end
            
            %% stimulus
            Screen('DrawTexture',wPtr,GaborStim,PicRect,PicLoc);
            Screen('DrawDots',wPtr,[0,0], FPsize,FPcolor,dotsXY,FPtype);
            Screen('Flip',wPtr);
            if ifeyelink
                Eyelink('Message', 'Target_show');
                tic
                while toc < dur.stim
                    if Eyelink( 'NewFloatSampleAvailable') > 0
                        % get the sample in the form of an event structure
                        evt = Eyelink( 'NewestFloatSample');
                        if eye_used ~= -1 % do we know which eye to use yet?
                            % if we do, get current gaze position from sample
                            x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
                            y = evt.gy(eye_used+1);
                            rr=sqrt((x-wCx)^2+(y-wCy)^2);
                            % do we have valid data and is the pupil visible?
                            if x~=el.MISSING_DATA && y~=el.MISSING_DATA && evt.pa(eye_used+1)>0 && rr > PixelPerDeg*2
                                % if data is valid
                                eyeP = 1;
                                break;
                            end
                        end
                    end % if sample available
                end
                if eyeP break; end
            else
                WaitSecs(dur.stim);
            end
            
            % Blank
            Screen('FillRect',wPtr,Gray,wRect);
            Screen('DrawDots',wPtr,[0,0], FPsize,FPcolor,dotsXY,FPtype);
            Screen('Flip',wPtr);
            if ifeyelink
                Eyelink('Message', 'Target_disappear');
            end
            
            [~, secs, keyCode] = KbCheck;
            touch = 0;
            while ~(touch&&(keyCode(EscapeKey)||keyCode(YesKey)|| keyCode(NoKey)||keyCode(RepeatKey)))
                [touch, secs, keyCode] = KbCheck;
            end
            
            if ~keyCode(RepeatKey)
                redo = 0;
            end
            
            if keyCode(YesKey)
                thisCorrect = 1;
                Screen('FillRect',wPtr,Gray,wRect);
                Screen('DrawDots',wPtr,[0,0], FPsize,[0 255 0],dotsXY,FPtype);
                Screen('Flip',wPtr);
                beep
            elseif keyCode(NoKey)
                thisCorrect = 0;
                Screen('FillRect',wPtr,Gray,wRect);
                Screen('DrawDots',wPtr,[0,0], FPsize,[255 0 0],dotsXY,FPtype);
                Screen('Flip',wPtr);
                sound(yy,Fs);
                if feedback
                    WaitSecs(dur.delay);
                    beep
                end
            elseif keyCode(NoKey)
                thisCorrect = 0;
                if feedback
                    WaitSecs(dur.delay);
                    sound(yy,Fs);
                end
            elseif keyCode(EscapeKey)
                Screen('CloseAll');
                reset_test_gamma;
                
                if ifeyelink
                    %% STEP 7.5.1 stop recor  ding
                    WaitSecs(0.1);
                    Eyelink('StopRecording');
                    WaitSecs(0.001);
                    Eyelink('message', 'Experiment end by escapeKey %s',KbName(EscapeKey));
                end
            end
            
            WaitSecs(0.5)
            if ifeyelink
                if keyCode(DriftCorrestKey)
                    dc = 1;
                end
            end
        end
        
        if ifeyelink
            % do drift correct every 10 trials or decide by experimenter
            if eyeP || dc
                WaitSecs(0.1);
                Eyelink('StopRecording');
                WaitSecs(0.001);
                
                %% STEP 7.2
                % Do a drift correction at the beginning of each trial
                % Performing drift correction (checking) is optional for
                % EyeLink 1000 eye trackers.
                EyelinkDoDriftCorrection(el,wCx,wCy);
                %         eyeLinktime1=GetSecs;
                %         eyeLinktime(trial)=GetSecs-tstart;
                
                eye_used = Eyelink('EyeAvailable'); % get eye that's tracked
                if eye_used == el.BINOCULAR % if both eyes are tracked
                    eye_used = el.LEFT_EYE; % use left eye
                end
                
                %% STEP 7.3
                % start recording eye position (preceded by a short pause so that
                % the tracker can finish the mode transition)
                % The paramerters for the 'StartRecording' call controls the
                % file_samples, file_events, link_samples, link_events availability
                Eyelink('Command', 'set_idle_mode');
                WaitSecs(0.05);
                Eyelink('StartRecording', 1, 1, 1, 1);
                % record a few samples before we actually start displaying
                % otherwise you may lose a few msec of data
            end
        end
        
        if ~eyeP
            history.correct = [history.correct thisCorrect];
            history=staircaseUpdate(history, pStaircase, nTrials);
            reversal=sum(history.isReversal);
            
            result{block}.ori(nTrials) = orientation;
            result{block}.fre(nTrials) = frequency;
            result{block}.key(nTrials) = key;
            result{block}.resp(nTrials) = thisCorrect;
            nTrials = nTrials+1;
        else
            eyeTrial = eyeTrial + 1;
        end
        
    end
    
    if ifeyelink
        %% STEP 7.5.2 stop recording
        Eyelink('StopRecording');
        
        %% STEP 8
        % End of Experiment; close the file first
        % close graphics window, close data file and shut down tracker
        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.5);
        
        %close the eye tracker.
        Eyelink('ShutDown');
    end
    
    %% Break for a while
    Text='Break for a while...';
    Screen('TextSize',wPtr,30);
    Screen('FillRect',wPtr,Gray,wRect);
    Screen('DrawText',wPtr,Text,300,v/2,Black);
    Screen('Flip',wPtr);
    WaitSecs(dur.rest);
    
    %% Analyse the Staircase and calculate the threshold
    RevIndex=find(history.isReversal==1);
    RevValue=history.testValue(RevIndex);
    RevCalc=RevValue(end-pStaircase.nCalc+1:end);
    threshold = mean(RevCalc)
    
    % plot the figure
    plot(1:double(nTrials),double(history.testValue(1,1:nTrials)),'ko-');
    xlabel('Trial number');
    ylabel('Threshold');
    title('Threshold vs. Trial Number');
    legend(num2str(threshold));
    hold on;
    
    pEye = eyeTrial/(nTrials+eyeTrial);
    
    %save (append) the data
    save([subPath '/pc_learning.mat'],'subjectID','result','block');
    
    fidnew=fopen(fileName,'a');
    fprintf(fidnew, '%s ', subjectID);
    fprintf(fidnew, '%2d ', subrun);
    fprintf(fidnew, '%s ', date);
    fprintf(fidnew, '%s ', type);
    fprintf(fidnew, '%s ', task);
    fprintf(fidnew, '%s ', ifeyelink);
    fprintf(fidnew, '%5.3f ',threshold);
    fprintf(fidnew, '%2d ', ecc);
    fprintf(fidnew, '%2d ', initDiff);
    fprintf(fidnew, '%5.3f ',pEye);
    fprintf(fidnew, '%4.2f ', contrast);
    fprintf(fidnew, '%4.2f ', sigma);
    fprintf(fidnew, '%5.3f ',RevValue);
    fprintf(fidnew, '\n');
    status=fclose(fidnew);
    
    ShowCursor;
    Screen('CloseAll');
    
    reset_test_gamma;
catch
    %this "catch" section executes in case of an error in the "try" section
    %above.  Importantly, it closes the onscreen window if its open.
    Screen('CloseAll');
    reset_test_gamma;
    % Priority(0);
    psychrethrow(psychlasterror);
    ShowCursor;
end
