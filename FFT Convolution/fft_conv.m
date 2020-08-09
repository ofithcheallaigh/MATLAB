a = [1,1,1,0,0,0,1,1,1];        % 9 samples long
b = [1,0,1,1];                  % 4 samples long
d = zeros(1,7);                 % Zeros used to build zero padded a sample
x = [a,d];                      % Concatenating
d = zeros(1,12);                % Reusing variable
y = [b,d];                      % Concatenating
% Now we have two series of 16 samples for our input

X = fft(x);
Y = fft(y);

C = X.*Y;                       % Elementwise multiplication
c = ifft(C);                    % Inverse transform


