
filename = '实验数据.xlsx';          % 请修改为您的Excel文件路径
% 如果工作表名称不是以N开头，请在此手动定义列表，例如：
% subject_sheets = {'N1','N2','N3','N4','N5','N6','N7','N8','N9','N10',...
%                   'N11','N12','N13','N14','N15','N16','N17','N18','N19','N20',...
%                   'N21','N22','N23','N24','N25','N26','N27','N28','N30','N31'};
% =====================

%% 获取所有工作表名称，筛选以'N'开头的工作表
[~, sheets] = xlsfinfo(filename);
subject_sheets = sheets(contains(sheets, 'N'));
if isempty(subject_sheets)
    error('未找到以N开头的工作表，请手动定义 subject_sheets');
end
fprintf('找到 %d 个工作表：\n', length(subject_sheets));
disp(subject_sheets');

%% 初始化结果
brake_start_rel = nan(length(subject_sheets), 1);   % 存储从开始到首次制动的时间差

%% 循环处理每个工作表
for i = 1:length(subject_sheets)
    sheetname = subject_sheets{i};
    fprintf('\n处理工作表：%s\n', sheetname);
    
    % 读取数据（不假定表头）
    raw = readtable(filename, 'Sheet', sheetname, 'ReadVariableNames', false);
    
    % 显示原始数据前5行，帮助确认列位置
    fprintf('原始数据前5行（第1列为时间，第13列为刹车）：\n');
    disp(raw(1:min(5,height(raw)), :));
    
    % 检查列数是否足够
    if size(raw,2) < 13
        warning('工作表 %s 列数不足13，跳过', sheetname);
        continue;
    end
    
    % 提取时间和刹车列原始数据（可能是数值或文本）
    time_raw = raw{:,1};
    brake_raw = raw{:,13};
    
    % 尝试将时间列转换为数值，非数值行会变成NaN
    time_num = str2double(string(time_raw));
    brake_num = str2double(string(brake_raw));
    
    % 如果第一行转换后为NaN，说明有表头，则删除第一行
    if isnan(time_num(1)) || isnan(brake_num(1))
        fprintf('检测到表头，已自动去除第一行\n');
        time_num = time_num(2:end);
        brake_num = brake_num(2:end);
        % 同时去除原始数据用于显示
        time_raw = time_raw(2:end);
        brake_raw = brake_raw(2:end);
    end
    
    % 再次检查是否有非数值数据
    valid = ~isnan(time_num) & ~isnan(brake_num);
    time = time_num(valid);
    brake = brake_num(valid);
    
    if isempty(time)
        warning('工作表 %s 无有效数值数据，跳过', sheetname);
        continue;
    end
    
    % 显示转换后的数据前5行，确认数值
    fprintf('转换后有效数据前5行：\n');
    disp(table(time(1:min(5,end)), brake(1:min(5,end)), 'VariableNames', {'time','brake'}));
    
    % 找到第一个刹车不为0的索引（考虑浮点误差，使用 > eps 或 ~=0）
    idx = find(brake ~= 0, 1, 'first');
    % 如果刹车可能为负，可改为 find(abs(brake) > 1e-6, 1, 'first')
    
    if isempty(idx)
        fprintf('  警告：未找到刹车不为0的点\n');
        brake_start_rel(i) = NaN;
    else
        t_start = time(idx);
        brake_start_rel(i) = t_start - time(1);   % 减去起始时间
        fprintf('  首次制动时间 = %.3f s (第 %d 行)\n', t_start, idx);
        fprintf('  从开始到制动时长 = %.3f s\n', brake_start_rel(i));
    end
end

%% 输出结果表格
result_table = table(subject_sheets', brake_start_rel, ...
    'VariableNames', {'Subject', 'BrakeStartRel'});
fprintf('\n最终结果：\n');
disp(result_table);

%% 保存结果到Excel
outfile = '开始制动时间结果.xlsx';
writetable(result_table, outfile);
fprintf('\n结果已保存至：%s\n', outfile);