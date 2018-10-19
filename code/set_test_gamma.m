function set_test_gamma
	% return;
    % load gamma table
    load([pwd '\Clut.mat'],'Clut');
    
    Screen('loadnormalizedgammatable',0,Clut);
    
    