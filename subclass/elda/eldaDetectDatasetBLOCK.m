function [boxes, scales]=eldaDetectDatasetBLOCK(test, models, name, fname, options)
% boxes=test_dataset(test, model, name)
% test is struct array with fields:
%	im:full path to image

if nargin < 5
    options = [];
end

lm = length(models);
lt = length(test);

boxes = cell(lm,lt);
scales = zeros(1,lt);

bboxMinMax = inf;
if isfield(options,'bboxMinMax')
    bboxMinMax = options.bboxMinMax;
end

bboxMaxMax = -inf;
if isfield(options,'bboxMaxMax')
    bboxMaxMax = options.bboxMaxMax;
end

for i = 1:lt
    tic;
    fprintf('%s: testing: %d/%d\n', name, i, length(test));
    im = imread(test(i).im);
    [im,scales(i)] = resizeminmax(im(test(i).y1:test(i).y2,test(i).x1:test(i).x2,:),bboxMinMax,bboxMaxMax);
    boxes(:,i) = eldaDetectBLOCK(im, models, fname, 0, options);
    toc;
end

