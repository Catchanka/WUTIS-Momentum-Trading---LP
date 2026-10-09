% TEST THE RSP BREADTH HYPOTHESIS
% This script does not change the strategy.
% It only analyzes why the RSP Veto may work.

band_mult_h = 1;
trade_freq_h = 30;

signal_gap = [];
signal_fwd = [];
signal_disagree = [];
signal_train = [];
signal_direction = [];

veto_events = zeros(length(all_days),1);

for d = 2:length(all_days)

    idx_y = find(spy_intra_data.day == all_days(d-1));
    idx = find(spy_intra_data.day == all_days(d));
    idx_rsp = find(rsp_intra_data.day == all_days(d));

    if isempty(idx) || isempty(idx_y) || isempty(idx_rsp)
        continue
    end

    % SPY data
    ohlc = spy_intra_data.ohlc(idx,:);
    vwap = spy_intra_data.vwap(idx,:);
    min_from_open = spy_intra_data.min_from_open(idx,1);
    open = ohlc(1,1);
    dividend = spy_intra_data.dividends(idx(1));

    y_close = spy_intra_data.ohlc(idx_y(end),4) - dividend;

    if isnan(spy_intra_data.sigma_open(idx(1)))
        continue
    end

    % SPY Noise Area
    UB = max(open,y_close)*(1 + band_mult_h*spy_intra_data.sigma_open(idx));
    LB = min(open,y_close)*(1 - band_mult_h*spy_intra_data.sigma_open(idx));

    % Align SPY and RSP timestamps
    spy_time = round(spy_intra_data.caldt(idx)*24*60);
    rsp_time = round(rsp_intra_data.caldt(idx_rsp)*24*60);

    [matched,loc_rsp] = ismember(spy_time,rsp_time);

    rsp_close = NaN(length(idx),1);
    rsp_vwap = NaN(length(idx),1);
    rsp_move = NaN(length(idx),1);

    rsp_close(matched) = rsp_intra_data.ohlc(idx_rsp(loc_rsp(matched)),4);
    rsp_vwap(matched) = rsp_intra_data.vwap(idx_rsp(loc_rsp(matched)));
    rsp_move(matched) = rsp_intra_data.move_open(idx_rsp(loc_rsp(matched)));

    % SPY movement from today's open
    spy_move = ohlc(:,4)./open - 1;

    % Original paper signals
    spy_long = ohlc(:,4)>UB & ohlc(:,4)>vwap;
    spy_short = ohlc(:,4)<LB & ohlc(:,4)<vwap;

    % RSP direction
    rsp_bullish = rsp_close>rsp_vwap & rsp_move>0;
    rsp_bearish = rsp_close<rsp_vwap & rsp_move<0;

    idx_trade = find(mod(min_from_open,trade_freq_h)==0);

    % -------------------------------------------------------------
    % SIGNAL LEVEL ANALYSIS
    % -------------------------------------------------------------

    for k = 1:length(idx_trade)

        t = idx_trade(k);

        if isnan(rsp_move(t))
            continue
        end

        direction = 0;

        if spy_long(t)
            direction = 1;
        elseif spy_short(t)
            direction = -1;
        end

        if direction==0
            continue
        end

        % RSP disagreement with SPY
        if direction==1
            disagreement = rsp_bearish(t);
        else
            disagreement = rsp_bullish(t);
        end

        % Positive gap means SPY is more extreme than RSP
        gap = direction*(spy_move(t)-rsp_move(t));

        % Forward return until next 30-minute decision point
        if k < length(idx_trade)
            t2 = idx_trade(k+1);
        else
            t2 = length(ohlc);
        end

        fwd_return = direction*(ohlc(t2,4)/ohlc(t,4)-1);

        signal_gap = [signal_gap; gap];
        signal_fwd = [signal_fwd; fwd_return];
        signal_disagree = [signal_disagree; disagreement];
        signal_train = [signal_train; train_mask(d)];
        signal_direction = [signal_direction; direction];

    end

    % -------------------------------------------------------------
    % RECONSTRUCT ACTUAL VETO EVENTS
    % -------------------------------------------------------------

    current_pos = 0;

    for k = 1:length(idx_trade)

        t = idx_trade(k);

        if isnan(rsp_move(t))
            continue
        end

        if current_pos==0

            if spy_long(t)
                if rsp_bearish(t)
                    veto_events(d) = veto_events(d) + 1;
                else
                    current_pos = 1;
                end

            elseif spy_short(t)
                if rsp_bullish(t)
                    veto_events(d) = veto_events(d) + 1;
                else
                    current_pos = -1;
                end
            end

        elseif current_pos==1

            if spy_short(t)

                if rsp_bullish(t)
                    veto_events(d) = veto_events(d) + 1;
                    current_pos = 0;
                else
                    current_pos = -1;
                end

            elseif ~spy_long(t)
                current_pos = 0;
            end

        elseif current_pos==-1

            if spy_long(t)

                if rsp_bearish(t)
                    veto_events(d) = veto_events(d) + 1;
                    current_pos = 0;
                else
                    current_pos = 1;
                end

            elseif ~spy_short(t)
                current_pos = 0;
            end
        end
    end
end


%% SIGNAL DISAGREEMENT FREQUENCY

train_signal = signal_train==1;
test_signal = signal_train==0;

train_disagree_rate = mean(signal_disagree(train_signal))*100;
test_disagree_rate = mean(signal_disagree(test_signal))*100;


%% SPY-RSP DIVERGENCE

train_positive_gap = signal_gap(train_signal & signal_gap>0);
test_positive_gap = signal_gap(test_signal & signal_gap>0);

train_gap_mean = mean(train_positive_gap)*100;
test_gap_mean = mean(test_positive_gap)*100;

train_gap90 = prctile(train_positive_gap,90)*100;
test_gap90 = prctile(test_positive_gap,90)*100;


%% FORWARD PERFORMANCE OF SIGNALS

train_agree_fwd = mean(signal_fwd(train_signal & ~signal_disagree))*10000;
train_disagree_fwd = mean(signal_fwd(train_signal & signal_disagree))*10000;

test_agree_fwd = mean(signal_fwd(test_signal & ~signal_disagree))*10000;
test_disagree_fwd = mean(signal_fwd(test_signal & signal_disagree))*10000;

train_agree_hit = mean(signal_fwd(train_signal & ~signal_disagree)>0)*100;
train_disagree_hit = mean(signal_fwd(train_signal & signal_disagree)>0)*100;

test_agree_hit = mean(signal_fwd(test_signal & ~signal_disagree)>0)*100;
test_disagree_hit = mean(signal_fwd(test_signal & signal_disagree)>0)*100;


%% ACTUAL VETO DAYS

valid_daily = ~isnan(strat.ret) & ~isnan(strat_rsp_veto.ret);

train_veto_days = train_mask & veto_events>0 & valid_daily;
test_veto_days = test_mask & veto_events>0 & valid_daily;

train_valid_days = train_mask & valid_daily;
test_valid_days = test_mask & valid_daily;

train_veto_day_rate = sum(train_veto_days)/sum(train_valid_days)*100;
test_veto_day_rate = sum(test_veto_days)/sum(test_valid_days)*100;

% Average daily returns on actual veto days
train_base_veto_ret = mean(strat.ret(train_veto_days))*10000;
train_veto_veto_ret = mean(strat_rsp_veto.ret(train_veto_days))*10000;

test_base_veto_ret = mean(strat.ret(test_veto_days))*10000;
test_veto_veto_ret = mean(strat_rsp_veto.ret(test_veto_days))*10000;

% Average return saved by veto
train_saved_bps = mean(strat_rsp_veto.ret(train_veto_days) - strat.ret(train_veto_days))*10000;
test_saved_bps = mean(strat_rsp_veto.ret(test_veto_days) - strat.ret(test_veto_days))*10000;


%% SUMMARY TABLE

hypothesis_summary = table( ...
    [train_disagree_rate; test_disagree_rate], ...
    [train_veto_day_rate; test_veto_day_rate], ...
    [train_gap_mean; test_gap_mean], ...
    [train_gap90; test_gap90], ...
    [train_agree_fwd; test_agree_fwd], ...
    [train_disagree_fwd; test_disagree_fwd], ...
    [train_saved_bps; test_saved_bps], ...
    'VariableNames',{'DisagreementRate','VetoDayRate','MeanPositiveGap', ...
                     'Gap90','AgreeForwardBps','DisagreeForwardBps','SavedBps'}, ...
    'RowNames',{'Train','Test'});

disp(hypothesis_summary)


%% SIGNAL QUALITY TABLE

signal_quality = table( ...
    [train_agree_fwd; train_disagree_fwd; test_agree_fwd; test_disagree_fwd], ...
    [train_agree_hit; train_disagree_hit; test_agree_hit; test_disagree_hit], ...
    'VariableNames',{'ForwardReturnBps','HitRate'}, ...
    'RowNames',{'Train_Agree','Train_Disagree','Test_Agree','Test_Disagree'});

disp(signal_quality)


%% VETO DAY PERFORMANCE TABLE

veto_day_performance = table( ...
    [train_base_veto_ret; test_base_veto_ret], ...
    [train_veto_veto_ret; test_veto_veto_ret], ...
    [train_saved_bps; test_saved_bps], ...
    'VariableNames',{'BaselineBps','RSPVetoBps','DifferenceBps'}, ...
    'RowNames',{'Train','Test'});

disp(veto_day_performance)


%% PLOTS

periods = categorical({'Train','Test'});
periods = reordercats(periods,{'Train','Test'});

% Consistent presentation colors
c_agree = [0 0.65 0];      % green
c_disagree = [0.85 0 0];   % red
c_base = [0 0.65 0];       % paper baseline
c_veto = [0 0.8 0.9];          % RSP veto

fig = figure();
t = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

% 1. RSP disagreement frequency
nexttile
b = bar(periods,[train_disagree_rate test_disagree_rate]);
b.FaceColor = c_disagree;
ylabel('Signals (%)');
title('RSP Disagreement Frequency');
grid on; set(gca,'GridLineStyle',':','FontSize',9);

% 2. SPY-RSP divergence
nexttile
b = bar(periods,[train_gap_mean train_gap90; ...
    test_gap_mean test_gap90]);
b(1).FaceColor = [0.35 0.35 0.35];
b(2).FaceColor = c_disagree;
ylabel('Directional Gap (%)');
title('SPY-RSP Divergence');
grid on; set(gca,'GridLineStyle',':','FontSize',9);
legend('Mean Positive Gap','90th Percentile', ...
    'Location','northwest','FontSize',8);

% 3. Signal performance
nexttile
b = bar(periods,[train_agree_fwd train_disagree_fwd; ...
    test_agree_fwd test_disagree_fwd]);
b(1).FaceColor = c_agree;
b(2).FaceColor = c_disagree;
yline(0,'--','Color',[0.6 0.6 0.6]);
ylabel('30-Min Forward Return (bps)');
title('Signal Performance');
grid on; set(gca,'GridLineStyle',':','FontSize',9);
legend('RSP Agrees','RSP Disagrees', ...
    'Location','southwest','FontSize',8);

% 4. Performance on veto days
nexttile
b = bar(periods,[train_base_veto_ret train_veto_veto_ret; ...
    test_base_veto_ret test_veto_veto_ret]);
b(1).FaceColor = c_base;
b(2).FaceColor = c_veto;
ylabel('Average Daily Return (bps)');
title('Performance on Veto Days');
grid on; set(gca,'GridLineStyle',':','FontSize',9);
legend('Paper Baseline','RSP Veto', ...
    'Location','southeast','FontSize',8);

title(t,'Testing the RSP Breadth Hypothesis', ...
    'FontWeight','bold','FontSize',14);


%% RETURN DISTRIBUTION: AGREE VS DISAGREE

train_agree = signal_fwd(train_signal & ~signal_disagree);
train_disagree = signal_fwd(train_signal & signal_disagree);
test_agree = signal_fwd(test_signal & ~signal_disagree);
test_disagree = signal_fwd(test_signal & signal_disagree);

% Median returns
median_ret = [median(train_agree); median(train_disagree); ...
    median(test_agree); median(test_disagree)]*10000;

% Average winning returns
avg_winner = [mean(train_agree(train_agree>0)); ...
    mean(train_disagree(train_disagree>0)); ...
    mean(test_agree(test_agree>0)); ...
    mean(test_disagree(test_disagree>0))]*10000;

% Average losing returns
avg_loser = [mean(train_agree(train_agree<0)); ...
    mean(train_disagree(train_disagree<0)); ...
    mean(test_agree(test_agree<0)); ...
    mean(test_disagree(test_disagree<0))]*10000;

% 10th and 90th percentile returns
p10 = [prctile(train_agree,10); prctile(train_disagree,10); ...
    prctile(test_agree,10); prctile(test_disagree,10)]*10000;

p90 = [prctile(train_agree,90); prctile(train_disagree,90); ...
    prctile(test_agree,90); prctile(test_disagree,90)]*10000;

% Distribution summary table
return_distribution = table( ...
    median_ret,avg_winner,avg_loser,p10,p90, ...
    'VariableNames',{'MedianBps','AvgWinnerBps','AvgLoserBps','P10Bps','P90Bps'}, ...
    'RowNames',{'Train_Agree','Train_Disagree','Test_Agree','Test_Disagree'});

disp(return_distribution)


%% RETURN DISTRIBUTION PLOT

figure();
hold on

% Consistent colors
c_agree = [0 0.65 0];      % green
c_disagree = [0.85 0 0];   % red

% Clearly separated Train and Test clusters
x_train_agree    = 0.65*ones(length(train_agree),1);
x_train_disagree = 1.35*ones(length(train_disagree),1);

x_test_agree     = 2.65*ones(length(test_agree),1);
x_test_disagree  = 3.35*ones(length(test_disagree),1);

% Boxplots without individual outlier markers
h1 = boxchart(x_train_agree,train_agree*10000, ...
    'BoxFaceColor',c_agree,'MarkerStyle','none');

h2 = boxchart(x_train_disagree,train_disagree*10000, ...
    'BoxFaceColor',c_disagree,'MarkerStyle','none');

h3 = boxchart(x_test_agree,test_agree*10000, ...
    'BoxFaceColor',c_agree,'MarkerStyle','none');

h4 = boxchart(x_test_disagree,test_disagree*10000, ...
    'BoxFaceColor',c_disagree,'MarkerStyle','none');

% Zero return reference
yline(0,'--','Color',[0.6 0.6 0.6]);

% Mean return markers
plot(0.65,mean(train_agree)*10000,'wo', ...
    'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerSize',6);

plot(1.35,mean(train_disagree)*10000,'wo', ...
    'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerSize',6);

plot(2.65,mean(test_agree)*10000,'wo', ...
    'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerSize',6);

plot(3.35,mean(test_disagree)*10000,'wo', ...
    'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerSize',6);

% Presentation-focused axis
ylim([-40 40]);
yticks(-40:10:40);

xlim([0.2 3.8]);
xticks([1 3]);
xticklabels({'Train','Test'});

ylabel('30-Min Forward Return (bps)');
title('SPY Momentum Signal Return Distribution', ...
    'FontWeight','bold','FontSize',12);

legend([h1 h2],{'RSP Agrees','RSP Disagrees'}, ...
    'Location','northwest');

grid on;
set(gca,'GridLineStyle',':','FontSize',9);

hold off