function y = lag_TS(data, n)
% Lag a data matrix by 'n' periods
% Inputs:
%   data: An NxM matrix of data
%   n: Scalar defining the number of periods by which to lag the data
% Output:
%   y: An NxM matrix of lagged data

[T, N] = size(data); % Get the dimensions of the input data matrix
y = NaN(T, N); % Initialize the output matrix with NaNs

if n > 0
    y((n+1):T, :) = data(1:(T-n), :); % Lag data forward by 'n' periods
end
end