function [P, J, classes] = evaluateSegmentationMultiClass(resultDir, datasetDir)


classes = getDirectoryNames(datasetDir);
nClasses = length(classes);

P = zeros(1, nClasses);
J = zeros(1, nClasses);

for i = 1:nClasses
    class = classes{i};
    disp(class);
    
    maskDir = fullfile(resultDir, class);
    gtDir = fullfile(datasetDir, class, 'GroundTruth');
    
    [P(i), J(i)] = evaluateSegmentation(maskDir, gtDir);
end

