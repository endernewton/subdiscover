function showPerformancePerClass(xPerClass, classes, methods, yLabel)


nClasses = length(classes);
assert(size(xPerClass,1) == nClasses);
nMethods = length(methods);
assert(size(xPerClass,2) == nMethods);

% add averages
x = [mean(xPerClass,1) ; nan(1,nMethods) ; xPerClass];
xLabels = {'Average','',classes{:}};

figure('Color', [1,1,1], 'Position', [1,1,800,500]);
h = bar(x, 'edgecolor', 'none');
xlim([0,length(xLabels)+1]);
set(gca, 'FontName', 'Times', 'FontSize', 12);
xticklabel_rotate(1:length(xLabels), 75, name2str(xLabels), 'FontName', 'Times', 'FontSize', 12);
ylabel(yLabel, 'FontName', 'Times', 'FontSize', 14);
set(gca, 'TickLength', [0,0]); % remove tick marks

legend(h, name2str(methods), 'Location', 'NorthOutside', 'Orientation', 'Horizontal', 'FontName', 'Times', 'FontSize', 10);
