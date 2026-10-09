AUM_0 = 100000; % starting AUM

commission = 0.0035; % commission per share
min_comm_per_order = 0.35; % minimum commission per order
slippage = 0.001; % slippage per share based on the study

% VOLATILITY BAND DEFINITION
band_mult = 1;

% REBALANCING FREQUENCY
trade_freq = 30;

% SIZING METHOD
sizing_type = "vol_target";
target_vol = 0.02;
max_leverage = 4;

% Clear previous strategy logs
clear strat trade_log

% Initialize strategy structure
strat.caldt = all_days;
strat.ret = NaN(length(all_days),1);
strat.AUM = AUM_0*ones(length(all_days),1);
strat.ret_spy = NaN(length(all_days),1);
strat.is_train = train_mask;
strat.is_test = test_mask;

% Daily SPY returns
spy_daily_data.ret = [NaN; diff(spy_daily_data.ohlc(:,4)) ./ spy_daily_data.ohlc(1:end-1,4)];

for d = 2:length(all_days)

    % Carry previous AUM forward unless changed by today's trading
    strat.AUM(d) = strat.AUM(d-1);

    idx_y = find(spy_intra_data.day == all_days(d-1));
    idx = find(spy_intra_data.day == all_days(d));

    ohlc = spy_intra_data.ohlc(idx,:);
    vwap = spy_intra_data.vwap(idx,:);
    min_from_open = spy_intra_data.min_from_open(idx,1);
    spx_vol = spy_intra_data.spy_dvol(idx(1));
    open = ohlc(1,1);
    dividend = spy_intra_data.dividends(idx(1));

    % Dividend-adjusted previous close
    y_close = spy_intra_data.ohlc(idx_y(end),4) - dividend;

    % Skip initial warm-up period
    if isnan(spy_intra_data.sigma_open(idx(1))); continue; end
    if strcmp(sizing_type,"vol_target") && isnan(spx_vol); continue; end

    % Noise Area
    UB = max(open,y_close)*(1 + band_mult*spy_intra_data.sigma_open(idx));
    LB = min(open,y_close)*(1 - band_mult*spy_intra_data.sigma_open(idx));

    % Trading signal
    signal = zeros(length(ohlc),1);
    signal(ohlc(:,4)>UB & ohlc(:,4)>vwap) = 1;
    signal(ohlc(:,4)<LB & ohlc(:,4)<vwap) = -1;

    % Position sizing
    if strcmp(sizing_type,"vol_target")
        shares = floor(strat.AUM(d-1)/open*min(target_vol/spx_vol,max_leverage));
    elseif strcmp(sizing_type,"full_notional")
        shares = floor(strat.AUM(d-1)/open);
    end

    % Trade every 30 minutes
    idx_trade = find(mod(min_from_open,trade_freq)==0);

    % One-minute price changes
    change_1m = [NaN; diff(ohlc(:,4))];

    % Exposure
    exposure = NaN(length(signal),1);
    exposure(idx_trade) = signal(idx_trade);
    exposure = fillmissing(exposure,'previous');
    exposure = lag_TS(exposure,1);
    exposure(isnan(exposure)) = 0;

    % Number of executed orders
    trades_count = sum(abs(diff([exposure;0])),'omitmissing');

    % PnL
    gross_pnl = sum(exposure.*change_1m,'omitmissing')*shares;
    commission_paid = trades_count*max(min_comm_per_order,commission*shares);
    slippage_paid = trades_count*slippage*shares;
    net_pnl = gross_pnl - commission_paid - slippage_paid;

    % Strategy return and AUM
    strat.ret(d) = net_pnl/strat.AUM(d-1);
    strat.AUM(d) = strat.AUM(d-1) + net_pnl;

    % SPY daily return
    idx_spx = find(spy_daily_data.caldt == all_days(d));
    if ~isempty(idx_spx)
        strat.ret_spy(d) = spy_daily_data.ret(idx_spx);
    end
end



