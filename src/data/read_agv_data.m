function agvData = read_agv_data(excelPath)
%READ_AGV_DATA Read AGV configuration and energy data from Excel.
%   agvData = READ_AGV_DATA(excelPath) reads the AGV sample workbook and
%   only returns data. It does not modify the workbook or create files.

if nargin < 1
    error('read_agv_data:MissingInput', 'excelPath is required.');
end

if ~isfile(excelPath)
    error('read_agv_data:FileNotFound', ...
        'AGV data file not found: %s', excelPath);
end

[~, sheetNames] = xlsfinfo(excelPath);
if numel(sheetNames) < 3
    error('read_agv_data:InvalidWorkbook', ...
        'AGV data workbook must contain at least 3 sheets.');
end

AGVNum = xlsread(excelPath, sheetNames{1});
AGVSpeed = xlsread(excelPath, sheetNames{2});
AGVEnergy_excel = xlsread(excelPath, sheetNames{3});

if isempty(AGVNum) || isempty(AGVSpeed) || size(AGVEnergy_excel, 1) < 2
    error('read_agv_data:InvalidData', ...
        'AGV data workbook does not contain the expected values.');
end

AGVEnergy.free = AGVEnergy_excel(1, :);
AGVEnergy.load = AGVEnergy_excel(2, :);

agvData = struct();
agvData.AGVNum = AGVNum(1);
agvData.AGVSpeed = AGVSpeed(:).';
agvData.AGVEnergy = AGVEnergy;
end
