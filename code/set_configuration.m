function config = set_configuration(subpath)
config.learningType = input('PL or CL learning( 1 for PL, 2 for CL): ');
config.task = input('RB or II task( 1 for RB, 2 for II): ');
config.rule = input('Training rule( 1 or 2): ');
config.location = input('Training location (1 for dl, 2 for dr): ');

configName = [subpath '/config_file.mat'];
save(configName,'config');
end