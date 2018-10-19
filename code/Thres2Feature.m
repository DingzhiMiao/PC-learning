function [ ori_std, freq_std ] = Thres2Feature( F_type, thres )
%Thres2Feature turns Treshold to ori and freq values
%    [ ori_std, freq_std ] = Thres2Feature( F_type, thres )
%           Input: F_type: type of the Learning, 'RB', 'II_1', 'II_2'
%                     thres: thres want to transform
%           Output: ori_std, freq_std: between [0 100]

switch F_type
    case 'RB'
        y_func = '50';
        if rand > 0.5
            move_dir = 1;
        else
            move_dir = -1;
        end;
        x = rand * 100;
        eval(['ori_std = ' y_func ' + move_dir * thres']);
        freq_std = x;
    case 'II_1'
        y_func = 'x';
        if rand > 0.5
            move_dir = 1;
            min_x = 0;
            max_x = 100 - thres * sqrt(2);
        else
            move_dir = -1;
            min_x =  thres * sqrt(2);
            max_x = 100;
        end;
        x = rand * (max_x - min_x) + min_x;
        eval(['ori_std = ' y_func ' + move_dir * thres * sqrt(2);']);
        freq_std = x;
    case 'II_2'
        y_func = '100-x';
         if rand > 0.5
            move_dir = -1;
            min_x = 0;
            max_x = 100 - thres * sqrt(2);
        else
            move_dir = 1;
            min_x =  thres * sqrt(2);
            max_x = 100;
        end;
        x = rand * (max_x - min_x) + min_x;
        eval(['ori_std = ' y_func ' + move_dir * thres * sqrt(2);']);
        freq_std = x;
end

