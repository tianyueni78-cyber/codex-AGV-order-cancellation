function a = decompose_AGVTable(insertion, block, job, opera, load_status, dest_machine, e_flag)
% e_flag: 0 非充电  1 充电状态
a = [];
if isequal(int64(1E6 * insertion.start), int64(1E6 * block.start)) ...
        && int64(1E6 * insertion.end) < int64(1E6 * block.end)
    a(1).start = insertion.start;
    a(1).end = insertion.end;
    a(1).job = job;
    a(1).opera = opera;
    a(1).load_status = load_status;
    a(1).from_machine = block.from_machine;
    a(1).to_machine = dest_machine;
    a(1).charge = 0;
    if e_flag > 0
        a(1).charge = e_flag;
    end

    a(2).start = insertion.end;
    a(2).end = block.end;
    a(2).job = 0;
    a(2).opera = 0;
    a(2).load_status = 0;
    a(2).from_machine = dest_machine;
    a(2).to_machine = 0;
    a(2).charge = 0;
    
elseif int64(1E6 * insertion.start) > int64(1E6 * block.start) ...
        && int64(1E6 * insertion.end) < int64(1E6 * block.end)
    a(1).start = block.start;
    a(1).end = insertion.start;
    a(1).job = 0;
    a(1).opera = 0;
    a(1).load_status = 0;
    a(1).from_machine = block.from_machine;
    a(1).to_machine = block.from_machine;
    a(1).charge = 0;

    a(2).start = insertion.start;
    a(2).end = insertion.end;
    a(2).job = job;
    a(2).opera = opera;
    a(2).load_status = load_status;
    a(2).from_machine = block.from_machine;
    a(2).to_machine = dest_machine;
    a(2).charge = 0;
    if e_flag > 0
        a(2).charge = e_flag;
    end

    a(3).start = insertion.end;
    a(3).end = block.end;
    a(3).job = 0;
    a(3).opera = 0;
    a(3).load_status = 0;
    a(3).from_machine = dest_machine;
    a(3).to_machine = 0;
    a(3).charge = 0;
else
    warning('AGV decompose wrong.')
end
end