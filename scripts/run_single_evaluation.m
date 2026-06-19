clear
clc

projectRoot = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));
addpath(fullfile(projectRoot, 'raw_code', 'NSGA-II'));

rng(42);

fjspPath = fullfile(projectRoot, 'data_sample', 'Mk01.fjs');
machineExcelPath = fullfile(projectRoot, 'data_sample', '机器数据.xlsx');
agvExcelPath = fullfile(projectRoot, 'data_sample', 'AGV数据.xlsx');

problem = read_fjsp(fjspPath);
machineData = read_machine_data(machineExcelPath, problem.machineNum);
agvData = read_agv_data(agvExcelPath);

config = struct();
config.AGVEG_MAX = 100;
config.eChargeSpeed = 20;

distance_matrix = machineData.distance_matrix;
AGVSpeed = agvData.AGVSpeed;
AGVEnergy = agvData.AGVEnergy;
distance_MAX = max([max(distance_matrix.machine_to_machine(:)), ...
    max(distance_matrix.load_to_machine), ...
    max(distance_matrix.machine_to_unload), ...
    distance_matrix.load_to_unload]);
config.AGVEG_MIN = distance_MAX / AGVSpeed(end) * ...
    (AGVEnergy.free(end) + AGVEnergy.load(end)) + 1e-6;

pop = 1;
speedNum = length(agvData.AGVSpeed);
chromSet = init(pop, problem.jobNum, problem.operaNumVec, ...
    problem.candidateMachine, agvData.AGVNum, speedNum);
chrom = chromSet(1, :);

result = evaluate_chromosome(chrom, problem, machineData, agvData, config);

runDir = create_run_dir(fullfile(projectRoot, 'outputs', 'single_evaluation'));
save(fullfile(runDir, 'single_evaluation_result.mat'), ...
    'result', 'chrom', 'problem', 'machineData', 'agvData', 'config');

summaryPath = fullfile(runDir, 'summary.txt');
fid = fopen(summaryPath, 'w');
if isequal(fid, -1)
    error('run_single_evaluation:SummaryOpenFailed', ...
        'Could not open summary file: %s', summaryPath);
end
cleanupObj = onCleanup(@() fclose(fid));
fprintf(fid, 'single evaluation result\n');
fprintf(fid, 'makespan: %.6f\n', result.makespan);
fprintf(fid, 'machineEnergy: %.6f\n', result.machineEnergy);
fprintf(fid, 'agvEnergy: %.6f\n', result.agvEnergy);
fprintf(fid, 'totalEnergy: %.6f\n', result.totalEnergy);
fprintf(fid, 'outputDir: %s\n', runDir);

fprintf('single evaluation finished.\n');
fprintf('makespan: %.6f\n', result.makespan);
fprintf('totalEnergy: %.6f\n', result.totalEnergy);
fprintf('outputDir: %s\n', runDir);

function runDir = create_run_dir(baseDir)
if ~exist(baseDir, 'dir')
    mkdir(baseDir);
end

stamp = datestr(now, 'yyyymmdd_HHMMSS');
runDir = fullfile(baseDir, stamp);
suffix = 1;
while exist(runDir, 'dir')
    runDir = fullfile(baseDir, sprintf('%s_%02d', stamp, suffix));
    suffix = suffix + 1;
end
mkdir(runDir);
end
