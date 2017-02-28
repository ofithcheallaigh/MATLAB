x = [5 4 3 2 1];
% Insertion sort
n = length(x);
for j = 2:n
    myNumber = x(j);                % Value we are interested in
    i = j;                          % i is equal to index value  
    while ((i > 1) && (x(i - 1) > myNumber))    % while in loop AND the value before index > myNumber
        x(i) = x(i - 1);                        % put myNumber into the index before current one
        i = i - 1;                              % Now focus on index before current one
    end
    x(i) = myNumber;                            % Put myNumber in this new index
end
