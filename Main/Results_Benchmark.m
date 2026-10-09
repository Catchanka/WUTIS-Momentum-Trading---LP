rf_annual = 0.00; % Annual risk-free rate
rf_daily = (1 + rf_annual)^(1/252) - 1;

% Valid observations
valid = ~isnan(strat.ret) & ~isnan(strat.ret_spy);
train_valid = valid & strat.is_train;
test_valid = valid & strat.is_test;

if ~any(train_valid) || ~any(test_valid)
    error('Not enough valid observations in either the training or testing period.');
end

% Full sample returns
ret_mom = strat.ret(valid);
ret_spy = strat.ret_spy(valid);

% Train returns
ret_mom_train = strat.ret(train_valid);
ret_spy_train = strat.ret_spy(train_valid);

% Test returns
ret_mom_test = strat.ret(test_valid);
ret_spy_test = strat.ret_spy(test_valid);

% Full equity curves
strat.AUM_SPY = AUM_0*cumprod(1 + strat.ret_spy,'omitnan');
plotDates = datetime(strat.caldt,'ConvertFrom','datenum');

fig = figure();
plot(plotDates,strat.AUM,'LineWidth',1,'Color','g'), hold on
plot(plotDates,strat.AUM_SPY,'LineWidth',1,'Color','r')
xline(test_start_date,'--','Test starts');
hold off
grid on; set(gca,'GridLineStyle',':');
xlim([plotDates(1) plotDates(end)]);
tickStart = dateshift(plotDates(1),'start','month');
tickEnd = dateshift(plotDates(end),'start','month');
tickDates = tickStart:calmonths(6):tickEnd;
tickDates = tickDates(tickDates >= plotDates(1) & tickDates <= plotDates(end));
xticks(tickDates);
xtickformat('MMM yy');
xtickangle(90);
ytickformat('$%,.0f');
ax = gca; ax.YAxis.Exponent = 0;
set(gca,'FontSize',8);
legend('Momentum','SPY','Test Start','Location','northwest');
title('Intraday Momentum Strategy','FontWeight','bold','FontSize',12);
subtitle(['Commission = $' num2str(commission) '/share, Slippage = $' num2str(slippage) '/share'],'FontSize',9);

% Full sample statistics
stats.totret = round((prod(1+ret_mom)-1)*100,0);
stats.irr = round((prod(1+ret_mom)^(252/length(ret_mom))-1)*100,1);
stats.vol = round(std(ret_mom)*sqrt(252)*100,1);
stats.sr = round(mean(ret_mom-rf_daily)/std(ret_mom)*sqrt(252),2);
stats.hr = round(sum(ret_mom>0)/sum(abs(ret_mom)>0)*100,0);
stats.mdd = round(maxdrawdown(strat.AUM)*100,0);
regr = fitlm(ret_spy,ret_mom);
coef = regr.Coefficients.Estimate;
stats.alpha = round(coef(1)*100*252,2);
stats.beta = round(coef(2),2);

% TRAIN METRICS
mom_train_annret = (prod(1+ret_mom_train)^(252/length(ret_mom_train))-1)*100;
spy_train_annret = (prod(1+ret_spy_train)^(252/length(ret_spy_train))-1)*100;
mom_train_vol = std(ret_mom_train)*sqrt(252)*100;
spy_train_vol = std(ret_spy_train)*sqrt(252)*100;
mom_train_sr = mean(ret_mom_train-rf_daily)/std(ret_mom_train)*sqrt(252);
spy_train_sr = mean(ret_spy_train-rf_daily)/std(ret_spy_train)*sqrt(252);

% TEST METRICS
mom_test_annret = (prod(1+ret_mom_test)^(252/length(ret_mom_test))-1)*100;
spy_test_annret = (prod(1+ret_spy_test)^(252/length(ret_spy_test))-1)*100;
mom_test_vol = std(ret_mom_test)*sqrt(252)*100;
spy_test_vol = std(ret_spy_test)*sqrt(252)*100;
mom_test_sr = mean(ret_mom_test-rf_daily)/std(ret_mom_test)*sqrt(252);
spy_test_sr = mean(ret_spy_test-rf_daily)/std(ret_spy_test)*sqrt(252);

% Results table
comparison = table( ...
    [mom_train_annret; spy_train_annret; mom_test_annret; spy_test_annret], ...
    [mom_train_vol; spy_train_vol; mom_test_vol; spy_test_vol], ...
    [mom_train_sr; spy_train_sr; mom_test_sr; spy_test_sr], ...
    'VariableNames',{'AnnualizedReturn','AnnualizedVolatility','SharpeRatio'}, ...
    'RowNames',{'Momentum_Train','SPY_Train','Momentum_Test','SPY_Test'});

disp(comparison)

% TRAIN / TEST COMPARISON PLOTS
periods = categorical({'Train','Test'});
periods = reordercats(periods,{'Train','Test'});

% Colors matching equity curve
c_mom = 'g';
c_spy = 'r';

fig = figure();
tiledlayout(1,3);

% Annualized Return
nexttile
b = bar(periods,[mom_train_annret spy_train_annret; ...
    mom_test_annret spy_test_annret]);
b(1).FaceColor = c_mom;
b(2).FaceColor = c_spy;
ylabel('Annualized Return (%)');
title('Annualized Return');
legend('Momentum','SPY','Location','best');
grid on; set(gca,'GridLineStyle',':');
set(gca,'FontSize',8);

% Annualized Volatility
nexttile
b = bar(periods,[mom_train_vol spy_train_vol; ...
    mom_test_vol spy_test_vol]);
b(1).FaceColor = c_mom;
b(2).FaceColor = c_spy;
ylabel('Annualized Volatility (%)');
title('Annualized Volatility');
grid on; set(gca,'GridLineStyle',':');
set(gca,'FontSize',8);

% Sharpe Ratio
nexttile
b = bar(periods,[mom_train_sr spy_train_sr; ...
    mom_test_sr spy_test_sr]);
b(1).FaceColor = c_mom;
b(2).FaceColor = c_spy;
ylabel('Sharpe Ratio');
title('Sharpe Ratio');
grid on; set(gca,'GridLineStyle',':');
set(gca,'FontSize',8);

sgtitle('Train vs Test Performance');

% Print overall performance metrics
fprintf('\nFULL SAMPLE PERFORMANCE\n');
fprintf('-----------------------------\n');
fprintf('Total Return:        %.0f%%\n',stats.totret);
fprintf('Annualized Return:   %.1f%%\n',stats.irr);
fprintf('Annualized Vol:      %.1f%%\n',stats.vol);
fprintf('Sharpe Ratio:        %.2f\n',stats.sr);
fprintf('Hit Ratio:           %.0f%%\n',stats.hr);
fprintf('Max Drawdown:        %.0f%%\n',stats.mdd);
fprintf('Annualized Alpha:    %.2f%%\n',stats.alpha);
fprintf('Beta:                %.2f\n',stats.beta);

% Print split information
train_days = strat.caldt(strat.is_train);
test_days = strat.caldt(strat.is_test);

fprintf('\nTRAIN/TEST SPLIT\n');
fprintf('-----------------------------\n');
fprintf('Train: %s to %s\n',datestr(train_days(1),'dd-mmm-yyyy'),datestr(train_days(end),'dd-mmm-yyyy'));
fprintf('Test:  %s to %s\n',datestr(test_days(1),'dd-mmm-yyyy'),datestr(test_days(end),'dd-mmm-yyyy'));
fprintf('Train observations: %d\n',length(ret_mom_train));
fprintf('Test observations:  %d\n',length(ret_mom_test));