
close all
difficulty = 15;
for i = 1:20

    % orientation frequency
    [ ori_std, freq_std, key] = Thres2Feature( type, difficulty );
    if task== 'RB'
        orientation = rule + ori_std/100*(oriRange(2)-oriRange(1))-(oriRange(2)-oriRange(1))/2;
    else
        orientation = ori_std/100*(oriRange(2)-oriRange(1))+oriRange(1);
    end
    frequency = freq_std/100*(freRange(2)-freRange(1))+freRange(1);
    figure(1)
    subplot(4,10,i*2)
    if key == 1
        plot(frequency,orientation,'ro')
        figure(2)
        plot(frequency,orientation,'ro')
        hold on
    else
        plot(frequency,orientation,'bo')
        figure(2)
        plot(frequency,orientation,'bo')
        hold on
    end
    %     hold on
    figure(1)
    xlim([1,8])
    ylim([0 90]);
    title(num2str(key))
    axis square
    %% make gabor
    orientation = -orientation;
    sti=MyGabor(PixelPerDeg, 1, patchxextd, 1, patchyextd, contrast, frequency, sigma, phase1, orientation, locCx, locCy);
    stiPatch=(sti+1)/2;
    figure(1)
    subplot(4,10,i*2-1)
    imshow(stiPatch);
    title(num2str(key))
end
figure(1)
suptitle(['difficulty = ' num2str(difficulty)]);
figure(2)
xlim([1,8])
ylim([0 90]);
axis square
 plot([1,8],[45,45],'-k')
plot([4.5 4.5],[0,90],'-k')
title(['difficulty = ' num2str(difficulty)])
