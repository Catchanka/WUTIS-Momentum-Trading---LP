rf_annual = 0;
rf_daily = (1 + rf_annual)^(1/252) - 1;

period_start = datenum({'01-Jan-2016','01-Jan-2019','01-Jan-2022'});
period_end   = datenum({'31-Dec-2018','31-Dec-2021','30-Apr-2024'});
period_name  = {'2016-2018'; '2019-2021'; '2022-Apr2024'};

base_ret = NaN(3,1); veto_ret = NaN(3,1);
base_vol = NaN(3,1); veto_vol = NaN(3,1);
base_sr  = NaN(3,1); veto_sr  = NaN(3,1);

for p = 1:3

    valid = strat.caldt >= period_start(p) & strat.caldt <= period_end(p) & ...
        ~isnan(strat.ret) & ~isnan(strat_rsp_veto.ret);

    r_base = strat.ret(valid);
    r_veto = strat_rsp_veto.ret(valid);

    base_ret(p) = (prod(1+r_base)^(252/length(r_base))-1)*100;
    veto_ret(p) = (prod(1+r_veto)^(252/length(r_veto))-1)*100;

    base_vol(p) = std(r_base)*sqrt(252)*100;
    veto_vol(p) = std(r_veto)*sqrt(252)*100;

    base_sr(p) = mean(r_base-rf_daily)/std(r_base)*sqrt(252);
    veto_sr(p) = mean(r_veto-rf_daily)/std(r_veto)*sqrt(252);
end

subperiods = table( ...
    base_ret,veto_ret,base_vol,veto_vol,base_sr,veto_sr, ...
    'VariableNames',{'BaselineReturn','VetoReturn','BaselineVol','VetoVol','BaselineSharpe','VetoSharpe'}, ...
    'RowNames',period_name);

disp(subperiods)