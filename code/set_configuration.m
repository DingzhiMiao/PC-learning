function config = set_configuration(subpath)
config.learningType = input('PL or CL learning( 1 for PL, 2 for CL): ');
task = input('RB or II task (1 for RB, 2 for II): ');
if task == 1
    config.task = 'RB';
else
    config.task = 'II';
end

if strcmp(config.task, 'RB')
    config.rule = input('Training rule( 36 or 126): ');
    config.type = 'RB';
elseif strcmp(config.task, 'II')
    config.rule = input('Training rule( 1 or 2): ');
    if config.rule == 1
        config.type = 'II_1';
    else
        config.type = 'II_2';
    end
end
config.location = input('Training location (225 for dl, 315 for dr): ');

configName = [subpath '/config_file.mat'];
save(configName,'config');
end