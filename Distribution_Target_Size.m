function [target_size, target_size_fit] = Distribution_Target_Size

% simulating the practice trial from a participant - will establish the
% probability - target size relationship

% create close values
a = -0.5; % min range
b = 0.5; % max range
n_close_trials = 80;
close_trials = (b-a).*rand(n_close_trials,1) + a;

% create mid values
a = -2; % min range
b = 2; % max range
n_mid_trials = 20;
mid_trials = (b-a).*rand(n_mid_trials,1) + a;

% create far values
a = -4; % min range
b = 4; % max range
n_far_trials = 20;
far_trials = (b-a).*rand(n_far_trials,1) + a;


trials = [close_trials' mid_trials' far_trials'];

% Option 1  - normal distribution fit using pdf and icdf

pd = fitdist(trials','Normal');

x_pdf = [-5:0.1:5];
y = pdf(pd,x_pdf);
 
figure
histogram(trials,20,'Normalization','pdf')
line(x_pdf,y)

for k=1:99

    A(k) = icdf(pd,k/100);

end

for k=1:99

    i = (k/2)/100;
    target_size_fit_probs(k,:) = icdf(pd,[i 1-i]);
    target_size_fit(k) = abs(target_size_fit_probs(k,1) - target_size_fit_probs(k,2));

end
target_size_fit = flip(target_size_fit);


% Option 2  - normal distribution z-scores

trials_mean = mean(trials);
trials_std = std(trials);
variability_data = (trials - trials_mean)/trials_std;
normal_distriution_test = kstest(variability_data); % tests the normal distribution (assumes mean=0 and uses std): 0 = normal distribution

probabilities_hit = 0:0.01:1;
probabilities_miss = 1 - probabilities_hit;

% this is calculating the target size for each respective probability
z_scores = norminv((1-probabilities_hit)/2,0,trials_std);
z_scores_test = norminv((1-probabilities_hit)/2,0,1);
target_size = abs((z_scores * trials_std) + 0);
target_size = target_size(2:100);

end