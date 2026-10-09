function stock_data = fetchAlpacaData(stocksTicker, fromDate, toDate, period)
% Fetch historical stock data from Alpaca Market Data API.
%
% Example:
% spy_intra_data = fetchAlpacaData('SPY', '2016-01-01', ...
%                                  '2024-04-30', 'minute');

%% Alpaca credentials
apiKey    = "xxx";
secretKey = "xxx";

%% Convert requested period into Alpaca timeframe

if strcmpi(period, 'minute')
    timeframe = "1Min";
elseif strcmpi(period, 'day')
    timeframe = "1Day";
else
    error('period must be either "minute" or "day".');
end

%% API settings

baseUrl = "https://data.alpaca.markets/v2/stocks/" + ...
          string(stocksTicker) + "/bars";

limit = 10000;

% IMPORTANT:
% "iex" works with the free/basic stock-data plan.
% "sip" gives consolidated US exchange data but may require
% an appropriate Alpaca subscription.
feed = "sip";

adjustment = "raw";

%% Authentication headers

options = weboptions( ...
    'ContentType', 'json', ...
    'Timeout', 60, ...
    'HeaderFields', { ...
        'APCA-API-KEY-ID', char(apiKey); ...
        'APCA-API-SECRET-KEY', char(secretKey) ...
    });

%% Initialize output

stock_data = struct( ...
    'volume', [], ...
    'ohlc', [], ...
    'caldt', []);

pageToken = "";

%% Download pages

while true

    if strlength(pageToken) == 0

        url = baseUrl + ...
            "?timeframe=" + timeframe + ...
            "&start=" + string(fromDate) + ...
            "&end=" + string(toDate) + ...
            "&limit=" + string(limit) + ...
            "&adjustment=" + adjustment + ...
            "&feed=" + feed + ...
            "&sort=asc";

    else

        url = baseUrl + ...
            "?timeframe=" + timeframe + ...
            "&start=" + string(fromDate) + ...
            "&end=" + string(toDate) + ...
            "&limit=" + string(limit) + ...
            "&adjustment=" + adjustment + ...
            "&feed=" + feed + ...
            "&sort=asc" + ...
            "&page_token=" + pageToken;

    end

    fprintf('Fetching data from Alpaca...\n');

    data = webread(url, options);

    %% Check for returned bars

    if ~isfield(data, 'bars') || isempty(data.bars)
        break;
    end

    stockData = data.bars;

    %% Alpaca timestamps are ISO-8601 UTC timestamps

    datetimeValues = datetime( ...
        string({stockData.t}), ...
        'InputFormat', 'yyyy-MM-dd''T''HH:mm:ssXXX', ...
        'TimeZone', 'UTC');

    % Convert to New York market time
    datetimeValues.TimeZone = 'America/New_York';

    %% Minute data

    if strcmpi(period, 'minute')

        marketStart = duration(9,30,0);
        marketEnd   = duration(15,59,59);

        marketHoursFilter = ...
            timeofday(datetimeValues) >= marketStart & ...
            timeofday(datetimeValues) <= marketEnd;

        filteredData = stockData(marketHoursFilter);

        filteredTimes = datetimeValues(marketHoursFilter);

        if ~isempty(filteredData)

            filteredVolumes = [filteredData.v]';

            filteredOHLC = [ ...
                [filteredData.o]' ...
                [filteredData.h]' ...
                [filteredData.l]' ...
                [filteredData.c]' ...
            ];

            stock_data.volume = [ ...
                stock_data.volume;
                filteredVolumes
            ];

            stock_data.ohlc = [ ...
                stock_data.ohlc;
                filteredOHLC
            ];

            stock_data.caldt = [ ...
                stock_data.caldt;
                datenum(filteredTimes)'
            ];

        end

    %% Daily data

    else

        volumes = [stockData.v]';

        ohlc = [ ...
            [stockData.o]' ...
            [stockData.h]' ...
            [stockData.l]' ...
            [stockData.c]' ...
        ];

        stock_data.volume = [ ...
            stock_data.volume;
            volumes
        ];

        stock_data.ohlc = [ ...
            stock_data.ohlc;
            ohlc
        ];

        stock_data.caldt = [ ...
            stock_data.caldt;
            datenum(datetimeValues)'
        ];

    end

    %% Pagination

    if isfield(data, 'next_page_token') && ...
            ~isempty(data.next_page_token)

        pageToken = string(data.next_page_token);

    else
        break;
    end

end

fprintf('Finished downloading %s data.\n', period);

end