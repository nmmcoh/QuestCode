function Plot_Indifference_Curve(q_low,q_high)

close all

figure(1)
plot(q_low.trial_data(:,2));
hold on
plot(q_high.trial_data(:,2), 'b-', 'LineWidth', 2);
legend('low','high');


figure(2)
% plot q_low data
mdl = fitglm(q_low.trial_data(:,2), q_low.trial_data(:,1), 'Distribution', 'binomial');
xnew = linspace(-10, 10, 200)';
ynew = predict(mdl, xnew);

scatter(q_low.trial_data(:,2),q_low.trial_data(:,1),'filled');
ylim([-0.1 1.1]) 
hold on
plot(xnew, ynew, 'r-', 'LineWidth', 2);

% plot q_high data
mdl = fitglm(q_high.trial_data(:,2), q_high.trial_data(:,1), 'Distribution', 'binomial');
xnew = linspace(-10, 10, 200)';
ynew = predict(mdl, xnew);

scatter(q_high.trial_data(:,2),q_high.trial_data(:,1),'filled');
ylim([-0.1 1.1]) 
plot(xnew, ynew, 'r-', 'LineWidth', 2);



figure(3)
% plot q_low data
scatter(q_low.trial_data(:,2),q_low.trial_data(:,1),'filled');
hold on
x = q_low.x2+QuestMean(q_low);
x =  10 .^ x;
x = (x * 200)-10;
plot(x,-q_low.p2+1); grid on; %%%%% we are negating q.p2 and adding 1 to match the scatter plot data
% set(gca,'YTick',ytick);
set(gca,'XLim',[-10 10]);
xlabel('Stimulus intensity');
ylabel('Percent correct');
line([-10,10],[q_low.pThreshold,q_low.pThreshold],'LineStyle','--','Color','k')
line([q_low.finalThreshold,q_low.finalThreshold],[0,1],'LineStyle','--','Color','k')
errorbar(q_low.finalThreshold,q_low.pThreshold,q_low.CI95(2)-q_low.CI95(1),'horizontal') 

% plot q_high data
scatter(q_high.trial_data(:,2),q_high.trial_data(:,1),'filled');
hold on
x = q_high.x2+QuestMean(q_high);
x =  10 .^ x;
x = (x * 200)-10;
plot(x,-q_high.p2+1); grid on; %%%%% we are negating q.p2 and adding 1 to match the scatter plot data
% set(gca,'YTick',ytick);
set(gca,'XLim',[-10 10]);
xlabel('Stimulus intensity');
ylabel('Percent correct');
line([-10,10],[q_high.pThreshold,q_high.pThreshold],'LineStyle','--','Color','k')
line([q_high.finalThreshold,q_high.finalThreshold],[0,1],'LineStyle','--','Color','k')
errorbar(q_high.finalThreshold,q_high.pThreshold,q_high.CI95(2)-q_high.CI95(1),'horizontal') 
legend('' ,'low','','','','','high');

end