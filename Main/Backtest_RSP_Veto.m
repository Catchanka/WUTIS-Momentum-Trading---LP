AUM_0 = 100000;

commission = 0.0035;
min_comm_per_order = 0.35;
slippage = 0.001;

% VOLATILITY BAND DEFINITION
band_mult = 1;

% REBALANCING FREQUENCY
trade_freq = 30;

% SIZING METHOD
sizing_type = "vol_target";
target_vol = 0.02;
max_leverage = 4;

clear strat_rsp_veto

% Initialize strategy
strat_rsp_veto.caldt = all_days;
strat_rsp_veto.ret = NaN(length(all_days),1);
strat_rsp_veto.AUM = AUM_0*ones(length(all_days),1);
strat_rsp_veto.ret_spy = NaN(length(all_days),1);
strat_rsp_veto.is_train = train_mask;
strat_rsp_veto.is_test = test_mask;

% Daily SPY returns
spy_daily_data.ret = [NaN; diff(spy_daily_data.ohlc(:,4)) ./ spy_daily_data.ohlc(1:end-1,4)];

for d = 2:length(all_days)

    % Carry previous AUM forward
    strat_rsp_veto.AUM(d) = strat_rsp_veto.AUM(d-1);

    % SPY indexes
    idx_y = find(spy_intra_data.day == all_days(d-1));
    idx = find(spy_intra_data.day == all_days(d));

    % RSP indexes
    idx_rsp = find(rsp_intra_data.day == all_days(d));

    if isempty(idx) || isempty(idx_y) || isempty(idx_rsp)
        continue
    end

    % SPY intraday data
    ohlc = spy_intra_data.ohlc(idx,:);
    vwap = spy_intra_data.vwap(idx,:);
    min_from_open = spy_intra_data.min_from_open(idx,1);
    spx_vol = spy_intra_data.spy_dvol(idx(1));
    open = ohlc(1,1);
    dividend = spy_intra_data.dividends(idx(1));

    % Dividend adjusted previous close
    y_close = spy_intra_data.ohlc(idx_y(end),4) - dividend;

    % Warmup period
    if isnan(spy_intra_data.sigma_open(idx(1))); continue; end
    if strcmp(sizing_type,"vol_target") && isnan(spx_vol); continue; end

    % SPY Noise Area
    UB = max(open,y_close)*(1 + band_mult*spy_intra_data.sigma_open(idx));
    LB = min(open,y_close)*(1 - band_mult*spy_intra_data.sigma_open(idx));

    % Align RSP observations with SPY observations
    spy_time = round(spy_intra_data.caldt(idx)*24*60);
    rsp_time = round(rsp_intra_data.caldt(idx_rsp)*24*60);

    [matched,loc_rsp] = ismember(spy_time,rsp_time);

    rsp_close = NaN(length(idx),1);
    rsp_vwap = NaN(length(idx),1);
    rsp_move_open = NaN(length(idx),1);

    rsp_close(matched) = rsp_intra_data.ohlc(idx_rsp(loc_rsp(matched)),4);
    rsp_vwap(matched) = rsp_intra_data.vwap(idx_rsp(loc_rsp(matched)));
    rsp_move_open(matched) = rsp_intra_data.move_open(idx_rsp(loc_rsp(matched)));

    rsp_available = ~isnan(rsp_close) & ~isnan(rsp_vwap) & ~isnan(rsp_move_open);

    % Original SPY signals
    spy_long = ohlc(:,4)>UB & ohlc(:,4)>vwap;
    spy_short = ohlc(:,4)<LB & ohlc(:,4)<vwap;

    % RSP direction
    rsp_bullish = rsp_close>rsp_vwap & rsp_move_open>0;
    rsp_bearish = rsp_close<rsp_vwap & rsp_move_open<0;

    % Position sizing
    if strcmp(sizing_type,"vol_target")
        shares = floor(strat_rsp_veto.AUM(d-1)/open*min(target_vol/spx_vol,max_leverage));
    elseif strcmp(sizing_type,"full_notional")
        shares = floor(strat_rsp_veto.AUM(d-1)/open);
    end

    % Decision times
    idx_trade = find(mod(min_from_open,trade_freq)==0);

    % RSP DISAGREEMENT VETO
    exposure = NaN(length(ohlc),1);
    current_pos = 0;

    for k = 1:length(idx_trade)

        t = idx_trade(k);

        if current_pos == 0

            % Allow long unless RSP clearly disagrees
            if spy_long(t) && rsp_available(t) && ~rsp_bearish(t)
                current_pos = 1;

            % Allow short unless RSP clearly disagrees
            elseif spy_short(t) && rsp_available(t) && ~rsp_bullish(t)
                current_pos = -1;
            end

        elseif current_pos == 1

            % Reverse only if new short is not contradicted by RSP
            if spy_short(t) && rsp_available(t) && ~rsp_bullish(t)
                current_pos = -1;

            % Original SPY logic controls normal exit
            elseif ~spy_long(t)
                current_pos = 0;
            end

        elseif current_pos == -1

            % Reverse only if new long is not contradicted by RSP
            if spy_long(t) && rsp_available(t) && ~rsp_bearish(t)
                current_pos = 1;

            % Original SPY logic controls normal exit
            elseif ~spy_short(t)
                current_pos = 0;
            end
        end

        exposure(t) = current_pos;
    end

    % Hold position between decision times
    exposure = fillmissing(exposure,'previous');

    % Execute signal one minute later
    exposure = lag_TS(exposure,1);
    exposure(isnan(exposure)) = 0;

    % One minute SPY price changes
    change_1m = [NaN; diff(ohlc(:,4))];

    % Number of orders
    trades_count = sum(abs(diff([exposure;0])),'omitmissing');

    % PnL
    gross_pnl = sum(exposure.*change_1m,'omitmissing')*shares;
    commission_paid = trades_count*max(min_comm_per_order,commission*shares);
    slippage_paid = trades_count*slippage*shares;
    net_pnl = gross_pnl - commission_paid - slippage_paid;

    % Update strategy
    strat_rsp_veto.ret(d) = net_pnl/strat_rsp_veto.AUM(d-1);
    strat_rsp_veto.AUM(d) = strat_rsp_veto.AUM(d-1) + net_pnl;

    % SPY daily return
    idx_spx = find(spy_daily_data.caldt == all_days(d));

    if ~isempty(idx_spx)
        strat_rsp_veto.ret_spy(d) = spy_daily_data.ret(idx_spx);
    end

end