function [Complete_y_fit] = bootstrapLine(epochs, x_values, y_values, x_test)
% bootstrapLine - Function that performs the bootstrapping

Complete_y_fit = zeros(epochs, length(y_values));

if length(x_values) == length(y_values)
    windowLength = length(x_values);
else
    warning("X and Y data have different lengths");
end

for epoch = 1:epochs
    x_resampled = zeros(1,windowLength);
    y_resampled = zeros(1,windowLength);

    for len=1:windowLength
        samp = randi(windowLength);
        x_resampled(len) = x_values(samp);
        y_resampled(len) = y_values(samp);
    end

    p = polyfit(x_resampled, y_resampled, 1);
    Complete_y_fit(epoch, :) = polyval(p, x_test);
end
end

