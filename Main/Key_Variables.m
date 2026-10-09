% TRAIN/TEST SPLIT
test_start_date = datetime(2024,05,1); 

% Convert caldt to integer days to represent unique trading days
spy_intra_data.day = fix(spy_intra_data.caldt);

% Calculate and round time of day from caldt to four decimal places
spy_intra_data.tod = round(mod(spy_intra_data.caldt, 1), 4);

% Extract unique trading days
all_days = unique(spy_intra_data.day);

% Define training and testing periods
test_start_day = datenum(test_start_date);
train_mask = all_days < test_start_day;
test_mask = all_days >= test_start_day;

if ~any(train_mask) || ~any(test_mask)
    error('The selected test_start_date must lie inside the available data period.');
end

% Initialize intraday variables
spy_intra_data.move_open = NaN(size(spy_intra_data.caldt)); 
spy_intra_data.vwap = NaN(size(spy_intra_data.caldt));
spy_intra_data.spy_dvol = NaN(size(spy_intra_data.caldt));

% Initialize daily SPY returns
spy_return = NaN(length(all_days),1);

% Calculate daily variables
for d = 2:length(all_days)
    idx = find(spy_intra_data.day == all_days(d));
    idx_y = find(spy_intra_data.day == all_days(d-1));

    ohlc = spy_intra_data.ohlc(idx,:);
    volume = spy_intra_data.volume(idx,:);

    % VWAP
    spy_intra_data.vwap(idx) = v_wap(ohlc,volume);

    % Absolute movement from market open
    open = spy_intra_data.ohlc(idx(1),1);
    spy_intra_data.move_open(idx) = abs(ohlc(:,4)./open - 1);

    % Daily SPY return
    spy_return(d) = spy_intra_data.ohlc(idx(end),4) / spy_intra_data.ohlc(idx_y(end),4) - 1;

    % Rolling 14-day daily volatility
    if d > 14
        spy_intra_data.spy_dvol(idx) = std(spy_return(d-14:d-1));
    end
end

% Minutes from 9:30 market open
spy_intra_data.min_from_open = round((spy_intra_data.tod - 9.5/24)*60*24,0) + 1;
all_minutes = 1:390;

% Rolling 14-day average movement from open
spy_intra_data.sigma_open = NaN(size(spy_intra_data.caldt));

for m = 1:length(all_minutes)
    idx_ = find(spy_intra_data.min_from_open == all_minutes(m));
    spy_intra_data.sigma_open(idx_) = lag_TS(Rolling_Mean(spy_intra_data.move_open(idx_),14,'omitnan'),1);
end

% Match dividends to trading days
dividends.day = fix(dividends.caldt);
spy_intra_data.dividends = zeros(size(spy_intra_data.caldt));

for i = 1:length(dividends.caldt)
    idx = find(spy_intra_data.day == dividends.day(i),1);
    if ~isempty(idx)
        spy_intra_data.dividends(idx) = dividends.dividend(i);
    end
end