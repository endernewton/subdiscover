function [segs,numelchange,evalresset,avgmasks,BGMean,FGMean,BGCov,FGCov] = GCAlgoTransferNB(images,masks,bboxes,options)
% Modifild version of Graph Cut, used to do joint graph cuts for aligned
% image patches, Credit: Itay Blumenthal
% -------------------------------------------------------------------------
% Unsupervised Object Discovery and Segmentation
% Xinlei Chen, 2014 [enderchen@cs.cmu.edu]
% Please email me if you find bugs, or have suggestions or questions
% -------------------------------------------------------------------------

if nargin < 3
    options = [];
end

diffThreshold = 0.001;
if isfield(options,'diffThreshold')
    diffThreshold = options.diffThreshold;
end

maxIterations = 10;
if isfield(options,'maxIterGC')
    maxIterations = options.maxIterGC;
end

K = 5;
if isfield(options,'KGC')
    K = options.KGC;
end

KGroup = 5;
if isfield(options,'KGCGroup')
    KGroup = options.KGCGroup;
end

Beta = 0.5;
if isfield(options,'Beta')
    Beta = options.Beta;
end

G = 50;
if isfield(options,'GGC')
    G = options.GGC;
end

alpha = 1;
if isfield(options,'Alpha')
    alpha = options.Alpha;
end
disp(alpha);

convergeRate = 0.1;
if isfield(options,'convergeRateGroup')
    convergeRate = options.convergeRateGroup;
end

fixedSeed = 0;
if isfield(options,'fixedSeed')
    fixedSeed = options.fixedSeed;
end

if fixedSeed
    RandStream('twister','Seed',0); % just to make sure the performance
end

maskimages = options.maskimages;
N = length(images);
images = images(:);
masks = masks(:);
bboxes = bboxes(:);
sizes = cellfun2(@(x)[x(4)-x(2)+1,x(3)-x(1)+1],bboxes);
sizes = cell2mat(sizes);
fixedBG = cellfun2(@(x)~x,masks);
images = cellfun2(@(x)double(x),images);

HC = cell(N,1);
VC = cell(N,1);
bgLogPL = cell(N,1);
fgLogPL = cell(N,1);

numelchange = zeros(N,maxIterations);

%%%%%%%%%%%%%%%%%%%%%
%%% Get definite labels defining absolute Background :
segs = fixedBG;
prevSegs = cellfun2(@(x)double(x),fixedBG);

%%%%%%%%%%%%%%%%%%%%%
%%% Calculate the smoothness term defined by the entire image's RGB values

%%% Get the image gradient
for i=1:N
    im = images{i};
    gradH = im(:,2:end,:) - im(:,1:end-1,:);
    gradV = im(2:end,:,:) - im(1:end-1,:,:);
    
    gradH = sum(gradH.^2, 3);
    gradV = sum(gradV.^2, 3);
    
    %%% Use the gradient to calculate the graph's inter-pixels weights
    hC = exp(-Beta.*gradH./mean(gradH(:)));
    vC = exp(-Beta.*gradV./mean(gradV(:)));
    
    %%% These matrices will evantually use as inputs to Bagon's code
    HC{i} = [hC zeros(size(hC,1),1)];
    VC{i} = [vC ;zeros(1, size(vC,2))];
end

sc = [0 G;G 0];

%%%%%%%%%%%%%%%%%%%%%
%%% Start the EM iterations :
bgMean = cell(N,1);
fgMean = cell(N,1);

BGMean = [];
FGMean = [];
BGCov = [];
FGCov = [];

canonicalsize = 200;
convergeds = false(1,N);
badones = false(1,N);
badsegs = false(1,N);
evalresset = zeros(1,N);

avgmasks = zeros(canonicalsize);

for iter=1:maxIterations
    
    conv = false;
    if any(~badsegs & convergeds)
        conv = true;
        avgmasks = zeros(canonicalsize);
        %%% Now it is transfer time, first compute the average masks, then do
        %%% the transfer to all the image
        for i=find(~badsegs & convergeds)
            pmask = segs{i}(bboxes{i}(2):bboxes{i}(4),bboxes{i}(1):bboxes{i}(3));
            pmask = imresize(pmask,[canonicalsize,canonicalsize]);
            avgmasks = avgmasks + double(pmask);
        end
        avgmasks = avgmasks / max(sum(~badsegs & convergeds),1);
    end
    
    disp(['Iteration:',int2str(iter)]);
    [BGLogPL FGLogPL BGMean FGMean BGCov FGCov] =  CalcLogGroups(images, KGroup, prevSegs, BGMean, FGMean );
    for i=1:N
        fprintf('%d ',i);
        if (~convergeds(i) && ~badones(i)) || iter == 1
            disp(length(find(prevSegs{i} == 1)));
            disp(length(find(prevSegs{i} == 0)));
            
            [bgLogPL{i} fgLogPL{i} bgMean{i} fgMean{i} ] =  CalcLogPLikelihood(images{i}, K, find(prevSegs{i} == 1),find(prevSegs{i} == 0), bgMean{i}, fgMean{i} );            
        end
        
        if ~conv || ~badsegs(i)
            [bg fg] = getUnary(bgLogPL{i},fgLogPL{i},BGLogPL{i},FGLogPL{i},alpha);
        else
            [bgloc,fgloc] = getULoc(avgmasks,bboxes{i},size(segs{i},1),size(segs{i},2));
            [bg fg] = getUnaryLoc(bgLogPL{i},fgLogPL{i},BGLogPL{i},FGLogPL{i},alpha,bgloc,fgloc);
        end
        
        fg(fixedBG{i}) = max(max(fg));

        %%% Now that we have all inputs, calculate the min-cut of the graph
        %%% using Bagon's code. Not much to explain here, for more details read
        %%% the graph cut documentation in the   GraphCut.m    file.
        dc = cat(3, bg, fg);
        graphHandle = GraphCut('open', dc , sc, VC{i}, HC{i});
        graphHandle = GraphCut('set', graphHandle, int32(prevSegs{i} == 0));
        [graphHandle segs{i}] = GraphCut('expand', graphHandle);
        segs{i} = 1 - segs{i};
        
        GraphCut('close', graphHandle);
    end
    
    if iter>0
        convergeds = false(1,N);
        badsegs = false(1,N);
        for i=1:N
            numelchange(i,iter) = nnz(segs{i}(:)~=prevSegs{i}(:)) / numel(segs{i});
            range = length(find(segs{i}(:)==1));
            disp(range);
            if  numelchange(i,iter) < diffThreshold
                convergeds(i) = true;
                fprintf('Iter:%03d  Image:%s(%04d) Converged...\n',iter,maskimages{i},i);
            end
            evalresset(i) = evalSegs(segs{i},bboxes{i});
            if evalresset(i) < 0.8 % threshold to see if all the boundaries are good
                badsegs(i) = true;
                fprintf('Iter:%03d  Image:%s(%04d) Converged to bad (%.5f)...\n',iter,maskimages{i},i,evalresset(i));
            end
            if range + K * 10 > numel(segs{i}) || range < K * 10
                badones(i) = true;
                badsegs(i) = true;
                fprintf('Iter:%03d  Image:%s(%04d) Converged to bad...\n',iter,maskimages{i},i);
            end
        end
        disp([sum(convergeds | badones),N]);
        disp(evalresset);
        %%% Break if current result is somewhat similar to previuos result
        if sum(~convergeds & ~badones) < N * convergeRate
            break;
        end
    end
    
    prevSegs = segs;     
end

segs = cellfun2(@(x)applyMorph(x < 0.5),segs);

end

function [bg,fg] = getULoc(avgmasks,bbox,h,w)
sizes1 = bbox(4) - bbox(2) + 1;
sizes2 = bbox(3) - bbox(1) + 1;
bg = ones(h,w);
fg = zeros(h,w);
bg(bbox(2):bbox(4),bbox(1):bbox(3)) = -log(imresize(avgmasks,[sizes1,sizes2]));
fg(bbox(2):bbox(4),bbox(1):bbox(3)) = -log(imresize(1-avgmasks,[sizes1,sizes2]));
% fg = -bg;
end

function [b,f] = getUnary(bl,fl,BL,FL,alpha)
b = bl + BL * alpha;
f = fl + FL * alpha;
end

function [b,f] = getUnaryLoc(bl,fl,BL,FL,alpha,bloc,floc)
b = bl + BL * alpha + bloc;
f = fl + FL * alpha + floc;
end

function [allBGLogPL allFGLogPL bgMean fgMean bgCovarianceMats fgCovarianceMats] =  CalcLogGroups(images, K, prevSegs, bgMeanInit, fgMeanInit )

imageValues = cellfun2(@(x)reshape(x,[],3),images);
sizes = cellfun2(@(x)size(x),images);
sizes = cell2mat(sizes);
sizes = sizes(:,1:2);
numels = prod(sizes,2);

clear images
imageValues = cell2mat(imageValues);

bgIds = cellfun2(@(x)x(:)==1,prevSegs);
bgIds = cell2mat(bgIds);
fgIds = cellfun2(@(x)x(:)==0,prevSegs);
fgIds = cell2mat(fgIds);

numPixels = length(fgIds);
numBGValues = sum(bgIds);
numFGValues = sum(fgIds);

allBGLogPL = zeros(numPixels,K);
allFGLogPL = zeros(numPixels,K);
bgValues = imageValues(bgIds,:);
fgValues = imageValues(fgIds,:);

clear bgIds fgIds

opts = statset('kmeans');
opts.MaxIter = 200;

if ( ~isempty(bgMeanInit) && ~isempty(fgMeanInit) )
    [bgClusterIds bgMean] = kmeans(bgValues, K, 'start', bgMeanInit,  'emptyaction','singleton' ,'Options',opts);
    [fgClusterIds fgMean] = kmeans(fgValues, K, 'start', fgMeanInit,  'emptyaction','singleton', 'Options',opts);
else
    [bgClusterIds bgMean] = kmeans(bgValues, K, 'emptyaction','singleton' ,'Options',opts);
    [fgClusterIds fgMean] = kmeans(fgValues, K, 'emptyaction','singleton', 'Options',opts);
end

checkSumFG = 0;
checkSumBG = 0;

bgCovarianceMats = cell(K,1);
fgCovarianceMats = cell(K,1);

for k=1:K
    %%% Get the k Gaussian weights for Background & Forground 
    bgGaussianWeight = nnz(bgClusterIds==k)/numBGValues;
    fgGaussianWeight = nnz(fgClusterIds==k)/numFGValues;
    checkSumBG = checkSumBG + bgGaussianWeight;
    checkSumFG = checkSumFG + fgGaussianWeight;

    %%% FOR ALL PIXELS - calculate the distance from the k gaussian (BG & FG)
    bgDist = imageValues - repmat(bgMean(k,:),size(imageValues,1),1);
    fgDist = imageValues - repmat(fgMean(k,:),size(imageValues,1),1);

    %%% Calculate the gaussian covariance matrix & use it to calculate
    %%% all of the pixels likelihood to it :
    bgCovarianceMat = cov(bgValues(bgClusterIds==k,:))+1e-5 * eye(3);
    fgCovarianceMat = cov(fgValues(fgClusterIds==k,:))+1e-5 * eye(3);
    bgCovarianceMats{k} = bgCovarianceMat;
    fgCovarianceMats{k} = fgCovarianceMat;
    
    allBGLogPL(:,k) = -log(bgGaussianWeight)+0.5*log(det(bgCovarianceMat)) + 0.5*sum( (bgDist/bgCovarianceMat).*bgDist, 2 );
    allFGLogPL(:,k) = -log(fgGaussianWeight)+0.5*log(det(fgCovarianceMat)) + 0.5*sum( (fgDist/fgCovarianceMat).*fgDist, 2 );
end

assert(abs(checkSumBG - 1) < 1e-6 && abs(checkSumFG - 1)  < 1e-6 );

allBGLogPL = mat2cell(min(allBGLogPL, [], 2),numels);
allFGLogPL = mat2cell(min(allFGLogPL, [], 2),numels);

for i=1:length(numels)
    allBGLogPL{i} = reshape(allBGLogPL{i},sizes(i,1),sizes(i,2));
    allFGLogPL{i} = reshape(allFGLogPL{i},sizes(i,1),sizes(i,2));
end

end

function [ bgLogPL fgLogPL bgMean fgMean bgCovarianceMats fgCovarianceMats ] = CalcLogPLikelihood(im, K, bgIds, fgIds, bgMeanInit, fgMeanInit )

numPixels = size(im,1) * size(im,2);
allBGLogPL = zeros(numPixels,K);
allFGLogPL = zeros(numPixels,K);

%%% Seperate color channels 
R = im(:,:,1);
G = im(:,:,2);
B = im(:,:,3);

%%% Prepare the color datasets according to the input labels 
imageValues = [R(:) G(:) B(:)];
bgValues = [R(bgIds)    G(bgIds)     B(bgIds)];
fgValues = [R(fgIds)    G(fgIds)     B(fgIds)];
numBGValues = size(bgValues,1);
numFGValues = size(fgValues,1);

%%%%%%
% Use a 'manual' way to calculate the GMM parameters, instead of using
% Matlab's gmdistribution.fit() function. This is due to better speed 
% results..
% Start with Kmeans centroids calculation :
opts = statset('kmeans');
opts.MaxIter = 200;

if ( ~isempty(bgMeanInit) && ~isempty(fgMeanInit) )
    [bgClusterIds bgMean] = kmeans(bgValues, K, 'start', bgMeanInit,  'emptyaction','singleton' ,'Options',opts);
    [fgClusterIds fgMean] = kmeans(fgValues, K, 'start', fgMeanInit,  'emptyaction','singleton', 'Options',opts);
else
    [bgClusterIds bgMean] = kmeans(bgValues, K, 'emptyaction','singleton' ,'Options',opts);
    [fgClusterIds fgMean] = kmeans(fgValues, K, 'emptyaction','singleton', 'Options',opts);
end

checkSumFG = 0;
checkSumBG = 0;

bgCovarianceMats = cell(K,1);
fgCovarianceMats = cell(K,1);

for k=1:K
    %%% Get the k Gaussian weights for Background & Forground 
    bgGaussianWeight = nnz(bgClusterIds==k)/numBGValues;
    fgGaussianWeight = nnz(fgClusterIds==k)/numFGValues;
    checkSumBG = checkSumBG + bgGaussianWeight;
    checkSumFG = checkSumFG + fgGaussianWeight;

    %%% FOR ALL PIXELS - calculate the distance from the k gaussian (BG & FG)
    bgDist = imageValues - repmat(bgMean(k,:),size(imageValues,1),1);
    fgDist = imageValues - repmat(fgMean(k,:),size(imageValues,1),1);

    %%% Calculate the gaussian covariance matrix & use it to calculate
    %%% all of the pixels likelihood to it :
    bgCovarianceMat = cov(bgValues(bgClusterIds==k,:));
    fgCovarianceMat = cov(fgValues(fgClusterIds==k,:));
    bgCovarianceMats{k} = bgCovarianceMat+1e-5 * eye(3);
    fgCovarianceMats{k} = fgCovarianceMat+1e-5 * eye(3);
    allBGLogPL(:,k) = -log(bgGaussianWeight)+0.5*log(det(bgCovarianceMat)) + 0.5*sum( (bgDist/bgCovarianceMat).*bgDist, 2 );
    allFGLogPL(:,k) = -log(fgGaussianWeight)+0.5*log(det(fgCovarianceMat)) + 0.5*sum( (fgDist/fgCovarianceMat).*fgDist, 2 );
end

assert(abs(checkSumBG - 1) < 1e-6 && abs(checkSumFG - 1)  < 1e-6 );

%%% Last, as seen in the GrabCut paper, take the minimum Log likelihood
%%% (    argmin(Dn)    )
bgLogPL = reshape(min(allBGLogPL, [], 2),size(im,1), size(im,2));
fgLogPL = reshape(min(allFGLogPL, [], 2),size(im,1), size(im,2));

end

function seg = applyMorph(seg)

oseg = seg;
try
    seg = imclose(seg,strel('disk',3));
    seg = imfill(seg,'holes');
    seg = bwmorph(seg,'open'); % remove thin regions
    [~,N] = bwlabel(seg); % select largest 8-connected region
    h = hist(seg(:),1:N);
    [~,i] = max(h);
    seg = seg==i;
catch ME
    disp(ME.message);
    seg = oseg;
    return;
end

end



