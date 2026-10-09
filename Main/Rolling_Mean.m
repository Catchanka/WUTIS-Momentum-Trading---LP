function y = Rolling_Mean(price, window, nanflag)
% Compute the rolling mean of a time-series over a specified window
% Inputs:
%   price: An Nx1 vector of price data
%   window: Scalar defining the number of observations used for the moving average
%   nanflag: String, either 'omitnan' or 'includenan', specifying how to treat NaNs
% Output:
%   y: An Nx1 vector of the rolling mean values

y = movmean(price, [window-1 0], 1, nanflag); % Calculate moving average
y(1:window-1) = NaN; % Assign NaN to the first 'window-1' elements
end