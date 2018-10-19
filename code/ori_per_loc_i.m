function ori_per_loc_i(subject,para)
% FixorChange = 1: fix loction; 2: change location
% SorD = 1: staircase; 2: constant stimuli
% test = 1: pre and post test; 2: training at 1 circle 3: training at 3
% circles
FixorChange = para.FixorChange; SorD = para.SorD; test = para.test;testLoc_start = para.testLoc;
initOri  = para.initOri;testOri = para.testOri;

if FixorChange ==1 && SorD==1 && test ==2
    task = 'FixStair';
elseif FixorChange ==1 && SorD==1 && test==1
    task = 'FixTest';
elseif FixorChange ==2 && SorD==1 && test ==3
    task = 'ChStair3';
elseif FixorChange ==2 && SorD==1 && test ==2
    task = 'ChStair1';
elseif FixorChange ==2 && SorD==2 && test ==2
    task = 'ChD1';
elseif FixorChange ==2 && SorD==2 && test ==3
    task = 'ChD3';
else
    error('The task condition is wrong')
end


commandwindow;
Screen('Preference','Verbosity',0);
Screen('Preference','SkipSyncTests',1);
Screen('Preference','VisualDebugLevel',0);
KbName('UnifyKeyNames');

    %% initialize rand
    if strncmp(version,'7.7',3) || strncmp(version,'7.9',3)
        RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock)));
    elseif strncmp(version,'7.1',3)
        rand('state',sum(100*clock));
    end
    %%%%%%%%%
    
%%  Subj. Info.
% subject = input('Enter the subject ID: ','s');
if strcmp(task, 'FixTest')
    condition  = input('Enter the condition: ','s');
    if  condition == 'a'
        testLoc = testLoc_start;
    elseif condition == 'b'
        if testOri == 1;
        testOri  =3;
        elseif testOri == 3;
            testOri  =1;
        end
                testLoc = testLoc_start;
    elseif condition == 'c'
        if testLoc_start ==7
            testLoc = 1;
        elseif testLoc_start==1
            testLoc = 7;
        end
    end
else
    testLoc = testLoc_start;
end

subrun = input('Enter the run number: ');
if test==3
    EccList = input('Enter the location: ');
end
filepath = fileparts(which('runOri.m'));
eyelink = 'Y';
% testOri = 3;
block = 0;
if exist([filepath '/data/' subject '_oa.mat'],'file')
    load([filepath '/data/' subject '_oa.mat']);
end
block = block + 1;


loc = 30; % the location different between two locations
ori = 45; % the orientation different between two locations
if test==3
    Ecc = EccList*2+1;
else
    Ecc = 5;
end

numLoc = 360/loc;
numOri = 180/ori;

startOri = randi(numOri);
startLoc = randi(numLoc);
if FixorChange == 1
    startOrientation= (testOri-1)*ori+20;
    startLocation = (testLoc-1)*loc+20;
elseif FixorChange ==2
    startLocation = 20+(startLoc-1)*loc; % the start location [20 50 80 110 140 170 200 230 260 290 320 350]
    startOrientation = 20+(startOri-1)*ori;
end
if SorD ==2
    totalTrials = numLoc*numOri*1;
elseif SorD ==1
    totalTrials = numLoc*numOri*2;
end

% initOri = 20;

try
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
    edfFile = ['OA' subject  num2str(block)];
    % the code are in case the subject wrongly input the argument which may replace the old data.
    while  2==exist([filepath '\raw_edf\' edfFile '.edf'],'file')
        disp('Run number was wrong, please check and input agian!');
        %     block = input('Enter the run number: ');
        % edfFile = [subject '_p' num2str(block)];
        
    end
    %% STEP 3  getDisplay %%
    HideCursor;
    
    Screens=Screen('Screens');
    ScnNbr=max(Screens);
    oldResolution=Screen('Resolution', ScnNbr, 1024, 768, 120, 32); % change resolution
    
    set_test_gamma;
    
    [wPtr, wRect]=Screen('OpenWindow', ScnNbr, 0,[],32,2);
    
    framerate=Screen('FrameRate',wPtr);
    FlipInterval=Screen('GetFlipInterval',wPtr);
    [wCx,wCy]=WindowCenter(wPtr);
    Black=BlackIndex(ScnNbr);
    White=WhiteIndex(ScnNbr);
    Gray= round((White+Black)/2);
    
    rectWidth=round(wRect(3));
    h=round(wRect(3));
    v=round(wRect(4));
    %     Text='Orientation discrimination';
    
    DisplaySize=[400 300];
    hpixel=h/DisplaySize(1);vpixel=v/DisplaySize(2);
    distance=1000;
    PixelPerDeg=1/atand(1/hpixel/distance);
    
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
    
    [vv vs]=Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a ''%s'' tracker.\n', vs );
    
    % open file to record data to
    i = Eyelink('Openfile', edfFile);
    if i~=0
        printf('Cannot create EDF file ''%s'' ', edffilename);
        Eyelink( 'Shutdown');
        return;
    end
    
    Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox demo-experiment''');
    [width, height]=Screen('WindowSize', wPtr);
    
    %% STEP 5
    % SET UP TRACKER CONFIGURATION
    % Setting the proper recording resolution, proper calibration type,
    % as well as the data file content;
    Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1);
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
    
    % bkgrC = Black;
    %% STEP 6
    % Calibrate the eye tracker
    % setup the proper calibration foreground and background colors
    el.backgroundcolour = Gray;
    el.foregroundcolour = White;
    EyelinkDoTrackerSetup(el);
    
%     %% initialize rand
%     if strncmp(version,'7.7',3) || strncmp(version,'7.9',3)
%         RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock)));
%     elseif strncmp(version,'7.1',3)
%         rand('state',sum(100*clock));
%     end
%     %%%%%%%%%
    
    %% define key
    TriggerKey = KbName('space');
    EscapeKey = KbName('ESCAPE');
    RepeatKey = KbName('7');
    DriftCorrestKey = KbName('8');
    badbutton = 'Twang';
    [yy Fs bits]=wavread(badbutton);
    
    %% design the background fixation
    % cross
    fixC = [0 0 0];
    fixLength = 40;
    fixWidth = 4;
    fixList = [-1 0; 1 0; 0 1; 0 -1]*fixLength/2;
    fixList = fixList';
    
    % dots
    dotsXY=[wCx,wCy];
    FPsize=0.3*PixelPerDeg;
    FPtype=1;
    FPcolor=255;
    FPgreen=[0 255 0];
    FPred=[255 0 0];
    
    %% gabor stimuli parameters%%
    % 0 reference orientation is vertical
    % reforientation = 36-90;
    frequency=3;       % cpd
    lamda=1/frequency;
    contrast=47;       %
    sigma=0.68;
    phase=90;          %
    % location
    patchxextd=ceil((frequency/3)*5*lamda*PixelPerDeg);  % patch size
    patchyextd=ceil((frequency/3)*5*lamda*PixelPerDeg);  % patch size
    locCx=patchxextd/2;
    locCy=patchyextd/2;
    
    offLocX = round(Ecc*cos(startLocation*pi/180)*PixelPerDeg);
    offLocY = round(-Ecc*sin(startLocation*pi/180)*PixelPerDeg);
    
    %% staircase
    % Start some local variables used to control the staircase
    pStaircase.nUps=3;                   %3-> ~80% success 2->~70% success 1->~50% ssuccess
    pStaircase.initStep =2;              % calculated from after Inital steps dropped
    pStaircase.nChanges=2;               % Num. of reversals after which the step size changes to 1.
    pStaircase.nPractice=1;
    pStaircase.conditionScale = 1;       % This identifies the type of the scale of conditions vector, 0 for linear; 1 for logarithm scale.
    if test ==1
        pStaircase.nReversals=10;            % Num. of reversals to end the staircase
    elseif test == 2
        pStaircase.nReversals=30;            % Num. of reversals to end the staircase
    end
    pStaircase.nCalc =6;                 % Num. of reversals used for computing final threshold
    
    pStaircase.initSetup=initOri;
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
    if eye_used == el.BINOCULAR; % if both eyes are tracked
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
    
    %% The first display %%
    Screen('FillRect',wPtr,Gray,wRect);
    Screen('FrameRect',wPtr,Black,[h/2+offLocX-60,v/2+offLocY-60,h/2+offLocX+60,v/2+offLocY+60],4)
    %     Screen('DrawLines',wPtr,fixList,fixWidth, fixC,[wCx wCy],0);
    Screen('DrawDots',wPtr,[0,0], FPsize,FPcolor,dotsXY,FPtype);
    
    Screen('Flip',wPtr);
    %     HideCursor;
    
    %% Initialize the experiments
    [touch, secs, keyCode] = KbCheck;
    touch = 0;
    while ~(touch&(keyCode(TriggerKey) | keyCode(EscapeKey)))
        [touch, secs, keyCode] = KbCheck;
    end
    if keyCode(EscapeKey)
        Screen('CloseAll');
    end
    
    nTrials = 1;
    reversal = 0;
    eyeTrial = 0;
    if SorD ==2
        difficulty = initOri;
    end
    
    if test ==1
        totalTrials = pStaircase.nReversals;
        runTrials = reversal;
    else
        runTrials = nTrials;
    end
    
    while runTrials <= totalTrials
        redo=1;
        eyeP = 0;
        dc = 0;
        
        if SorD ==1
            difficulty = history.testValue(nTrials);
        end
        
        Eyelink('Message', 'TRIALID %d', nTrials);
        
        while redo==1
            phase1=phase+rand*180;
            phase2=phase-90+rand*180;
            
            %% define location and refOri
            if FixorChange ==2 % change location
                % change orientation & location for each trial
                reforientation =mod(nTrials-1,numOri)*ori+startOrientation;
                if reforientation>180
                    reforientation = reforientation-180;
                end
                location = mod(nTrials-1,numLoc)*loc+startLocation;
                if location>360
                    location = location-360;
                end
                
                if location == (testLoc-1)*loc+20 % change ori at test location to test_ori+90
                    if reforientation == (testOri-1)*ori+20;
                        reforientation = reforientation + 90;
                    end
                end
                
            elseif FixorChange ==1 % fix location
                reforientation = (testOri-1)*ori+20;
                location = (testLoc-1)*loc+20;
            end
            
            if rand>0.5
                ori_int1=reforientation-0.5*difficulty;
                ori_int2=reforientation+0.5*difficulty;
                YesKey=KbName('1');NoKey=KbName('2');
            else
                ori_int1=reforientation+0.5*difficulty;
                ori_int2=reforientation-0.5*difficulty;
                YesKey=KbName('2');NoKey=KbName('1');
            end
            
            offLocX = round(Ecc*cos(location*pi/180))*PixelPerDeg;
            offLocY = round(-Ecc*sin(location*pi/180))*PixelPerDeg;
            
            %% make gabor
            % grayscaleImageMatrix=MyGabor(PixelPerDeg, xor, xextd, yor, yextd, contrast, cycPerDeg, sigma, phase, tiltInDegrees, locCx, locCy)
            RSti=MyGabor(PixelPerDeg, 1, patchxextd, 1, patchyextd, contrast, frequency, sigma, phase1, ori_int1, locCx, locCy);
            TSti=MyGabor(PixelPerDeg, 1, patchxextd, 1, patchyextd, contrast, frequency, sigma, phase2, ori_int2, locCx, locCy);
            
            RStiPatch=round((RSti+1)/2*255);
            TStiPatch=round((TSti+1)/2*255);
            
            Gabor_1intl=Screen('MakeTexture',wPtr,RStiPatch);
            Gabor_2intl=Screen('MakeTexture',wPtr,TStiPatch);
            
            % Define Stimuli Location;
            PicRect=Screen('Rect',Gabor_1intl);
            Pic_center=CenterRect(PicRect,wRect);
            PicLoc=OffsetRect(Pic_center,offLocX,offLocY);
            
            %% Run Trials
            % ITI
            Screen('FillRect',wPtr,Gray,wRect);
            Screen('DrawDots',wPtr,[0,0], FPsize,FPcolor,dotsXY,FPtype);
            Screen('Flip',wPtr);
            WaitSecs(0.500);
            
            % Fixation
            Screen('FillRect',wPtr,Gray,wRect);
            Screen('DrawDots',wPtr,[0,0], FPsize,FPcolor,dotsXY,FPtype);
            Screen('Flip',wPtr);
            WaitSecs(0.500-0.2);
            
            %% make sure fixation
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
            
            %% 1st interval
            Screen('DrawTexture',wPtr,Gabor_1intl,PicRect,PicLoc);
            Screen('DrawDots',wPtr,[0,0], FPsize,FPcolor,dotsXY,FPtype);
            Screen('Flip',wPtr);
            Eyelink('Message', 'Target1_show');
            %             WaitSecs(0.1);
            
            tic
            while toc < 0.1
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
            
            % Blank
            Screen('FillRect',wPtr,Gray,wRect);
            Screen('DrawDots',wPtr,[0,0], FPsize,FPcolor,dotsXY,FPtype);
            Screen('Flip',wPtr);
            Eyelink('Message', 'Target1_disappear');
            WaitSecs(0.500-0.2);
            
            %% make sure fixation
            tic
            while toc < 0.2
                if Eyelink( 'NewFloatSampleAvailable') > 0
                    % get the sample in the form of an event structure
                    evt = Eyelink( 'NewestFloatSample');
                    if eye_used ~= -1 % do we know which eye to use yet?
                        % if we do, get current gaze position from sample
                        x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
                        y = evt.gy(eye_used+1);
                        rr=sqrt((x-wCx)^2+(y-wCy)^2);
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
            
            %         t2=Getsecs;
            %% 2nd interval
            Screen('DrawTexture',wPtr,Gabor_2intl,PicRect,PicLoc);
            Screen('DrawDots',wPtr,[0,0], FPsize,FPcolor,dotsXY,FPtype);
            Screen('Flip',wPtr);
            Eyelink('Message', 'Target2_show');
            %             WaitSecs(0.1);
            
            %% check for presence of a new sample update
            tic
            while toc < 0.1
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
            
            %% Blank for response :
            Screen('FillRect',wPtr,Gray,wRect); %with Fixation:
            Screen('DrawDots',wPtr,[0,0], FPsize,FPcolor,dotsXY,FPtype);
            Screen('Flip',wPtr);
            Eyelink('Message', 'Target2_disappear');
            
            
            [touch, secs, keyCode] = KbCheck;
            touch = 0;
            while ~(touch&(keyCode(EscapeKey)|keyCode(YesKey)| keyCode(NoKey)|keyCode(RepeatKey)))
                [touch, secs, keyCode] = KbCheck;
            end
            
            if ~keyCode(RepeatKey)
                redo=0;
                Eyelink('message','REDO');
            end
            
            if keyCode(YesKey)
                thisCorrect=1;
                beep
            elseif keyCode(NoKey)
                thisCorrect=0;
                sound(yy,Fs,bits);
                
            elseif keyCode(EscapeKey)
                Screen('CloseAll');
                reset_test_gamma;
                %% STEP 7.5.1 stop recor  ding
                WaitSecs(0.1);
                Eyelink('StopRecording');
                WaitSecs(0.001);
                Eyelink('message', 'Experiment end by escapeKey %s',KbName(EscapeKey));
                
            end
            
            % do drift correct every 10 trials or decide by experimenter
            if keyCode(DriftCorrestKey)
                dc = 1;
            end
        end
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
            if eye_used == el.BINOCULAR; % if both eyes are tracked
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
        
        if ~eyeP
            history.correct = [history.correct thisCorrect];
            history=staircaseUpdate(history, pStaircase, nTrials);
            reversal=sum(history.isReversal);
            
            result{block}(nTrials,1) = location;
            result{block}(nTrials,2) = reforientation;
            result{block}(nTrials,3) = thisCorrect;
            nTrials = nTrials+1;
            if test ==1
                runTrials = reversal;
            else
                runTrials = nTrials;
            end
        else
            eyeTrial = eyeTrial + 1;
        end
        
    end
    %% STEP 7.5.2 stop recording
    Eyelink('StopRecording');
    
    %% STEP 8
    % End of Experiment; close the file first
    % close graphics window, close data file and shut down tracker
    Eyelink('Command', 'set_idle_mode');
    WaitSecs(0.5);
    
    %close the eye tracker.
    Eyelink('ShutDown');
    
    %% Break for a while
    Text='Break for a while...';
    Screen('TextSize',wPtr,30);
    Screen('FillRect',wPtr,Gray,wRect);
    Screen('DrawText',wPtr,Text,300,v/2,Black);
    Screen('Flip',wPtr);
    WaitSecs(30);
    
    %% Analyse the Staircase and calculate the threshold
    if SorD == 1
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
    elseif SorD == 2
        threshold = sum(result{block}(:,3))/totalTrials % threshold here means accurate
    end
    pEye = eyeTrial/(nTrials+eyeTrial);
    
    %save (append) the data
    save([filepath '\data\' subject '_oa'],'subject','result','block');
    
    fidnew=fopen([filepath '\data\ori_per_all.dat'],'a');
    fprintf(fidnew, '%s ', subject);
    fprintf(fidnew, '%2d ', subrun);
    fprintf(fidnew, '%s ', date);
    fprintf(fidnew, '%s ', task);
    fprintf(fidnew, '%s ', eyelink);
    fprintf(fidnew, '%5.3f ',threshold);
    fprintf(fidnew, '%2d ',testLoc);
    fprintf(fidnew, '%2d ',testOri);
    fprintf(fidnew, '%2d ', Ecc);
    fprintf(fidnew, '%5.3f ',pEye);
    fprintf(fidnew, '%4.2f ', contrast);
    fprintf(fidnew, '%4.2f ', frequency);
    fprintf(fidnew, '%4.2f ', sigma);
    if SorD == 1
        fprintf(fidnew, '%5.3f ',RevValue);
    end
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