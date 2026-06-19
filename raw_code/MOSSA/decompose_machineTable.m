%%   machineTable分块重组
function a = decompose_machineTable(insertion, block, job, opera)    
a = [];
if isequal(int64(1E6 * insertion.start), int64(1E6 * block.start)) ...
        && isequal(int64(1E6 * insertion.end), int64(1E6 * block.end))
    a.start = insertion.start;
    a.end = insertion.end;
    a.job = job;
    a.opera = opera;
elseif isequal(int64(1E6 * insertion.start), int64(1E6 * block.start)) ...
        &&int64(1E6 * insertion.end) < int64(1E6 * block.end)
    a(1).start = insertion.start;
    a(1).end = insertion.end;
    a(1).job = job;
    a(1).opera = opera;

    a(2).start = insertion.end;
    a(2).end = block.end;
    a(2).job = 0;
    a(2).opera = 0;
elseif int64(1E6 * insertion.start) > int64(1E6 * block.start) ...
        &&isequal(int64(1E6 * insertion.end), int64(1E6 * block.end))
    a(1).start = block.start;
    a(1).end = insertion.start;
    a(1).job = 0;
    a(1).opera = 0;

    a(2).start = insertion.start;
    a(2).end = block.end;
    a(2).job = job;
    a(2).opera = opera;
elseif int64(1E6 * insertion.start) > int64(1E6 * block.start) ...
        &&int64(1E6 * insertion.end) < int64(1E6 * block.end)
    a(1).start = block.start;
    a(1).end = insertion.start;
    a(1).job = 0;
    a(1).opera = 0;

    a(2).start = insertion.start;
    a(2).end = insertion.end;
    a(2).job = job;
    a(2).opera = opera;

    a(3).start = insertion.end;
    a(3).end = block.end;
    a(3).job = 0;
    a(3).opera = 0;
else
    warning('machineTable decompose wrong.')
end
end