function set_test_gamma
	% return;
    % load gamma table
%     path=fileparts(which('veriner_noise.m'));
    load('D:\XXY\vernier_noise\Clut.mat','Clut');
    
    Screen('loadnormalizedgammatable',0,Clut);
    
    