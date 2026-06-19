function energy_plot(AGVNum, agvEGRecord, agvChargeNum)
ag_str = [];
for ag = 1: AGVNum
    ag_str = [ag_str ',''AGV' num2str(ag) ' 充电' num2str(agvChargeNum(ag)) '次' ''''];
end
ag_str = ag_str(2: end);

color = ['r'; 'g'; 'b'; 'y'; 'c'];
for ag = 1: AGVNum
    plot(agvEGRecord{ag}(:, 1), agvEGRecord{ag}(:, 2), [color(ag) '-s'], 'MarkerEdgeColor', 'k', 'MarkerFaceColor', color(ag), 'LineWidth', 1.0);
    hold on
    for i = 1: size(agvEGRecord{ag}, 1)
        txt = sprintf('%0.1f', agvEGRecord{ag}(i, 2));
        text(agvEGRecord{ag}(i, 1) + 0.3, agvEGRecord{ag}(i, 2) - 0.3, txt, 'FontWeight', 'Bold', 'FontSize', 8)
        hold on
    end
end
eval(['legend(' ag_str ', ''Location'', ''NorthEastOutside'')'])
end