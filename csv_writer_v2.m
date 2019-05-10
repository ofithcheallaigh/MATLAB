close all
clear all


% % Get user input information - test date, start time, reg
% prompt = {'Test Date:','Test Start Time:'};
% dlgtitle = 'Input';
% dims = [1 35];
% definput = {'26/03/2019','09:52'};
% answer = inputdlg(prompt,dlgtitle,dims,definput);


% Gets filenames which will be used in data import
abs_filename = 'C:\Users\a1038064\Documents\MATLAB\Nordic\Replayed_DKL_South_Variable_File_1_ABSData_08-05-19__Time_12-32-36.csv';
adc_filename = 'C:\Users\a1038064\Documents\MATLAB\Nordic\DLK_South_Variable_File_1.csv';

output_file_name = '__ROAD_DATA_DLKS_60KPH_E-CLASS_000181.csv';

% ***********************************************************************
% Calling data import function (see end of script)
% ***********************************************************************
[abs_date_time,adc_date_time,importedADCData,importedABSData,ADCData,ABSData] = read_in_files(abs_filename,adc_filename);

% Prep-ing timing infomation 
% ABS time information has also been imported (see abs_dat_time) but there are
% expty cells, these need removed:
abs_date_time = cellstr(abs_date_time);
abs_date_time = abs_date_time(~cellfun('isempty',abs_date_time));
abs_date_time = string(abs_date_time);

% Get data in the correct alignment (i.e. 1 x N matrix)
adc_date_time = adc_date_time';

% Now, remove the data portion from each of the vectors (ADC and ABS)
adc_time_only = extractAfter(adc_date_time,"_");
abs_time_only = extractAfter(abs_date_time,"_");

% Convert to datetime format, and subtract
% NB: This will add a date into the file, but this doesn't matter, as we
% are subtracting the two vectors, so the date will cancel.
% I will try and find a way to remove the data later
abs_datetime = datetime(abs_time_only);
adc_datetime = datetime(adc_time_only);


% ***********************
% Time calc part: Start
% ***********************
abs = abs_datetime;
adc = adc_datetime;

% abs = [1,5,5,5,7,3,2,1];
% adc = [3,10,9,1,4,3,1,1];

len_a = length(abs);
len_b = length(adc);

% Lines below set the upper and lower limit of acceptable time differences
% between ABS and ADC times (i.e. between 0 and 7 seconds)
seconds_upper_limit = seconds(7);
seconds_lower_limit = seconds(0);

% a_index_counter = 1;
for i = 1:len_a
    for j = 1:len_b
        sub_answer(j) = adc(j) - abs(i);
        if(length(sub_answer) == 50)
            break;
        end
    end
    break;
end

logical_answer = (sub_answer > seconds_lower_limit)&(sub_answer < seconds_upper_limit);
logical_answer_mean = mean(logical_answer);

if(logical_answer_mean > 0)
    k  = find(logical_answer);
    % break;
end
% sub_answer = zeros(1,len_a);

adc_start = k;
abs_start = i;

% **********************
% TIme calc part: Ends
% **********************

% Call function to get the usable ABS and ADC data
[usable_abs_sample_data,usable_adc_sample_data] = abs_acd_usable_data_fun(importedADCData,ABSData,abs_datetime,adc_start,abs_start);

[written_table] = csv_builder_fun_1(importedADCData,adc_start,abs_datetime,abs_time_only,adc_time_only,importedABSData,usable_abs_sample_data,usable_adc_sample_data);

% Used for plotting
a = datetime(adc_time_only(adc_start:(adc_start+49)));
b = datetime(abs_time_only);
time_diff = a - b;

% Plot function, as a visual check on the time differences
plot(time_diff);
title('Difference between the final selected ABS and ADC time')
xlabel('Sample')
ylabel('Time (sec)')

% Writes table to .csv file
writetable(written_table,output_file_name,'Delimiter',',','QuoteStrings',true,'WriteVariableNames',false);

% ***************************************
% My Functions
% ***************************************
function [usable_abs_sample_data,usable_adc_sample_data] = abs_acd_usable_data_fun(importedADCData,ABSData,abs_datetime,adc_start,abs_start)
% Now that I know the index where the timing statrs (i.e. j), I can use
% that to get the correct ADC data
full_adc_sample_data = importedADCData(:,(6:end));
full_adc_sample_data = full_adc_sample_data';
usable_adc_sample_data = full_adc_sample_data(:,(adc_start:(adc_start+length(abs_datetime)-1)));
usable_adc_sample_data = num2cell(usable_adc_sample_data);
% I need to get the second row of the ADC data to be the same as the first
usable_adc_sample_data(1,:) = usable_adc_sample_data(2,:);

% Sort ABS data now
imported_abs = ABSData((7:end),(2:101));
ABSData_only = ABSData(7:end,:);
time_stamp_data = ABSData_only(:,2:2:end-1);        % Gets the timestamp data from the file
time_stamp_data = table2array(time_stamp_data);
tooth_data = ABSData_only(:,3:2:end);               % Gets the tooth data from the file
tooth_data = table2array(tooth_data);


% Now to sort ABS data
% imported_abs = ABSData((7:end),(2:101));
% ABSData_only = ABSData(7:end,:);
% time_stamp_data = ABSData_only(:,2:2:end-1);        % Gets the timestamp data from the file
% time_stamp_data = table2array(time_stamp_data);
% tooth_data = ABSData_only(:,3:2:end);               % Gets the tooth data from the file
% tooth_data = table2array(tooth_data);

time_stamp_data = time_stamp_data(:,abs_start:end);
tooth_data = tooth_data(:,abs_start:end);

[row,col] = size(tooth_data);
usable_abs_sample_data = zeros(2*row,col);

% Interleave data
k = 1;
for i = 1:150
    usable_abs_sample_data(k,:) = time_stamp_data(i,:);
    usable_abs_sample_data(k+1,:) = tooth_data(i,:);
    k = k + 2;
end
usable_abs_sample_data = num2cell(usable_abs_sample_data);
end

function [written_table] = csv_builder_fun_1(importedADCData,adc_start,abs_datetime,abs_time_only,adc_time_only,importedABSData,usable_abs_sample_data,usable_adc_sample_data)

%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
% ************************************************************ %
% ************ Generate the ADC and ABS headers ************** %
% ************************************************************ %
% Format: SAMP_CH1#N, where N = 0:511
for i = 1:512
    j = int2str(i-1);
    my_adc_string = strcat('SAMP_CH1#',j);
    adc_sample_headings{i} = my_adc_string; 
    adc_sample_headings = adc_sample_headings';
end

% Build ABS time colums
k = 1;
for i = 1:512
    j = int2str(i);
    my_abs_string = strcat('ABS_TIME#',j);
    abs_time_string{i} = my_abs_string;
    abs_time_string = abs_time_string';
end

% Building ABS tooth column
k = 1;
for i = 1:512
    j = int2str(i);
    my_abs_string = strcat('ABS_TOOTH#',j);
    abs_tooth_string{i} = my_abs_string;
    abs_tooth_string = abs_tooth_string';
end

% Interleave ABS info
j = 1;
for i = 1:150
    abs_sample_headings(j,:) = abs_time_string(i,:);
    abs_sample_headings(j+1,:) = abs_tooth_string(i,:);
    j = j + 2;
end

% Get my abs and adc time into format for table
canoe_sys_time_header = {'CANOE_SYS_TIME'};
CANOE_SYS_TIME = [canoe_sys_time_header,abs_time_only];

adc_sys_time_header = {'NORDIC_SYS_TIME'};
nordic_sys_time = adc_time_only(adc_start:(adc_start+49));
NORDIC_SYS_TIME = [adc_sys_time_header,nordic_sys_time];

% IC2 data
osc_ic2 = importedADCData(((adc_start:(adc_start+length(abs_datetime)-1))),3);
osc_ic2 = osc_ic2';
osc_ic2_cell = num2cell(osc_ic2);
osc_ic2_header = {'OSC_IC2_DEC'};
OSC_IC2 = [osc_ic2_header,osc_ic2_cell];

% Gets Offset
offset = importedADCData(((adc_start:(adc_start+length(abs_datetime)-1))),4);
offset = offset';
offset_len = length(offset);
for i = 1:offset_len
    if offset(i) > 512
        offset_dec(i) = offset(i) - 1024;
    else
        offset_dec(i) = offset(i);
    end
end
offset_dec_cell = num2cell(offset_dec);
offset_dec_header = {'OFFSET_CODE_DEC'};
OFFSET_DEC = [offset_dec_header,offset_dec_cell];

% Gets sample rate; loop sets 1 = 406.25Hz
sample_rate_indicator = importedADCData(((adc_start:(adc_start+length(abs_datetime)-1))),2);
for i = 1:length(abs_datetime)
    if sample_rate_indicator == 1
        sample_rate_freq(i) = 406.25;
    end
end
adc_sample_rate_freq = num2cell(sample_rate_freq);
adc_sample_rate_hz = {'ADC_SAMPLE_RATE_HZ'};
ADC_SAMPLE_RATE_HZ = [adc_sample_rate_hz,adc_sample_rate_freq];

% Gets PAL block timestamp
PAL_block_header = {'PAL_BlockTimeStamp'};
PAL_Block_time_stamp = importedABSData(3,:);
PAL_Block_time_stamp = PAL_Block_time_stamp(~isnan(PAL_Block_time_stamp));
PAL_Block_time_stamp = num2cell(PAL_Block_time_stamp);
PAL_BLOCK_TIMESTAMP = [PAL_block_header,PAL_Block_time_stamp];

% Get microtest time
microtest_time = importedADCData(((adc_start:(adc_start+length(abs_datetime)-1))),5);
microtest_time = microtest_time';
microtest_time_cell = num2cell(microtest_time);
microtest_time_header = {'MICROTEST_TIME'};
MICROTEST_TIME = [microtest_time_header,microtest_time_cell];

% Get ABS frequency
abs_freq = importedABSData(5,:);
abs_freq = abs_freq(~isnan(abs_freq));      % Removes NAN
abs_freq_cell = num2cell(abs_freq);
abs_freq_header = {'ABS_AV_FREQ_HZ'};
ABS_FREQUENCY = [abs_freq_header,abs_freq_cell];

% ***************************************************************** %
% ************* Puts the table together to write ****************** %
% ***************************************************************** %


row_headers = {'DATE';'START_TIME';'DATA_SYSTEM';'SW_VERSION';'PART_ID';'DATA_ID';'ROAD_NAME';...
    'ROAD_SURFACE';'TARGET_SPEED_KPH';'WHEEL_LOC';'WHEEL_TYPE';'TYRE_SIZE';'TREAD_TYPE';...
    'S_ALIGN';'ABS_TOOTH_COUNT';'CAR_MAKE';'CAR_MODEL';'CAR_REG';'ASIC_TEMP';'ASIC_PRESS'};
row_header_info = {
    '25/3/2019';...         % Test Date
    '3:37 PM';...           % Test time
    'NORDIC';...            % Data collection system
    '2.0.11';...            % SW version
    '50B1EB1E';...          % Part ID
    '8072';...              % Data ID
    'DLKS';...               % Road name
    'SR';...                % Road surface
    '60';...               % Target speed
    'FR';...                % Sensor location
    'ALLOY';...             % Wheel type
    '275/45 R19 98Y';...    % Tyre size E-Class: 245/40 R19 98Y; GLE: 275/45 R19 98Y
    'SUMMER';...            % Tread type
    'RAD/PTQ/TAN';...       % Alignment
    '96';...                % ABS tooth count
    'MERCEDES';...          % Vehicle make
    'GLE';...           % Vehicle model
    'BB HX 5699';...        % Vehicle reg E-Class: BB RE 4673; GLE: BB HX 5699
    '';...                  % ASIC temp
    ''...                   % ASIC pressure
    };                
ROW_HEADER_INFO_REPEATED = repmat(row_header_info,1,length(abs_datetime));     % All info, repeated

top_header_sect1_info = [row_headers,ROW_HEADER_INFO_REPEATED];                % Generates my data
% Built from nordic system time, ocs_ic2_dec, adc_sample_rate_hz,
% offset_code_dec
top_header_sect2_info = [NORDIC_SYS_TIME;OSC_IC2;ADC_SAMPLE_RATE_HZ;OFFSET_DEC];
% mid_row_full_info = [mid_row_header,mid_row_info_repeated_50];
TOP_HEADER_FULL = [top_header_sect1_info;top_header_sect2_info];
% Generate mid-table info
MID_TABLE_INFO = [CANOE_SYS_TIME;PAL_BLOCK_TIMESTAMP;MICROTEST_TIME;ABS_FREQUENCY];




% Need to write ABS info
ABS_INFO_FULL = [abs_sample_headings,usable_abs_sample_data];
% Now, ADC data
ADC_INFO_FULL = [adc_sample_headings,usable_adc_sample_data];

COMPLETE_TABLE = [TOP_HEADER_FULL;ADC_INFO_FULL;MID_TABLE_INFO;ABS_INFO_FULL];

% ********************************************************************** %
% ************** Writes my table to a csv file ************************* %
% ********************************************************************** %
% Write data to table
written_table = table(COMPLETE_TABLE);                                              % Converts to table for writing
% writetable(written_table, 'My Test Table.csv','Delimiter',',','QuoteStrings',true,'WriteVariableNames',false);


end

function[abs_date_time,adc_date_time,importedADCData,importedABSData,ADCData,ABSData] = read_in_files(abs_filename, adc_filename)
    abs_filename; % = 'C:\Users\a1038064\Documents\MATLAB\Nordic\ABSData_27-03-19__Time_15-44-27.csv';
    delimiter = ',';
    startRow = 2;
    endRow = 2;
    
    % For more information, see the TEXTSCAN documentation.
    formatSpec = '%*s%*s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%*s%[^\n\r]';

    % ***Open the text file.
    fileID = fopen(abs_filename,'r');

    dataArray = textscan(fileID, formatSpec, endRow-startRow+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');

    % ***Close the text file.
    fclose(fileID);

    % ***Create output variable
    abs_date_time = [dataArray{1:end-1}];

    % ***Clear temporary variables
    % clearvars filename delimiter startRow endRow formatSpec fileID dataArray ans;

    % *************** Import for adc date time
    % ***Initialize variables.
    adc_filename;
    delimiter = ',';
    startRow = 2;

    % ***Format for each line of text:
    %   column1: text (%s)
    % For more information, see the TEXTSCAN documentation.
    formatSpec = '%s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%*s%[^\n\r]';

    % ***Open the text file.
    fileID = fopen(adc_filename,'r');

    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');

    % ***Close the text file.
    fclose(fileID);

    % ***Create output variable
    adc_date_time = [dataArray{1:end-1}];

    % ***Clear temporary variables
    % clearvars filename delimiter startRow formatSpec fileID dataArray ans;

    % ************* Import for ADC
    % Initialize variables for ADC
    adc_filename;
    delimiter = ',';
    startRow = 2;

    % Read columns of data as text:
    % For more information, see the TEXTSCAN documentation.
    formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

    % Open the text file.
    fileID = fopen(adc_filename,'r');
    
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');

    % Close the text file.
    fclose(fileID);

    % Convert the contents of columns containing numeric text to numbers.
    % Replace non-numeric text with NaN.
    raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
    for col=1:length(dataArray)-1
        raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
    end
    numericData = NaN(size(dataArray{1},1),size(dataArray,2));

    for col=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301,302,303,304,305,306,307,308,309,310,311,312,313,314,315,316,317,318,319,320,321,322,323,324,325,326,327,328,329,330,331,332,333,334,335,336,337,338,339,340,341,342,343,344,345,346,347,348,349,350,351,352,353,354,355,356,357,358,359,360,361,362,363,364,365,366,367,368,369,370,371,372,373,374,375,376,377,378,379,380,381,382,383,384,385,386,387,388,389,390,391,392,393,394,395,396,397,398,399,400,401,402,403,404,405,406,407,408,409,410,411,412,413,414,415,416,417,418,419,420,421,422,423,424,425,426,427,428,429,430,431,432,433,434,435,436,437,438,439,440,441,442,443,444,445,446,447,448,449,450,451,452,453,454,455,456,457,458,459,460,461,462,463,464,465,466,467,468,469,470,471,472,473,474,475,476,477,478,479,480,481,482,483,484,485,486,487,488,489,490,491,492,493,494,495,496,497,498,499,500,501,502,503,504,505,506,507,508,509,510,511,512,513,514,515,516,517]
        % Converts text in the input cell array to numbers. Replaced non-numeric
        % text with NaN.
        rawData = dataArray{col};
        for row=1:size(rawData, 1)
            % Create a regular expression to detect and remove non-numeric prefixes and
            % suffixes.
            regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
            try
                result = regexp(rawData(row), regexstr, 'names');
                numbers = result.numbers;

                % Detected commas in non-thousand locations.
                invalidThousandsSeparator = false;
                if numbers.contains(',')
                    thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                    if isempty(regexp(numbers, thousandsRegExp, 'once'))
                        numbers = NaN;
                        invalidThousandsSeparator = true;
                    end
                end
                % Convert numeric text to numbers.
                if ~invalidThousandsSeparator
                    numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                    numericData(row, col) = numbers{1};
                    raw{row, col} = numbers{1};
                end
            catch
                raw{row, col} = rawData{row};
            end
        end
    end


    % Replace non-numeric cells with NaN
    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
    raw(R) = {NaN}; % Replace non-numeric cells

    % Create output variable
    importedADCData = cell2mat(raw);
    % Clear temporary variables
    % clearvars filename delimiter startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp R;



    % *************** Import ABS data in numeric matrix format
    % Initialize variables for ABS
    abs_filename; % = 'C:\Users\a1038064\Documents\MATLAB\Nordic\ABSData_27-03-19__Time_15-44-27.csv';
    delimiter = ',';

    % Read columns of data as text:
    % For more information, see the TEXTSCAN documentation.
    formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

    % Open the text file.
    fileID = fopen(abs_filename,'r');

    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string',  'ReturnOnError', false);

    % Close the text file.
    fclose(fileID);

    % Convert the contents of columns containing numeric text to numbers.
    % Replace non-numeric text with NaN.
    raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
    for col=1:length(dataArray)-1
        raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
    end
    numericData = NaN(size(dataArray{1},1),size(dataArray,2));

    for col=[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101]
        % Converts text in the input cell array to numbers. Replaced non-numeric
        % text with NaN.
        rawData = dataArray{col};
        for row=1:size(rawData, 1)
            % Create a regular expression to detect and remove non-numeric prefixes and
            % suffixes.
            regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
            try
                result = regexp(rawData(row), regexstr, 'names');
                numbers = result.numbers;

                % Detected commas in non-thousand locations.
                invalidThousandsSeparator = false;
                if numbers.contains(',')
                    thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                    if isempty(regexp(numbers, thousandsRegExp, 'once'))
                        numbers = NaN;
                        invalidThousandsSeparator = true;
                    end
                end
                % Convert numeric text to numbers.
                if ~invalidThousandsSeparator
                    numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                    numericData(row, col) = numbers{1};
                    raw{row, col} = numbers{1};
                end
            catch
                raw{row, col} = rawData{row};
            end
        end
    end


    % Replace non-numeric cells with NaN
    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
    raw(R) = {NaN}; % Replace non-numeric cells

    % Create output variable
    importedABSData = cell2mat(raw);
    % Clear temporary variables
    % clearvars filename delimiter formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp R;

    % **************** END


    % --------------- Below for ABS

    % %% Import data from text file.
    % %% Initialize variables.
    abs_filename; % = 'C:\Users\a1038064\Documents\MATLAB\Nordic\ABSData_27-03-19__Time_15-44-27.csv';
    delimiter = ',';

    % %% Read columns of data as text:
    % For more information, see the TEXTSCAN documentation.
    formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

    % %% Open the text file.
    fileID = fopen(abs_filename,'r');
    
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string',  'ReturnOnError', false);

    % %% Close the text file.
    fclose(fileID);

    % %% Convert the contents of columns containing numeric text to numbers.
    % Replace non-numeric text with NaN.
    raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
    for col=1:length(dataArray)-1
        raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
    end
    numericData = NaN(size(dataArray{1},1),size(dataArray,2));

    for col=[2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101]
        % Converts text in the input cell array to numbers. Replaced non-numeric
        % text with NaN.
        rawData = dataArray{col};
        for row=1:size(rawData, 1)
            % Create a regular expression to detect and remove non-numeric prefixes and
            % suffixes.
            regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
            try
                result = regexp(rawData(row), regexstr, 'names');
                numbers = result.numbers;

                % Detected commas in non-thousand locations.
                invalidThousandsSeparator = false;
                if numbers.contains(',')
                    thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                    if isempty(regexp(numbers, thousandsRegExp, 'once'))
                        numbers = NaN;
                        invalidThousandsSeparator = true;
                    end
                end
                % Convert numeric text to numbers.
                if ~invalidThousandsSeparator
                    numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                    numericData(row, col) = numbers{1};
                    raw{row, col} = numbers{1};
                end
            catch
                raw{row, col} = rawData{row};
            end
        end
    end


    % %% Split data into numeric and string columns.
    rawNumericColumns = raw(:, [2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101]);
    rawStringColumns = string(raw(:, [1,102]));


    % %% Replace non-numeric cells with NaN
    R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
    rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

    % %% Create output variable
    ABSData = table;
    ABSData.BlockNumber = rawStringColumns(:, 1);
    ABSData.VarName2 = cell2mat(rawNumericColumns(:, 1));
    ABSData.VarName3 = cell2mat(rawNumericColumns(:, 2));
    ABSData.VarName4 = cell2mat(rawNumericColumns(:, 3));
    ABSData.VarName5 = cell2mat(rawNumericColumns(:, 4));
    ABSData.VarName6 = cell2mat(rawNumericColumns(:, 5));
    ABSData.VarName7 = cell2mat(rawNumericColumns(:, 6));
    ABSData.VarName8 = cell2mat(rawNumericColumns(:, 7));
    ABSData.VarName9 = cell2mat(rawNumericColumns(:, 8));
    ABSData.VarName10 = cell2mat(rawNumericColumns(:, 9));
    ABSData.VarName11 = cell2mat(rawNumericColumns(:, 10));
    ABSData.VarName12 = cell2mat(rawNumericColumns(:, 11));
    ABSData.VarName13 = cell2mat(rawNumericColumns(:, 12));
    ABSData.VarName14 = cell2mat(rawNumericColumns(:, 13));
    ABSData.VarName15 = cell2mat(rawNumericColumns(:, 14));
    ABSData.VarName16 = cell2mat(rawNumericColumns(:, 15));
    ABSData.VarName17 = cell2mat(rawNumericColumns(:, 16));
    ABSData.VarName18 = cell2mat(rawNumericColumns(:, 17));
    ABSData.VarName19 = cell2mat(rawNumericColumns(:, 18));
    ABSData.VarName20 = cell2mat(rawNumericColumns(:, 19));
    ABSData.VarName21 = cell2mat(rawNumericColumns(:, 20));
    ABSData.VarName22 = cell2mat(rawNumericColumns(:, 21));
    ABSData.VarName23 = cell2mat(rawNumericColumns(:, 22));
    ABSData.VarName24 = cell2mat(rawNumericColumns(:, 23));
    ABSData.VarName25 = cell2mat(rawNumericColumns(:, 24));
    ABSData.VarName26 = cell2mat(rawNumericColumns(:, 25));
    ABSData.VarName27 = cell2mat(rawNumericColumns(:, 26));
    ABSData.VarName28 = cell2mat(rawNumericColumns(:, 27));
    ABSData.VarName29 = cell2mat(rawNumericColumns(:, 28));
    ABSData.VarName30 = cell2mat(rawNumericColumns(:, 29));
    ABSData.VarName31 = cell2mat(rawNumericColumns(:, 30));
    ABSData.VarName32 = cell2mat(rawNumericColumns(:, 31));
    ABSData.VarName33 = cell2mat(rawNumericColumns(:, 32));
    ABSData.VarName34 = cell2mat(rawNumericColumns(:, 33));
    ABSData.VarName35 = cell2mat(rawNumericColumns(:, 34));
    ABSData.VarName36 = cell2mat(rawNumericColumns(:, 35));
    ABSData.VarName37 = cell2mat(rawNumericColumns(:, 36));
    ABSData.VarName38 = cell2mat(rawNumericColumns(:, 37));
    ABSData.VarName39 = cell2mat(rawNumericColumns(:, 38));
    ABSData.VarName40 = cell2mat(rawNumericColumns(:, 39));
    ABSData.VarName41 = cell2mat(rawNumericColumns(:, 40));
    ABSData.VarName42 = cell2mat(rawNumericColumns(:, 41));
    ABSData.VarName43 = cell2mat(rawNumericColumns(:, 42));
    ABSData.VarName44 = cell2mat(rawNumericColumns(:, 43));
    ABSData.VarName45 = cell2mat(rawNumericColumns(:, 44));
    ABSData.VarName46 = cell2mat(rawNumericColumns(:, 45));
    ABSData.VarName47 = cell2mat(rawNumericColumns(:, 46));
    ABSData.VarName48 = cell2mat(rawNumericColumns(:, 47));
    ABSData.VarName49 = cell2mat(rawNumericColumns(:, 48));
    ABSData.VarName50 = cell2mat(rawNumericColumns(:, 49));
    ABSData.VarName51 = cell2mat(rawNumericColumns(:, 50));
    ABSData.VarName52 = cell2mat(rawNumericColumns(:, 51));
    ABSData.VarName53 = cell2mat(rawNumericColumns(:, 52));
    ABSData.VarName54 = cell2mat(rawNumericColumns(:, 53));
    ABSData.VarName55 = cell2mat(rawNumericColumns(:, 54));
    ABSData.VarName56 = cell2mat(rawNumericColumns(:, 55));
    ABSData.VarName57 = cell2mat(rawNumericColumns(:, 56));
    ABSData.VarName58 = cell2mat(rawNumericColumns(:, 57));
    ABSData.VarName59 = cell2mat(rawNumericColumns(:, 58));
    ABSData.VarName60 = cell2mat(rawNumericColumns(:, 59));
    ABSData.VarName61 = cell2mat(rawNumericColumns(:, 60));
    ABSData.VarName62 = cell2mat(rawNumericColumns(:, 61));
    ABSData.VarName63 = cell2mat(rawNumericColumns(:, 62));
    ABSData.VarName64 = cell2mat(rawNumericColumns(:, 63));
    ABSData.VarName65 = cell2mat(rawNumericColumns(:, 64));
    ABSData.VarName66 = cell2mat(rawNumericColumns(:, 65));
    ABSData.VarName67 = cell2mat(rawNumericColumns(:, 66));
    ABSData.VarName68 = cell2mat(rawNumericColumns(:, 67));
    ABSData.VarName69 = cell2mat(rawNumericColumns(:, 68));
    ABSData.VarName70 = cell2mat(rawNumericColumns(:, 69));
    ABSData.VarName71 = cell2mat(rawNumericColumns(:, 70));
    ABSData.VarName72 = cell2mat(rawNumericColumns(:, 71));
    ABSData.VarName73 = cell2mat(rawNumericColumns(:, 72));
    ABSData.VarName74 = cell2mat(rawNumericColumns(:, 73));
    ABSData.VarName75 = cell2mat(rawNumericColumns(:, 74));
    ABSData.VarName76 = cell2mat(rawNumericColumns(:, 75));
    ABSData.VarName77 = cell2mat(rawNumericColumns(:, 76));
    ABSData.VarName78 = cell2mat(rawNumericColumns(:, 77));
    ABSData.VarName79 = cell2mat(rawNumericColumns(:, 78));
    ABSData.VarName80 = cell2mat(rawNumericColumns(:, 79));
    ABSData.VarName81 = cell2mat(rawNumericColumns(:, 80));
    ABSData.VarName82 = cell2mat(rawNumericColumns(:, 81));
    ABSData.VarName83 = cell2mat(rawNumericColumns(:, 82));
    ABSData.VarName84 = cell2mat(rawNumericColumns(:, 83));
    ABSData.VarName85 = cell2mat(rawNumericColumns(:, 84));
    ABSData.VarName86 = cell2mat(rawNumericColumns(:, 85));
    ABSData.VarName87 = cell2mat(rawNumericColumns(:, 86));
    ABSData.VarName88 = cell2mat(rawNumericColumns(:, 87));
    ABSData.VarName89 = cell2mat(rawNumericColumns(:, 88));
    ABSData.VarName90 = cell2mat(rawNumericColumns(:, 89));
    ABSData.VarName91 = cell2mat(rawNumericColumns(:, 90));
    ABSData.VarName92 = cell2mat(rawNumericColumns(:, 91));
    ABSData.VarName93 = cell2mat(rawNumericColumns(:, 92));
    ABSData.VarName94 = cell2mat(rawNumericColumns(:, 93));
    ABSData.VarName95 = cell2mat(rawNumericColumns(:, 94));
    ABSData.VarName96 = cell2mat(rawNumericColumns(:, 95));
    ABSData.VarName97 = cell2mat(rawNumericColumns(:, 96));
    ABSData.VarName98 = cell2mat(rawNumericColumns(:, 97));
    ABSData.VarName99 = cell2mat(rawNumericColumns(:, 98));
    ABSData.VarName100 = cell2mat(rawNumericColumns(:, 99));
    ABSData.VarName101 = cell2mat(rawNumericColumns(:, 100));
    ABSData.VarName102 = rawStringColumns(:, 2);

    % %% Clear temporary variables
    % clearvars filename delimiter formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp rawNumericColumns rawStringColumns R;

    % --------------- Below for ADC Data


    % %% Import data from text file.
    % Script for importing data from the following text file:
    %
    %    C:\Users\a1038064\Documents\MATLAB\Nordic\__50KPH.csv
    %
    % To extend the code to different selected data or a different text file,
    % generate a function instead of a script.

    % Auto-generated by MATLAB on 2019/04/18 15:52:56

    % %% Initialize variables.
    adc_filename; % = 'C:\Users\a1038064\Documents\MATLAB\Nordic\__50KPH.csv';
    delimiter = ',';
    startRow = 2;

    % %% Format for each line of text:
    % For more information, see the TEXTSCAN documentation.
    formatSpec = '%s%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';

    % %% Open the text file.
    fileID = fopen(adc_filename,'r');

    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'EmptyValue', NaN, 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');

    % %% Close the text file.
    fclose(fileID);

    % %% Create output variable
    ADCData = table(dataArray{1:end-1}, 'VariableNames', {'VarName1','VarName2','VarName3','VarName4','VarName5','VarName6','VarName7','VarName8','VarName9','VarName10','VarName11','VarName12','VarName13','VarName14','VarName15','VarName16','VarName17','VarName18','VarName19','VarName20','VarName21','VarName22','VarName23','VarName24','VarName25','VarName26','VarName27','VarName28','VarName29','VarName30','VarName31','VarName32','VarName33','VarName34','VarName35','VarName36','VarName37','VarName38','VarName39','VarName40','VarName41','VarName42','VarName43','VarName44','VarName45','VarName46','VarName47','VarName48','VarName49','VarName50','VarName51','VarName52','VarName53','VarName54','VarName55','VarName56','VarName57','VarName58','VarName59','VarName60','VarName61','VarName62','VarName63','VarName64','VarName65','VarName66','VarName67','VarName68','VarName69','VarName70','VarName71','VarName72','VarName73','VarName74','VarName75','VarName76','VarName77','VarName78','VarName79','VarName80','VarName81','VarName82','VarName83','VarName84','VarName85','VarName86','VarName87','VarName88','VarName89','VarName90','VarName91','VarName92','VarName93','VarName94','VarName95','VarName96','VarName97','VarName98','VarName99','VarName100','VarName101','VarName102','VarName103','VarName104','VarName105','VarName106','VarName107','VarName108','VarName109','VarName110','VarName111','VarName112','VarName113','VarName114','VarName115','VarName116','VarName117','VarName118','VarName119','VarName120','VarName121','VarName122','VarName123','VarName124','VarName125','VarName126','VarName127','VarName128','VarName129','VarName130','VarName131','VarName132','VarName133','VarName134','VarName135','VarName136','VarName137','VarName138','VarName139','VarName140','VarName141','VarName142','VarName143','VarName144','VarName145','VarName146','VarName147','VarName148','VarName149','VarName150','VarName151','VarName152','VarName153','VarName154','VarName155','VarName156','VarName157','VarName158','VarName159','VarName160','VarName161','VarName162','VarName163','VarName164','VarName165','VarName166','VarName167','VarName168','VarName169','VarName170','VarName171','VarName172','VarName173','VarName174','VarName175','VarName176','VarName177','VarName178','VarName179','VarName180','VarName181','VarName182','VarName183','VarName184','VarName185','VarName186','VarName187','VarName188','VarName189','VarName190','VarName191','VarName192','VarName193','VarName194','VarName195','VarName196','VarName197','VarName198','VarName199','VarName200','VarName201','VarName202','VarName203','VarName204','VarName205','VarName206','VarName207','VarName208','VarName209','VarName210','VarName211','VarName212','VarName213','VarName214','VarName215','VarName216','VarName217','VarName218','VarName219','VarName220','VarName221','VarName222','VarName223','VarName224','VarName225','VarName226','VarName227','VarName228','VarName229','VarName230','VarName231','VarName232','VarName233','VarName234','VarName235','VarName236','VarName237','VarName238','VarName239','VarName240','VarName241','VarName242','VarName243','VarName244','VarName245','VarName246','VarName247','VarName248','VarName249','VarName250','VarName251','VarName252','VarName253','VarName254','VarName255','VarName256','VarName257','VarName258','VarName259','VarName260','VarName261','VarName262','VarName263','VarName264','VarName265','VarName266','VarName267','VarName268','VarName269','VarName270','VarName271','VarName272','VarName273','VarName274','VarName275','VarName276','VarName277','VarName278','VarName279','VarName280','VarName281','VarName282','VarName283','VarName284','VarName285','VarName286','VarName287','VarName288','VarName289','VarName290','VarName291','VarName292','VarName293','VarName294','VarName295','VarName296','VarName297','VarName298','VarName299','VarName300','VarName301','VarName302','VarName303','VarName304','VarName305','VarName306','VarName307','VarName308','VarName309','VarName310','VarName311','VarName312','VarName313','VarName314','VarName315','VarName316','VarName317','VarName318','VarName319','VarName320','VarName321','VarName322','VarName323','VarName324','VarName325','VarName326','VarName327','VarName328','VarName329','VarName330','VarName331','VarName332','VarName333','VarName334','VarName335','VarName336','VarName337','VarName338','VarName339','VarName340','VarName341','VarName342','VarName343','VarName344','VarName345','VarName346','VarName347','VarName348','VarName349','VarName350','VarName351','VarName352','VarName353','VarName354','VarName355','VarName356','VarName357','VarName358','VarName359','VarName360','VarName361','VarName362','VarName363','VarName364','VarName365','VarName366','VarName367','VarName368','VarName369','VarName370','VarName371','VarName372','VarName373','VarName374','VarName375','VarName376','VarName377','VarName378','VarName379','VarName380','VarName381','VarName382','VarName383','VarName384','VarName385','VarName386','VarName387','VarName388','VarName389','VarName390','VarName391','VarName392','VarName393','VarName394','VarName395','VarName396','VarName397','VarName398','VarName399','VarName400','VarName401','VarName402','VarName403','VarName404','VarName405','VarName406','VarName407','VarName408','VarName409','VarName410','VarName411','VarName412','VarName413','VarName414','VarName415','VarName416','VarName417','VarName418','VarName419','VarName420','VarName421','VarName422','VarName423','VarName424','VarName425','VarName426','VarName427','VarName428','VarName429','VarName430','VarName431','VarName432','VarName433','VarName434','VarName435','VarName436','VarName437','VarName438','VarName439','VarName440','VarName441','VarName442','VarName443','VarName444','VarName445','VarName446','VarName447','VarName448','VarName449','VarName450','VarName451','VarName452','VarName453','VarName454','VarName455','VarName456','VarName457','VarName458','VarName459','VarName460','VarName461','VarName462','VarName463','VarName464','VarName465','VarName466','VarName467','VarName468','VarName469','VarName470','VarName471','VarName472','VarName473','VarName474','VarName475','VarName476','VarName477','VarName478','VarName479','VarName480','VarName481','VarName482','VarName483','VarName484','VarName485','VarName486','VarName487','VarName488','VarName489','VarName490','VarName491','VarName492','VarName493','VarName494','VarName495','VarName496','VarName497','VarName498','VarName499','VarName500','VarName501','VarName502','VarName503','VarName504','VarName505','VarName506','VarName507','VarName508','VarName509','VarName510','VarName511','VarName512','VarName513','VarName514','VarName515','VarName516','VarName517'});

    % %% Clear temporary variables
    % clearvars filename delimiter startRow formatSpec fileID dataArray ans;

    
end
