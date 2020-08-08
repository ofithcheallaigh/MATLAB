input_signal = load('signal_1hz_20hz.txt');                     % Signal to be filtered
filter_points = 5;                                              % Number of filter points
filtered_signal = movmean(input_signal, filter_points);         % In nuilt MATLAB function for the moving average

% Plotting
subplot(2,1,1)  
plot(input_signal)
title('Noisy Input Signal');

subplot(2,1,2)
plot(filtered_signal)
title('Filtered Signal (using 11pts Moving Average)')

shg();                                                          % Bring graph to the front