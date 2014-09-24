function objTester( models, bboxname, imagename, options )
% Testing for the (Latent) SVM models
% -------------------------------------------------------------------------
% Unsupervised Object Discovery and Segmentation
% Xinlei Chen, 2014 [enderchen@cs.cmu.edu]
% Please email me if you find bugs, or have suggestions or questions
% -------------------------------------------------------------------------

start = tic;

if nargin < 4
    options = [];
end

thresOffset = -0.5;
if isfield(options,'thresOffset')
    thresOffset = options.thresOffset;
end

featurename = 'CHOG';
if isfield(options,'lsvmFeatureName')
    featurename = options.lsvmFeatureName;
end

testInterval = 6;
if isfield(options,'testIntervalScene')
    testInterval = options.testIntervalScene;
end

disp(['Interval for the pyramid set to: ', int2str(testInterval)]);
models{1}.interval = testInterval;

if ~isfield(options,'now')
    options.now = 0;
else
    disp(options.now);
end

if ~isfield(options,'timelimit')
    options.timelimit = inf;
end

im = imread(imagename);

% do the detection
threshes = cellfun(@(x)x.thresh,models);

% split the models to make proper for memrory usage
maxModelsOnes = 1000;
l = length(models);
iters = ceil(l / maxModelsOnes);
disp(iters);
bboxes = cell(iters,1);
for i=1:iters
    startIter = (i - 1) * maxModelsOnes + 1;
    endIter = min(l, startIter + maxModelsOnes - 1);
    models{startIter}.interval = testInterval;
    disp([startIter,endIter]);
    bboxes{i} = imgdetectBLOCK(im, models(startIter:endIter), max(min(threshes(startIter:endIter) + thresOffset,0),-2), featurename, options);
end

bboxes = cat(1,bboxes{:});

% reduce using nms
for i=1:length(bboxes)
    if ~isempty(bboxes{i})
        ind = Nms(bboxes{i}(:,[1:4,6]), 0.5);
        bboxes{i} = bboxes{i}(ind,:);
    end
end

vars = {bboxes};
varNs = {'bboxes'};
saveFS(bboxname, vars, varNs);
fprintf('Testing took %.4f seconds\n', toc(start));

end
