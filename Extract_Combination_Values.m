function [new_target_size, lotteries_1_new_trial_values] = Extract_Combination_Values(mean_effort_trial_guess,lotteries_1_mean_efforts,lotteries_1_combinations,target_size)





% find indices corresponding to target mean effort for trial
[~,lotteries_1_mean_efforts_idx] = min(abs(lotteries_1_mean_efforts - mean_effort_trial_guess));
mean_effort_trial_actual = lotteries_1_mean_efforts(lotteries_1_mean_efforts_idx);

% randomize mean effort for trial
rand_lotteries_1_mean_efforts_idx = randperm(numel(lotteries_1_mean_efforts_idx));

% Select new combination values
lotteries_1_new_trial_values = lotteries_1_combinations(lotteries_1_mean_efforts_idx(rand_lotteries_1_mean_efforts_idx(1)),:);
disp(lotteries_1_new_trial_values);
% Determine width corresponding to probability
new_target_size = target_size(round(lotteries_1_new_trial_values(2)*100));

end