function q = Psychtoolbox_demo_function(initialGuess,lotteries_1_mean_efforts,lotteries_1_combinations,target_size)


% 1. Create QUEST structure
UpperLimit = 200;
tGuess = log10(initialGuess/UpperLimit); 
tGuessSd = 0.2;
beta = 10; % slope
delta = 0.001; % lapse rate
gamma = 0; % sucess when guessing
pThreshold=0.5;%0.82

q = QuestCreate(tGuess, tGuessSd, pThreshold, beta, delta, gamma);
tTest = tGuess;

% 2. Set number of trials
nTrials = 40;

% 3. Main experiment loop
for trial = 1:nTrials


    % Present stimulus (for example, using Screen)
    disp(['Try new intensity -> ', num2str(tTest)]);
    disp(['Try new intensity (unlogged) -> ', num2str(((10^tTest)*200))]);
    % Collect participant response (0 = incorrect, 1 = correct)

    [new_target_size, lotteries_1_new_trial_values] = Extract_Combination_Values(((10^tTest)*200),lotteries_1_mean_efforts,lotteries_1_combinations,target_size);
    Risk_Assessment_figure(new_target_size,lotteries_1_new_trial_values)

    response = input(['Trial ', num2str(trial), ', go(0)/no go(1) -> ']);
    % response = intensity>true_value;


    % save data
    mean_effort_error = ((10^(tTest))*200) - lotteries_1_new_trial_values(5);
    q.trial_data(trial,:) = [response, ((10^(tTest))*200)-10, lotteries_1_new_trial_values(5), mean_effort_error-10, lotteries_1_new_trial_values(6)];
    q.trial_combination(trial,:) = lotteries_1_new_trial_values;



    % Update QUEST with the response
    q = QuestUpdate(q, tTest, response);
    tTest = QuestMean(q);
    q=QuestRecompute(q);

end


% 4. Final threshold estimate
q.finalThreshold = ((10^(tTest))*200)-10; % unlogged and subtract 10 to rescale
disp(['Estimated threshold = ', num2str(q.finalThreshold)]);

% 5. Final 95% CI calculation
q.finalSD = std(q.trial_data(:,2));
SE = q.finalSD/sqrt(40);
q.CI95 = [q.finalThreshold - (1.96 * SE) q.finalThreshold + (1.96 * SE)];

end