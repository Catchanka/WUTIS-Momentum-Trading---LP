function dividends = fetchAlpacaDividends(stocksTicker, fromDate, toDate)
% Fetch historical cash dividends from Alpaca.
%
% Returns:
%   dividends.caldt     datenums of ex-dividend dates
%   dividends.dividend  cash dividend per share

%% Credentials

apiKey    = "xxx";
secretKey = "xxx";

%% Requested ex-dividend date range

requestedStart = datetime( ...
    fromDate, ...
    'InputFormat', 'yyyy-MM-dd');

requestedEnd = datetime( ...
    toDate, ...
    'InputFormat', 'yyyy-MM-dd');

if requestedEnd < requestedStart
    error('toDate must be on or after fromDate.');
end

%% Query a wider process-date window

queryStart = requestedStart - calmonths(2);
queryEnd   = requestedEnd   + calmonths(2);

queryStartString = string(queryStart, 'yyyy-MM-dd');
queryEndString   = string(queryEnd,   'yyyy-MM-dd');

%% Alpaca endpoint

baseUrl = "https://data.alpaca.markets/v1/corporate-actions";
limit = 1000;

%% Authentication

options = weboptions( ...
    'ContentType', 'json', ...
    'Timeout', 60, ...
    'HeaderFields', { ...
        'APCA-API-KEY-ID', char(apiKey); ...
        'APCA-API-SECRET-KEY', char(secretKey) ...
    });

%% Initialize output

dividends = struct( ...
    'caldt', [], ...
    'dividend', []);

pageToken = "";

%% Download pages

while true

    if strlength(pageToken) == 0

        url = baseUrl + ...
            "?symbols=" + string(stocksTicker) + ...
            "&types=cash_dividend" + ...
            "&start=" + queryStartString + ...
            "&end=" + queryEndString + ...
            "&limit=" + string(limit) + ...
            "&sort=asc";

    else

        url = baseUrl + ...
            "?symbols=" + string(stocksTicker) + ...
            "&types=cash_dividend" + ...
            "&start=" + queryStartString + ...
            "&end=" + queryEndString + ...
            "&limit=" + string(limit) + ...
            "&sort=asc" + ...
            "&page_token=" + pageToken;

    end

    fprintf('Fetching dividend data from Alpaca...\n');

    data = webread(url, options);

    %% Process dividends

    if isfield(data, 'corporate_actions') && ...
       isfield(data.corporate_actions, 'cash_dividends') && ...
       ~isempty(data.corporate_actions.cash_dividends)

        results = data.corporate_actions.cash_dividends;

        for i = 1:numel(results)

            % Alpaca/JSON conversion can produce either
            % a struct array or a cell array of structs.
            if iscell(results)
                currentResult = results{i};
            else
                currentResult = results(i);
            end

            exDate = datetime( ...
                currentResult.ex_date, ...
                'InputFormat', 'yyyy-MM-dd');

            if exDate >= requestedStart && ...
               exDate <= requestedEnd

                dividends.caldt = [ ...
                    dividends.caldt;
                    datenum(exDate)
                ];

                dividends.dividend = [ ...
                    dividends.dividend;
                    currentResult.rate
                ];

            end

        end

    end

    %% Pagination

    if isfield(data, 'next_page_token') && ...
       ~isempty(data.next_page_token)

        pageToken = string(data.next_page_token);

    else
        break;
    end

end

%% Sort by ex-dividend date

if ~isempty(dividends.caldt)

    [dividends.caldt, idx] = sort(dividends.caldt);

    dividends.dividend = dividends.dividend(idx);

end

fprintf('Finished downloading %d dividend records.\n', ...
    length(dividends.caldt));

end