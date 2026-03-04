function Risk_Assessment_figure(hit_width,lottery_new_trial_values)
hit_width = hit_width + 0.4;% 0.2 is the diameter of the circle
hit_position = 5 - (hit_width/2);

miss_txt = ['+' num2str(lottery_new_trial_values(3))];
hit_txt = [num2str(lottery_new_trial_values(1))];
prob_hit_txt = num2str(lottery_new_trial_values(2));

figure
r = rectangle('Position',[0 8 10 0.5]);
axis([0 10 0 10])
r.FaceColor = 'r';

drawcircle('Center',[5,1],'Radius',0.1,'StripeColor','k');

g = rectangle('Position',[hit_position 8 hit_width 0.5]);
g.FaceColor = 'g';

text(3,9,miss_txt,'FontSize',14)
text(4.9,9,hit_txt,'FontSize',14)
text(4.7,7.5,prob_hit_txt,'FontSize',14)
end