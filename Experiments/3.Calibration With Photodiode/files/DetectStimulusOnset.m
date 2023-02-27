function [stimOnsetTime, stimOnsetValue, stimTimePredictionError] = DetectStimulusOnset(data, time, line1StartIdx, line1EndIdx, line2StartIdx, line2EndIdx, bootstrapEpochs)
% DetectStimulusOnset: This enables us to find the intersection between two
% lines. Here we bootstrap across the data and the mean intersection of two
% is given as the output. The std of the intersection points gives the
% error.

intersectionPoints = zeros(bootstrapEpochs, 2);

% Finding the stimulus onset
Line1CompleteFits = bootstrapLine(bootstrapEpochs, time(line1StartIdx : line1EndIdx), data(line1StartIdx : line1EndIdx), time); % Fitting line 1
Line2CompleteFits = bootstrapLine(bootstrapEpochs, time(line2StartIdx : line2EndIdx), data(line2StartIdx : line2EndIdx), time); % Fitting line 2

for epoch=1:bootstrapEpochs
    [intersectionPoints(epoch, 1), intersectionPoints(epoch, 2)] = polyxpoly(time, Line1CompleteFits(epoch, :), x_test, Line2CompleteFits(epoch, :)); % Intersection of the two lines
end

stimOnsetTime = mean(intersectionPoints(:, 1)); % Mean time of estimated stimulus onsets
stimOnsetValue = mean(intersectionPoints(:, 2)); % Mean values of estimated stimulus onsets
stimTimePredictionError = std(intersectionPoints(:, 1)); % Jitter in the time prediction
end

