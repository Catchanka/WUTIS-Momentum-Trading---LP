rf_annual = 0;
rf_daily = (1 + rf_annual)^(1/252) - 1;

% Common valid observations
valid = ~isnan(strat.ret) & ~isnan(strat_rsp_veto.ret) & ~isnan(strat.ret_spy);
train_valid = valid & strat.is_train;
test_valid = valid & strat.is_test;

if ~any(train_valid) || ~any(test_valid)
    error('Not enough valid observations in either the training or testing period.');
end

% Returns
base_train = strat.ret(train_valid);
veto_train = strat_rsp_veto.ret(train_valid);
spy_train = strat.ret_spy(train_valid);

base_test = strat.ret(test_valid);
veto_test = strat_rsp_veto.ret(test_valid);
spy_test = strat.ret_spy(test_valid);

% TRAIN METRICS
base_train_ret = (prod(1+base_train)^(252/length(base_train))-1)*100;
veto_train_ret = (prod(1+veto_train)^(252/length(veto_train))-1)*100;
spy_train_ret  = (prod(1+spy_train)^(252/length(spy_train))-1)*100;

base_train_vol = std(base_train)*sqrt(252)*100;
veto_train_vol = std(veto_train)*sqrt(252)*100;
spy_train_vol  = std(spy_train)*sqrt(252)*100;

base_train_sr  = mean(base_train-rf_daily)/std(base_train)*sqrt(252);
veto_train_sr  = mean(veto_train-rf_daily)/std(veto_train)*sqrt(252);
spy_train_sr   = mean(spy_train-rf_daily)/std(spy_train)*sqrt(252);

% TEST METRICS
base_test_ret = (prod(1+base_test)^(252/length(base_test))-1)*100;
veto_test_ret = (prod(1+veto_test)^(252/length(veto_test))-1)*100;
spy_test_ret  = (prod(1+spy_test)^(252/length(spy_test))-1)*100;

base_test_vol = std(base_test)*sqrt(252)*100;
veto_test_vol = std(veto_test)*sqrt(252)*100;
spy_test_vol  = std(spy_test)*sqrt(252)*100;

base_test_sr  = mean(base_test-rf_daily)/std(base_test)*sqrt(252);
veto_test_sr  = mean(veto_test-rf_daily)/std(veto_test)*sqrt(252);
spy_test_sr   = mean(spy_test-rf_daily)/std(spy_test)*sqrt(252);

% Comparison table
comparison_rsp = table( ...
    [base_train_ret; veto_train_ret; spy_train_ret; base_test_ret; veto_test_ret; spy_test_ret], ...
    [base_train_vol; veto_train_vol; spy_train_vol; base_test_vol; veto_test_vol; spy_test_vol], ...
    [base_train_sr; veto_train_sr; spy_train_sr; base_test_sr; veto_test_sr; spy_test_sr], ...
    'VariableNames',{'AnnualizedReturn','AnnualizedVolatility','SharpeRatio'}, ...
    'RowNames',{'Baseline_Train','RSP_Veto_Train','SPY_Train', ...
                'Baseline_Test','RSP_Veto_Test','SPY_Test'});

disp(comparison_rsp)

%% TRAIN / TEST COMPARISON BAR CHARTS
periods = categorical({'Train','Test'});
periods = reordercats(periods,{'Train','Test'});

fig = figure();
tiledlayout(1,3);

% Colors
c_base = 'g';   % Paper Baseline
c_veto = 'c';   % RSP Veto
c_spy  = 'r';   % SPY

nexttile
b = bar(periods,[base_train_ret veto_train_ret spy_train_ret; ...
                 base_test_ret veto_test_ret spy_test_ret]);
b(1).FaceColor = c_base;
b(2).FaceColor = c_veto;
b(3).FaceColor = c_spy;
ylabel('Annualized Return (%)');
title('Annualized Return');
legend('Paper Baseline','RSP Veto','SPY','Location','best');
grid on; set(gca,'GridLineStyle',':');
set(gca,'FontSize',8);

nexttile
b = bar(periods,[base_train_vol veto_train_vol spy_train_vol; ...
                 base_test_vol veto_test_vol spy_test_vol]);
b(1).FaceColor = c_base;
b(2).FaceColor = c_veto;
b(3).FaceColor = c_spy;
ylabel('Annualized Volatility (%)');
title('Annualized Volatility');
grid on; set(gca,'GridLineStyle',':');
set(gca,'FontSize',8);

nexttile
b = bar(periods,[base_train_sr veto_train_sr spy_train_sr; ...
                 base_test_sr veto_test_sr spy_test_sr]);
b(1).FaceColor = c_base;
b(2).FaceColor = c_veto;
b(3).FaceColor = c_spy;
ylabel('Sharpe Ratio');
title('Sharpe Ratio');
grid on; set(gca,'GridLineStyle',':');
set(gca,'FontSize',8);

sgtitle('Paper Strategy vs RSP Veto Strategy');

%% EQUITY CURVES
strat.AUM_SPY = AUM_0*cumprod(1 + strat.ret_spy,'omitnan');
plotDates = datetime(strat.caldt,'ConvertFrom','datenum');

fig = figure();
plot(plotDates,strat.AUM,'LineWidth',1,'Color',c_base), hold on
plot(plotDates,strat_rsp_veto.AUM,'LineWidth',1,'Color',c_veto)
plot(plotDates,strat.AUM_SPY,'LineWidth',1,'Color',c_spy)
xline(test_start_date,'--','Test starts');
hold off

grid on; set(gca,'GridLineStyle',':');
xlim([plotDates(1) plotDates(end)]);
tickStart = dateshift(plotDates(1),'start','month');
tickEnd   = dateshift(plotDates(end),'start','month');
tickDates = tickStart:calmonths(6):tickEnd;
tickDates = tickDates(tickDates >= plotDates(1) & tickDates <= plotDates(end));
xticks(tickDates);
xtickformat('MMM yy');
xtickangle(90);
ytickformat('$%,.0f');
ax = gca; ax.YAxis.Exponent = 0;
set(gca,'FontSize',8);

legend('Paper Baseline','RSP Veto','SPY','Test Start','Location','northwest');
title('Paper Baseline vs RSP Veto Strategy','FontWeight','bold','FontSize',12);
subtitle(['Commission = $' num2str(commission) '/share, Slippage = $' num2str(slippage) '/share'],'FontSize',9);