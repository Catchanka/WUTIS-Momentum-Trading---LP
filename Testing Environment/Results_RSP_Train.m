rf_annual = 0;
rf_daily = (1 + rf_annual)^(1/252) - 1;

% Training observations only
base_valid = ~isnan(strat.ret) & ~isnan(strat.ret_spy) & strat.is_train;
rsp_valid = ~isnan(strat_rsp.ret) & ~isnan(strat_rsp.ret_spy) & strat_rsp.is_train;

base_train = strat.ret(base_valid);
rsp_train = strat_rsp.ret(rsp_valid);
spy_train = strat.ret_spy(base_valid);

% Baseline
base_annret = (prod(1+base_train)^(252/length(base_train))-1)*100;
base_vol = std(base_train)*sqrt(252)*100;
base_sr = mean(base_train-rf_daily)/std(base_train)*sqrt(252);

% RSP confirmed strategy
rsp_annret = (prod(1+rsp_train)^(252/length(rsp_train))-1)*100;
rsp_vol = std(rsp_train)*sqrt(252)*100;
rsp_sr = mean(rsp_train-rf_daily)/std(rsp_train)*sqrt(252);

% SPY
spy_annret = (prod(1+spy_train)^(252/length(spy_train))-1)*100;
spy_vol = std(spy_train)*sqrt(252)*100;
spy_sr = mean(spy_train-rf_daily)/std(spy_train)*sqrt(252);

comparison_train = table( ...
    [base_annret; rsp_annret; spy_annret], ...
    [base_vol; rsp_vol; spy_vol], ...
    [base_sr; rsp_sr; spy_sr], ...
    'VariableNames',{'AnnualizedReturn','AnnualizedVolatility','SharpeRatio'}, ...
    'RowNames',{'Paper_Baseline','RSP_Confirmed','SPY'});

disp(comparison_train)

periods = categorical({'Paper Baseline','RSP Confirmed','SPY'});

figure();
tiledlayout(1,3);

nexttile
bar(periods,[base_annret rsp_annret spy_annret]);
ylabel('Annualized Return (%)');
title('Annualized Return');
grid on

nexttile
bar(periods,[base_vol rsp_vol spy_vol]);
ylabel('Annualized Volatility (%)');
title('Annualized Volatility');
grid on

nexttile
bar(periods,[base_sr rsp_sr spy_sr]);
ylabel('Sharpe Ratio');
title('Sharpe Ratio');
grid on

sgtitle('Training Performance: Paper vs RSP Confirmation');