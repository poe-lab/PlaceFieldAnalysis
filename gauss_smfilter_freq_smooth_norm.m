function gauss_smfilter_freq_smooth_norm()
% Output: [bin on linearized maze, time in bin, normalized smoothed firing
% rate, spike count from normalized firing rate, spike count, firing rate]
[input_filename, input_xls_path] = uigetfile('*.xls','select a excel file', 'MultiSelect', 'on');

prompt1 = ['Input the width of gausskernel:'];% indicate the value of plx_cluster_indx.
answer1 = inputdlg(prompt1); % Default = 2 according to Anna Sergeeva.
width_input  = answer1{:}; 

prompt2 = ['Input the value of standard diviation:'];% indicate the value of plx_cluster_indx.
answer2 = inputdlg(prompt2); % Default = 4 according to Anna Sergeeva.
std_input  = answer2{:};

width = str2num(width_input);
std   = str2num(std_input);

if iscell(input_filename)
    iter_length = length(input_filename);
else
    iter_length = 1;
end

for i = 1 : iter_length
    
    if iscell(input_filename)
        tmp_cell = input_filename(i);
        tmp_str = tmp_cell{1};	
        p = tmp_str(1 : strfind(tmp_str, '.xls') - 1);
        filename = fullfile(input_xls_path, tmp_str);
    else
        p = input_filename(1 : strfind(input_filename, '.xls') - 1);
        filename = fullfile(input_xls_path, input_filename);
    end

    [status, sheets] = xlsfinfo(filename);
	
    for s = 1:numel(sheets)

        [value_array, string_array, raw_array] = xlsread(filename, sheets{s});

        first_column = value_array(:,1);
        time_column = value_array(:,2);
        frequency_column = value_array(:,4);
        spike_count = value_array(:,3);
        MaxSpike = max(spike_count);
        MaxFreq = max(frequency_column);
        MinFreq = min(frequency_column);
        gap = first_column(2) - first_column(1);
		freq_smooth = Gausskernel(frequency_column, width, std);
        freq_smooth_normalized = normalize_var(freq_smooth, MinFreq, MaxFreq);
        freq_smooth_normalized(isnan(freq_smooth_normalized)) = 0;
        %spike_count_smooth = Gausskernel(spike_count, width, std);
        %spike_count_smooth_normalized = normalize_var(spike_count_smooth, 0, MaxSpike);
        index = value_array(:,1:2);
        spike_count_from_normFreq = freq_smooth_normalized.*time_column;
        %freq_normSC = spike_count_smooth_normalized./time_column;
        %indexSC = value_array(:,3);
        xlswrite(strcat(p, '_out.xls'), horzcat(index,spike_count_from_normFreq,freq_smooth_normalized,spike_count,frequency_column), sheets{s});
        %figure(i), plot(first_column/gap, frequency_column, first_column/gap, freq_smooth_normalized);
        figure(i), plot(first_column/gap, frequency_column,first_column/gap, spike_count_from_normFreq./time_column);
    end
	
	objExcel = actxserver('Excel.Application');
	objExcel.Workbooks.Open(fullfile(input_xls_path, strcat(p, '_out.xls')));
	
	try
	% Throws an error if the sheets do not exist.
	objExcel.ActiveWorkbook.Worksheets.Item('Sheet1').Delete;
	objExcel.ActiveWorkbook.Worksheets.Item('Sheet2').Delete;
	objExcel.ActiveWorkbook.Worksheets.Item('Sheet3').Delete;
	catch
	 % Do nothing.
	end
	
	objExcel.ActiveWorkbook.Save;
	objExcel.ActiveWorkbook.Close;
	objExcel.Quit;
	objExcel.delete;

end




