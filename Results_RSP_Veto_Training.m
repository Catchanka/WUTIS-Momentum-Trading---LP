rf_annual = 0;
rf_daily = (1 + rf_annual)^(1/252) - 1;

% Use identical observations for all strategies
valid = ~isnan(strat.ret) & ...
    ~isnan(strat_rsp.ret) & ...
    ~isnan(strat_rsp_veto.ret) & ...
    ~isnan(strat.ret_spy) & ...
    strat.is_train;

base_train = strat.ret(valid);
rsp_confirm_train = strat_rsp.ret(valid);
rsp_veto_train = strat_rsp_veto.ret(valid);
spy_train = strat.ret_spy(valid);

% PAPER BASELINE
base_annret = (prod(1+base_train)^(252/length(base_train))-1)*100;
base_vol = std(base_train)*sqrt(252)*100;
base_sr = mean(base_train-rf_daily)/std(base_train)*sqrt(252);

% STRICT RSP CONFIRMATION
confirm_annret = (prod(1+rsp_confirm_train)^(252/length(rsp_confirm_train))-1)*100;
confirm_vol = std(rsp_confirm_train)*sqrt(252)*100;
confirm_sr = mean(rsp_confirm_train-rf_daily)/std(rsp_confirm_train)*sqrt(252);

% RSP DISAGREEMENT VETO
veto_annret = (prod(1+rsp_veto_train)^(252/length(rsp_veto_train))-1)*100;
veto_vol = std(rsp_veto_train)*sqrt(252)*100;
veto_sr = mean(rsp_veto_train-rf_daily)/std(rsp_veto_train)*sqrt(252);

% SPY
spy_annret = (prod(1+spy_train)^(252/length(spy_train))-1)*100;
spy_vol = std(spy_train)*sqrt(252)*100;
spy_sr = mean(spy_train-rf_daily)/std(spy_train)*sqrt(252);

comparison_train = table( ...
    [base_annret; confirm_annret; veto_annret; spy_annret], ...
    [base_vol; confirm_vol; veto_vol; spy_vol], ...
    [base_sr; confirm_sr; veto_sr; spy_sr], ...
    'VariableNames',{'AnnualizedReturn','AnnualizedVolatility','SharpeRatio'}, ...
    'RowNames',{'Paper_Baseline','RSP_Confirmed','RSP_Veto','SPY'});

disp(comparison_train)