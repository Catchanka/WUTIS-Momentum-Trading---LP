% Prepare RSP intraday variables for breadth confirmation

rsp_intra_data.day = fix(rsp_intra_data.caldt);
rsp_intra_data.tod = round(mod(rsp_intra_data.caldt,1),4);

rsp_intra_data.vwap = NaN(size(rsp_intra_data.caldt));
rsp_intra_data.move_open = NaN(size(rsp_intra_data.caldt));

rsp_days = unique(rsp_intra_data.day);

for d = 1:length(rsp_days)

    idx = find(rsp_intra_data.day == rsp_days(d));

    ohlc = rsp_intra_data.ohlc(idx,:);
    volume = rsp_intra_data.volume(idx,:);

    % Daily RSP VWAP
    rsp_intra_data.vwap(idx) = v_wap(ohlc,volume);

    % Signed return from RSP market open
    open = ohlc(1,1);
    rsp_intra_data.move_open(idx) = ohlc(:,4)./open - 1;

end

% Minutes from market open
rsp_intra_data.min_from_open = round((rsp_intra_data.tod - 9.5/24)*60*24,0) + 1;