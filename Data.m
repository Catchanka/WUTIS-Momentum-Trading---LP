fromDate = '2016-01-01';
toDate   = '2026-09-30';

spy_intra_data = fetchAlpacaData('SPY', fromDate, toDate, 'minute');
spy_daily_data = fetchAlpacaData('SPY', fromDate, toDate, 'day');
dividends = fetchAlpacaDividends('SPY', fromDate, toDate);
rsp_intra_data = fetchAlpacaData('RSP', fromDate, toDate, 'minute');

load('SPY_Alpaca_2016_2026.mat');
load('RSP_Alpaca_2016_2026.mat');


