function [statLine] = getStats(data)
% get minimum, median, maximum, quartiles, mode, and mean of given data

% reduce to column vector
reduced1D = data(:);
valueMinimum = min(reduced1D);
valueQ1 = prctile(reduced1D, 25);
valueMedian = median(reduced1D);
valueQ3 = prctile(reduced1D, 75);
valueMaximum = max(reduced1D);
valueMode = mode(reduced1D);
valueMean = mean(reduced1D);

statLine = {['min: ', num2str(valueMinimum), ...
    ', Q1: ', num2str(valueQ1), ...
    ', median: ', num2str(valueMedian), ...
    ', Q3: ', num2str(valueQ3), ...
    ', max: ', num2str(valueMaximum), ...
    ', mode: ', num2str(valueMode), ...
    ', mean: ' num2str(valueMean)]};

end