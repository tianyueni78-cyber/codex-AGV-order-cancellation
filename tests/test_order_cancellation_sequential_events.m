clear
clc

testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(testDir);

addpath(fullfile(projectRoot, 'src', 'cancellation'));
addpath(fullfile(projectRoot, 'src', 'data'));
addpath(fullfile(projectRoot, 'src', 'encoding'));
addpath(fullfile(projectRoot, 'src', 'decoding'));
addpath(fullfile(projectRoot, 'src', 'evaluation'));

problem = read_fjsp(fullfile(projectRoot, 'data_sample', 'Mk01.fjs'));
machineData = build_sample_machine_data(problem.machineNum);
agvData = build_sample_agv_data();
initialSchedule = build_sample_schedule(problem.machineNum);
config = build_local_stable_config();

cancelEvents = [
    make_event(1, 2, 10)
    make_event(2, 3, 14)
];
result = run_sequential_order_cancellations( ...
    problem, machineData, agvData, initialSchedule, cancelEvents, config);

assert(result.isFeasible, 'Sequential cancellation run should be feasible.');
assert(result.completed_event_count == 2, ...
    'Two cancellation events should be processed.');
assert(numel(result.event_results) == 2, ...
    'Two event result rows should be returned.');
assert(all([result.event_results.decision_isSelected]), ...
    'Each event should have a final selected strategy.');
assert(result.event_results(1).event_id == 1, ...
    'First event should run first.');
assert(result.event_results(2).event_id == 2, ...
    'Second event should run second.');

assert(~result.event_results(1).selected_candidate_backflow_detected, ...
    'First selected plan should not report cancelled job backflow.');
assert(~result.event_results(2).selected_candidate_backflow_detected, ...
    'Second selected plan should not report cancelled job backflow.');
assert(result.event_results(2).details.cancelledEventsBeforeEvent(1).job_id == 2, ...
    'Second event should use the first selected plan as its baseline.');

for i = 1:numel(result.event_results)
    eventResult = result.event_results(i);
    assert(eventResult.local_machine_check_isFeasible, ...
        'Local repair machine check should be recorded as feasible.');
    assert(eventResult.local_agv_check_isFeasible, ...
        'Local repair AGV check should be recorded as feasible.');
    assert(eventResult.local_job_sequence_check_isFeasible, ...
        'Local repair job sequence check should be recorded as feasible.');
    assert(eventResult.selected_constraint_check_isFeasible, ...
        'Selected schedule should pass final constraint checks.');
    assert(eventResult.selected_machine_check_isFeasible, ...
        'Selected schedule machine check should pass.');
    assert(eventResult.selected_agv_check_isFeasible, ...
        'Selected schedule AGV check should pass.');
    assert(eventResult.selected_job_sequence_check_isFeasible, ...
        'Selected schedule job sequence check should pass.');
end

assert_no_cancelled_backflow(result.finalSchedule, cancelEvents);

unsupportedEvents = [
    make_event(1, 1, 11)
    make_event(2, 2, 20)
];
unsupportedResult = run_sequential_order_cancellations( ...
    problem, machineData, agvData, initialSchedule, unsupportedEvents, config);

assert(~unsupportedResult.isFeasible, ...
    'Unsupported sequential run should not be feasible.');
assert(unsupportedResult.completed_event_count == 1, ...
    'Default unsupported policy should stop after the first event.');
assert(unsupportedResult.event_results(1).isUnsupported, ...
    'Processing cancellation should be marked unsupported.');
assert(strcmp(unsupportedResult.event_results(1).unsupported_reason, ...
    'unsupported_processing_and_agv_state'), ...
    'Unsupported reason should identify processing machine and AGV state.');
assert(unsupportedResult.event_results(1).stop_sequence, ...
    'Default unsupported behavior should stop the sequence.');
assert(numel(unsupportedResult.report.unsupported_events) == 1, ...
    'Unsupported event should be recorded in the top-level report.');

fprintf('test_order_cancellation_sequential_events passed\n');

function event = make_event(eventId, jobId, cancelTime)
event = struct();
event.event_id = eventId;
event.job_id = jobId;
event.cancel_time = cancelTime;
event.policy = 'cancel_unstarted_operations_only';
end

function config = build_local_stable_config()
config = struct();
config.hybrid_policy = struct();
config.hybrid_policy.enable_complete_if_local_infeasible = true;
config.hybrid_policy.use_stage_e_y_selection = false;
config.hybrid_policy.cmax_delta_threshold = Inf;
config.hybrid_policy.energy_delta_threshold = Inf;
config.hybrid_policy.idle_waste_threshold = Inf;
config.hybrid_policy.threshold_validation_status = ...
    'pending_stage_l_validation';
config.sequential_cancellation = struct();
config.sequential_cancellation.stop_on_unsupported = true;
end

function machineData = build_sample_machine_data(machineNum)
machineData = struct();
machineData.distance_matrix = struct();
machineData.distance_matrix.machine_to_machine = zeros(machineNum, machineNum);
for i = 1:machineNum
    for j = 1:machineNum
        machineData.distance_matrix.machine_to_machine(i, j) = abs(i - j);
    end
end
machineData.distance_matrix.load_to_machine = 1:machineNum;
machineData.distance_matrix.machine_to_unload = machineNum:-1:1;
machineData.distance_matrix.load_to_unload = 1;
machineData.machineEnergy = struct();
machineData.machineEnergy.work = ones(1, machineNum) * 2;
machineData.machineEnergy.free = ones(1, machineNum);
end

function agvData = build_sample_agv_data()
agvData = struct();
agvData.AGVNum = 2;
agvData.AGVSpeed = [1.0, 1.5, 2.0];
agvData.AGVEnergy.free = [1.0, 1.2, 1.4];
agvData.AGVEnergy.load = [1.4, 1.6, 1.8];
end

function schedule = build_sample_schedule(machineNum)
schedule = struct();
schedule.machineTable = build_sample_machine_table(machineNum);
schedule.AGVTable = build_sample_agv_table();
end

function machineTable = build_sample_machine_table(machineNum)
machineTable = cell(1, machineNum);

for machineIdx = 1:machineNum
    machineTable{machineIdx} = make_machine_block(0, inf, 0, 0);
end

machineTable{1} = [
    make_machine_block(0, 4, 1, 1)
    make_machine_block(10, 14, 1, 2)
    make_machine_block(14, inf, 0, 0)
];

machineTable{2} = [
    make_machine_block(0, 3, 3, 1)
    make_machine_block(3, 8, 2, 1)
    make_machine_block(12, 15, 2, 2)
    make_machine_block(15, inf, 0, 0)
];

if machineNum >= 3
    machineTable{3} = [
        make_machine_block(14, 18, 3, 2)
        make_machine_block(18, inf, 0, 0)
    ];
end
end

function AGVTable = build_sample_agv_table()
AGVTable = cell(1, 2);

AGVTable{1} = [
    make_agv_block(0, 4, 1, 1, -1, 1, -2)
    make_agv_block(10, 12, 1, 2, 1, 1, -2)
    make_agv_block(12, 16, 2, 2, 2, -2, -2)
    make_agv_block(16, inf, 0, 0, -2, -2, 0)
];

AGVTable{2} = [
    make_agv_block(0, 3, 3, 1, -1, 2, -2)
    make_agv_block(4, 8, 2, 1, -1, 2, -2)
    make_agv_block(10, 13, 3, 2, 2, -2, -2)
    make_agv_block(13, inf, 0, 0, -2, -2, 0)
];
end

function block = make_machine_block(startTime, endTime, jobId, operationId)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
end

function block = make_agv_block(startTime, endTime, jobId, operationId, ...
    fromMachine, toMachine, loadStatus)
block = struct();
block.start = startTime;
block.end = endTime;
block.job = jobId;
block.opera = operationId;
block.from_machine = fromMachine;
block.to_machine = toMachine;
block.status = [];
block.load_status = loadStatus;
block.charge = 0;
end

function assert_no_cancelled_backflow(schedule, cancelEvents)
for i = 1:numel(cancelEvents)
    assert_no_backflow_in_table( ...
        schedule.machineTable, cancelEvents(i), 'machineTable');
    assert_no_backflow_in_table( ...
        schedule.AGVTable, cancelEvents(i), 'AGVTable');
end
end

function assert_no_backflow_in_table(tableData, cancelEvent, tableName)
for resourceIdx = 1:numel(tableData)
    blocks = tableData{resourceIdx};
    for blockIdx = 1:numel(blocks)
        block = blocks(blockIdx);
        if block.job == cancelEvent.job_id && ...
                block.end > cancelEvent.cancel_time
            error('test_order_cancellation_sequential_events:Backflow', ...
                ['Cancelled job %d appears after cancel_time %.6f ', ...
                'in %s resource %d block %d.'], ...
                cancelEvent.job_id, cancelEvent.cancel_time, ...
                tableName, resourceIdx, blockIdx);
        end
    end
end
end
