function boxes = eldaDetectDatasetBSim(test, models, name, fname, options)
% boxes=test_dataset(test, model, name)
% test is struct array with fields:
%	im:full path to image

if nargin < 5
    options = [];
end

lm = length(models);
lt = length(test);

boxes = cell(lm,lt);

for i = 1:lt
    tic;
    fprintf('%s: testing: %d/%d\n', name, i, length(test));
    im = color(imread(test(i).im));
    boxes(:,i) = eldaDetectBLOCKE(im, models, fname, 0, options);
    toc;
end

