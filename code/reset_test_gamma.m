function reset_test_gamma

  % load gamma table
    clear reset
    
    load([pwd '\reset_gamma.mat'],'reset_gamma_table');
    
    Screen('loadnormalizedgammatable',0,reset_gamma_table);
