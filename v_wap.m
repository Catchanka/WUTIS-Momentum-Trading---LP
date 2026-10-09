function y = v_wap(ohlc, volume)
% Calculate the Volume Weighted Average Price (VWAP) for given price data
% Inputs:
%   ohlc: An Nx4 matrix where columns represent open, high, low, and close prices
%   volume: An Nx1 vector of trading volumes for each corresponding row in ohlc
% Output:
%   y: An Nx1 vector of VWAP values

hlc = mean(ohlc(:,2:end), 2); % Calculate the mean of high, low, and close prices
vol_x_hlc = volume .* hlc;    % Product of volume and average price
y = cumsum(vol_x_hlc) ./ cumsum(volume); % Cumulative sum to calculate VWAP
end