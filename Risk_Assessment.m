clear
clc
close all

[target_size, target_size_fit] = Distribution_Target_Size;


probabilities_hit = 0:0.01:1;
probabilities_miss = 1 - probabilities_hit;


% hit and miss penalties or gains. We will be using time (s) - if hit
% target, we will subtract E_hit(i) to the final time performing the task -
% if miss target, we will add time
E_hit = [-0.5 -1 -1.5 -2 -2.5 -3 -3.5 -4 -4.5 -5 -5.5 -6 -6.5 -7 -7.5 -8 -8.5 -9 -9.5 -10];
E_miss = [0.5 1 1.5 2 2.5 3 3.5 4 4.5 5 5.5 6 6.5 7 7.5 8 8.5 9 9.5 10];
%E_miss = [11.5 12 12.5 13 13.5 14 14.5 15 15.5 16 16.5 17 17.5 18 18.5 19 19.5 20 20.5 21];



i=1;

for t = 1:20
    for u = 1:20
        for w = 1:101
            
            mean_effort(i) = (E_hit(t) .* probabilities_hit(w)) + (E_miss(u) .* probabilities_miss(w));
            
            variance(i) = (((E_hit(t) - mean_effort(i))^2) * probabilities_hit(w)) + (((E_miss(t) - mean_effort(i))^2) * probabilities_miss(w));

            combinations(i,:) = [E_hit(t) probabilities_hit(w) E_miss(u) probabilities_miss(w) mean_effort(i) variance(i)];

            i = i + 1;

        end
    end
end


% find index of target variance
lotteries_low_idx = find(variance >= 8.5 & variance <= 12.5); % 10 +/- 2.5
lotteries_high_idx = find(variance >= 27.5 & variance <= 32.5); % 30 +/- 2.5


% find combinations corresponding to target variance
lotteries_low_combinations = sortrows(combinations(lotteries_low_idx,:),5);
lotteries_high_combinations = sortrows(combinations(lotteries_high_idx,:),5);

% Delete 0 and 1 probabilities 
lotteries_low_combinations(lotteries_low_combinations(:, 2) < 0.01 | lotteries_low_combinations(:, 2) > 0.99, :) = []; 
lotteries_high_combinations(lotteries_high_combinations(:, 2) < 0.01 | lotteries_high_combinations(:, 2) > 0.99, :) = []; 

%%% START THE TRIAL %%%%%%

% We are adding 10 to the mean effort guess to avoid negative values
mean_effort_trial_guess = 10;
% We are adding 10 to the lotteries_low/high_combinations(:,5) to avoid negative values
q_low = Psychtoolbox_demo_function(mean_effort_trial_guess,lotteries_low_combinations(:,5)+10,lotteries_low_combinations,target_size_fit);
close all
q_high = Psychtoolbox_demo_function(mean_effort_trial_guess,lotteries_high_combinations(:,5)+10,lotteries_high_combinations,target_size_fit);

save('q_low','q_low');
save('q_high','q_high');

Plot_Indifference_Curve(q_low,q_high);
