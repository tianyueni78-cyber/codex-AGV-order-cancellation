%% machineTable/AGVTable 插入空闲时间块儿
% e_flag: 0 非充电  1 充电状态
function table_input = table_insert(insertion, table_input, decom_posi, curJob, jobOpera, load_status, ...
    dest_machine, e_flag)
if nargin == 5
    tableName = 'machineTable';
elseif nargin == 8
    tableName = 'AGVTable';
else
    warning('table insert warong.')
    tableName = '';
end

if isequal(tableName, 'machineTable')
    a = decompose_machineTable(insertion, table_input(decom_posi), curJob, jobOpera);
elseif isequal(tableName, 'AGVTable')
    a = decompose_AGVTable(insertion, table_input(decom_posi), curJob, jobOpera, load_status, dest_machine, e_flag);
else
    warning('table insert warong.')
end

movement = length(a) - 1;
% 循环插入：位置 decom_posi 是machineTable/AGVTAble上要被插入分解的块儿
Len = length(table_input);
% 移动原有块
if ~isequal(Len, decom_posi)
    for m = Len : -1 : decom_posi + 1
        table_input(m + movement).start = table_input(m).start;
        table_input(m + movement).end = table_input(m).end;
        table_input(m + movement).job = table_input(m).job;
        table_input(m + movement).opera = table_input(m).opera;
        if isequal(tableName, 'AGVTable')
            table_input(m + movement).load_status = table_input(m).load_status;
            table_input(m + movement).from_machine = table_input(m).from_machine;
            table_input(m + movement).to_machine = table_input(m).to_machine;
            table_input(m + movement).charge = table_input(m).charge;
        end
    end
end

% 插入新块
for m = 1 : length(a)
    table_input(decom_posi - 1 + m).start = a(m).start;
    table_input(decom_posi - 1 + m).end = a(m).end;
    table_input(decom_posi - 1 + m).job = a(m).job;
    table_input(decom_posi - 1 + m).opera = a(m).opera;
    if isequal(tableName, 'AGVTable')
        table_input(decom_posi - 1 + m).load_status = a(m).load_status;
        table_input(decom_posi - 1 + m).from_machine = a(m).from_machine;
        table_input(decom_posi - 1 + m).to_machine = a(m).to_machine;
        table_input(decom_posi - 1 + m).charge = a(m).charge;
    end
end
end