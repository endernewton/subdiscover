function objTrainerMAT( cls, modelname, cacheDir, logpath, imagenames, detections, clusterind, options )
% The function modified from DPM v5, to train Latent SVM detectors. Credit: Pedro Felzenszwalb, Ross
% Girshick, Deva Ramanan
% modelname is the path to save the final model
% cache is the path to save the temporary model
% -------------------------------------------------------------------------
% Unsupervised Object Discovery and Segmentation
% Xinlei Chen, 2014 [enderchen@cs.cmu.edu]
% Please email me if you find bugs, or have suggestions or questions
% -------------------------------------------------------------------------
start = tic;

if nargin < 8
    options = [];
end

stamp = [cls,'-',date];

note = stamp;
if isfield(options,'note')
    note = options.note;
end

cachesize = 24000;
if isfield(options,'cachesize')
    cachesize = options.cachesize;
end

cachebyte = 5*2^30;
if isfield(options,'cachebyte')
    cachebyte = options.cachebyte;
end

maxnegsmall = 200;
if isfield(options,'maxnegsmall')
    maxnegsmall = options.maxnegsmall;
end

maxneglarge = 10000;
if isfield(options,'maxneglarge')
    maxneglarge = options.maxneglarge;
end

wlssvmM = 0;
if isfield(options,'wlssvmM')
    wlssvmM = options.wlssvmM;
end

fgOverlap = 0.7;
if isfield(options,'fgOverlap')
    fgOverlap = options.fgOverlap;
end

sbin = 8;
if isfield(options,'lsvmSbin')
    sbin = options.lsvmSbin;
end

interval = 10;
if isfield(options,'lsvmInterval')
    interval = options.lsvmInterval;
end

regu = 0.002;
if isfield(options,'lsvmRegu')
    regu = options.lsvmRegu;
end

if ~isfield(options,'now')
    options.now = 0;
else
    disp(options.now);
end

if ~isfield(options,'timelimit')
    options.timelimit = inf;
else
    disp(options.timelimit);
end

featurename = 'CHOG';
if isfield(options,'lsvmFeatureName')
    featurename = options.lsvmFeatureName;
end

fixedSeed = 0;
if isfield(options,'fixedSeed')
    fixedSeed = options.fixedSeed;
end

[ pos, neg, impos ] = objDataOrgMAT( imagenames, detections, clusterind, cacheDir, options );

nComp = 1;
if isfield(options,'nComp')
    nComp = options.nComp;
end

nCore = 1;
if isfield(options,'nCore')
    nCore = options.nCore;
end

if nComp > 1
    spos = split(pos, nComp);
    nComp = length(spos);
else
    spos = {pos};
    nComp = 1;
end

if fixedSeed
    RandStream('twister','Seed',0); % just to make sure the performance
end

nNeg = length(neg);
negPerm = neg(randperm(nNeg));
negSmall = negPerm(1:min(nNeg,maxnegsmall));
negPerm = neg(randperm(nNeg));
negLarge = negPerm(1:min(maxneglarge,nNeg));

if try_get_matlabpool_size == 0 && nCore > 1
    reopen_parallel_pool(nCore);
end

try
    load([cacheDir '/' cls '_lrsplit1'],'models');
catch ME
    disp(ME.message);
    %   initrand();
    for i = 1:nComp
        % split data into two groups: left vs. right facing instances
        models{i} = root_model(cls, spos{i}, note, sbin, interval, featurename);
        inds = lrsplit(models{i}, spos{i}, featurename);
        models{i} = lsvmTrain(models{i}, spos{i}(inds), negLarge, true, true, 1, 1, ...
            cachesize, fgOverlap, 0, false, ['lrsplit1_' num2str(i)], regu, cachebyte, cacheDir, featurename);
    end
    save([cacheDir '/' cls '_lrsplit1'],'models');
end

now = toc(start);
if now + options.now > options.timelimit
    disp(now + options.now);
    close_parallel_pool();
    rmdir(logpath);
    error('Time Limits!');
end

% train root left vs. right facing root filters using latent detections
% and hard negatives
try
    load([cacheDir '/' cls '_lrsplit2'],'models');
catch ME
    disp(ME.message);
    %   initrand();
    for i = 1:nComp
        models{i} = lr_root_model(models{i},featurename);
        models{i} = lsvmTrain(models{i}, spos{i}, negSmall, false, false, 4, 3, ...
            cachesize, fgOverlap, 0, false, ['lrsplit2_' num2str(i)], regu, cachebyte, cacheDir, featurename);
    end
    save([cacheDir '/' cls '_lrsplit2'],'models');
end

now = toc(start);
if now + options.now > options.timelimit
    disp(now + options.now);
    close_parallel_pool();
    rmdir(logpath);
    error('Time Limits!');
end

% merge models and train using latent detections & hard negatives
try 
  load([cacheDir '/' cls '_mix'], 'model');
catch ME
    disp(ME.message);
%   initrand();
    model = model_merge(models);
    model = lsvmTrain(model, impos, negSmall, false, false, 1, 5, ...
        cachesize, fgOverlap, wlssvmM, false, 'mix', regu, cachebyte, cacheDir, featurename);
    save([cacheDir '/' cls '_mix'], 'model');
end

save(modelname, 'model','neg');

close_parallel_pool();

end

function s = close_parallel_pool()
try
    s = matlabpool('size');
    if s > 0
        matlabpool('close', 'force');
    end
catch ME
    disp(ME.message);
    s = 0;
end
end


function reopen_parallel_pool(s)
if s > 0
    while true
        try
            matlabpool('open', s);
            break;
        catch ME
            disp(ME.message);
            fprintf('Ugg! Something bad happened. Trying again in 10 seconds...\n');
            pause(10);
        end
    end
end
end


function s = try_get_matlabpool_size()
try
    s = matlabpool('size');
catch ME
    disp(ME.message);
    s = 0;
end
end

