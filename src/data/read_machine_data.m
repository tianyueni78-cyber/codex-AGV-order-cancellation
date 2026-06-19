function machineData = read_machine_data(excelPath, machineNum)
%READ_MACHINE_DATA Read machine distances and energy data from Excel.
%   machineData = READ_MACHINE_DATA(excelPath, machineNum) reads the same
%   sheets used by the original main scripts, but only returns data and does
%   not write back to the Excel file.

if nargin < 2
    error('read_machine_data:MissingInput', ...
        'excelPath and machineNum are required.');
end

if ~isfile(excelPath)
    error('read_machine_data:FileNotFound', ...
        'Machine data file not found: %s', excelPath);
end

distance_matrix_excel = xlsread(excelPath, '装卸站到机器距离');

distance_matrix.load_to_machine = distance_matrix_excel(1, :);
distance_matrix.load_to_machine = distance_matrix.load_to_machine(1:machineNum);

distance_matrix.machine_to_unload = distance_matrix_excel(2, :);
distance_matrix.machine_to_unload = distance_matrix.machine_to_unload(1:machineNum);

distance_matrix.machine_to_machine = xlsread(excelPath, '机器到机器距离');
distance_matrix.machine_to_machine = ...
    distance_matrix.machine_to_machine(1:machineNum, 1:machineNum);

distance_matrix.load_to_unload = xlsread(excelPath, '装载站到卸载站距离');

machineEnergy.work = xlsread(excelPath, '机器加工能耗');
machineEnergy.free = xlsread(excelPath, '机器空载能耗');

machineData = struct();
machineData.distance_matrix = distance_matrix;
machineData.machineEnergy = machineEnergy;
end
