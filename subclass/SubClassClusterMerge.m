function [ idx, counts, clusters, detections, detectionimages, topNresults ] = SubClassClusterMerge( topfiles, options )
% Simple Merge-based Clustering, given the detector-detection bipartite
% graph
% -------------------------------------------------------------------------
% Unsupervised Object Discovery and Segmentation
% Xinlei Chen, 2014 [enderchen@cs.cmu.edu]
% Please email me if you find bugs, or have suggestions or questions
% -------------------------------------------------------------------------

if nargin < 2
    options = [];
end

ratioDK = 0.5;
if isfield(options,'ratioDK')
    ratioDK = options.ratioDK;
end

sizeDK = 70;
if isfield(options,'sizeDK')
    sizeDK = options.sizeDK;
end

overlap = .5;
if isfield(options,'overlapDouble')
    overlap = options.overlapDouble;
end

topN = 5;
if isfield(options,'topN')
    topN = options.topN;
end
disp(topN);

sizeThres = 10;
if isfield(options,'sizeThres')
    sizeThres = options.sizeThres;
end

maxIterMerge = 0.8;
if isfield(options,'maxIterMerge')
    maxIterMerge = options.maxIterMerge;
end

minIterMerge = 0.5;
if isfield(options,'minIterMerge')
    minIterMerge = options.minIterMerge;
end

maxSimiMerge = 0.6;
if isfield(options,'maxSimiMerge')
    maxSimiMerge = options.maxSimiMerge;
end

minSimiMerge = 0.2;
if isfield(options,'minSimiMerge')
    minSimiMerge = options.minSimiMerge;
end

load(topfiles,'detectors','topNscores','topNresults','detectionimages');
nDetectors = length(detectors);

% augment the detectors
for i=1:nDetectors
    st = size(topNresults{i},1);
    st = min(st,topN);
    topNscores(i) = mean(topNresults{i}(1:st,end-3));
    topNresults{i} = [topNresults{i}(1:st,:),(1:st)'];
end

%% this is the sorting part ...
[~,Index] = sort(topNscores,'descend');
nDetectors = min(nDetectors,sum(topNscores > 0)); % ELDA, most likely the top scores will be greater than 0
fprintf('Number of detectors kept: %d\n',nDetectors);

Index = Index(1:nDetectors);

detectors = detectors(Index,:);
topNscores = topNscores(Index);

% add the stuff
topNresults = topNresults(Index);
for i=1:nDetectors
    topNresults{i}(:,end-1) = i;
end

%% then starts the clustering step on the images
topNresultsMat = cell2mat(topNresults);
images = unique(topNresultsMat(:,end-2));
nImagesLeft = length(images); % Here the size has changed!!!!!
disp(['Number of selected images: ',int2str(nImagesLeft)]);

C = 0;
detections = cell(nImagesLeft,1);
scores = cell(nImagesLeft,1);

for i=1:nImagesLeft
    image = images(i);
    disp(['Now is image ', int2str(i), ': ', int2str(image)]);
    
    % get the detections and sort by size
    detects = topNresultsMat(topNresultsMat(:,end-2) == image,:);
    l = size(detects,1);
    fprintf('Number of detections for image %d (%d) : %d\n',i,image,l);
    sizes = (detects(:,3) - detects(:,1) + 1) .* (detects(:,4) - detects(:,2) + 1);
    [sizes,index] = sort(sizes,'descend');
    detects = detects(index,:); % x1, y1, x2, y2, score, size, image, detector, rank
    clear index
    
    if l >= 3
        % use NMS to link the detections of different detectors on the same
        % image
        [~,lidx] = NmsIdxIU([detects(:,1:4),sizes],overlap);
        llidx = unique(lidx);
        cc = 1;
        nlidx = lidx;
        for ll=llidx'
            nlidx(lidx==ll) = cc;
            cc = cc + 1;
        end
        lidx = nlidx;
        clear nlidx
    elseif l == 2
        lidx = 1:2;
        bj = detects(1,1:4);
        areaB = sizes(1);
        areaA = sizes(2);
        bk = detects(2,1:4);
        Left = max(bj(1),bk(1));
        Up = max(bj(2),bk(2));
        Right = min(bj(3),bk(3));
        Down = min(bj(4),bk(4));
        hI = Right-Left;
        vI = Down-Up;
        if hI > 0 && vI > 0
            areaI = (hI+1)*(vI+1);
            if areaI / (areaA + areaB - areaI) >= overlap
                lidx(2) = 1;
            end
        end
    elseif l == 1
        lidx = 1;
    end
    
    cidx = unique(lidx);
    c = length(cidx);
    fprintf('Number of clusters for image %d : %d/%d\n',i,c,l);
    cdetects = zeros(c,6); % x1, y1, x2, y2, siter, image
    cdetects(:,end) = image;
    cscores = zeros(l,4);

    for j=1:c
        ccidx = lidx == cidx(j);

        if sum(ccidx) == 1
            cdetects(j,1:4) = detects(ccidx,1:4);
        else
            % just get the median region
            cdetects(j,1:4) = [median(detects(ccidx,1:2)),median(detects(ccidx,3:4))];
        end
        cscores(ccidx,1) = detects(ccidx,end-1); % the detector index
        cscores(ccidx,2) = C + j; % the detection index
        cscores(ccidx,3) = detects(ccidx,5);
        cscores(ccidx,4) = detects(ccidx,end);
    end
    cdetects(:,1:4) = round(cdetects(:,1:4));
    C = C + c;
    detections{i} = cdetects;
    scores{i} = cscores;
end

A = cell2mat(scores); % first dim: det id, second dim: cluster id, third dim: score
B = sparse(A(:,2),A(:,1),1); % B is the binary matrix, so the row is detection, and the column is detector 
C = B; % C is the counting matrix, how many times each detection occur in each subcategory

% clean up data
[B,C] = probeClustering(B,C,maxIterMerge,minSimiMerge,sizeDK,ratioDK);

% find subcategories
[~,rows] = size(B);
idx = 1:rows;
disp('Clustering...');
iter = 0;
maxSim = 1.0;
maxIter = round(rows * minIterMerge);
while iter < maxIter || maxSim >= maxSimiMerge
    if (mod(iter,10) == 0)
        fprintf('Iteration: %d, Similarity %.4f\n',iter,full(maxSim));
    end
    cB = B' * B;
    sumB = max(sum(B,1),1);
    for i=1:rows
        cB(:,i) = cB(:,i) ./ sumB(:);
    end

    cB = cB - diag(diag(cB));
    [maxSim,ind] = max(cB(:));
    if (maxSim == 0)
        break;
    end
    [rind,cind] = ind2sub([rows,rows],ind);
    C(:,rind) = C(:,rind) + C(:,cind);
    B(:,rind) = C(:,rind) > 0;  % just get the matrix binary
    C(:,cind) = 0;
    B(:,cind) = 0;
    idx(cind) = rind;
    iter = iter + 1;
end

while 1
    count = 0;
    for i=1:rows
        if idx(idx(i)) ~= idx(i)
            count = count + 1;
            idx(i) = idx(idx(i));
        end
    end
    if count == 0
        break;
    end
end

B = double(full(C > 1));
sumB = full(sum(B,1));
c = 1;
for i=1:rows
    if sumB(i) < 1
        idx(idx == i) = 0;
    else
        idx(idx == i) = c;
        c = c + 1;
    end
end

B = B(:,sumB >= 1);
rows = size(B,2);

fprintf('Number of clusters discovered: %d\n',rows);
clusters = cell(rows,1);
for i=1:rows
    clusters{i} = find(B(:,i));
end

sizes = cellfun(@(x)length(x),clusters);
c = 1;
for i=1:rows
    if sizes(i) < sizeThres
        idx(idx == i) = 0;
    else
        idx(idx == i) = c;
        c = c + 1;
    end
end
clusters = clusters(sizes >= sizeThres);
fprintf('Number of clusters finally discovered: %d\n',c-1);

% still need to compute how many instances each detector contribute to each
% cluster
rows = length(idx);
counts = zeros(1,rows);
BB = sparse(A(:,2),A(:,1),1);
for i=1:rows
    if idx(i) > 0
        % find the cluster
        counts(i) = length(intersect(find(BB(:,i)),clusters{idx(i)}));
    end
end

end

% first do probe clustering to remove the noisy detectors
function [OB,OC,rinds,cinds] = probeClustering(B,C,maxIterMerge,minSimiMerge,sizeDK,ratioDK)

OB = B;
OC = C;

[~,rows] = size(B);
idx = 1:rows;
disp('Probe Clustering...');
iter = 0;
maxSim = 1.0;
maxIter = round(rows * maxIterMerge);
rinds = zeros(maxIter,1);
cinds = zeros(maxIter,1);
while iter < maxIter || maxSim >= minSimiMerge
    if (mod(iter,10) == 0)
        fprintf('Iteration: %d, Similarity %.4f\n',iter,full(maxSim));
    end
    cB = B' * B;
    sumB = max(sum(B,1),1);
    for i=1:rows
        cB(:,i) = cB(:,i) ./ sumB(:);
    end

    cB = cB - diag(diag(cB));
    [maxSim,ind] = max(cB(:));
    if (maxSim == 0)
        break;
    end
    [rind,cind] = ind2sub([rows,rows],ind);
    rinds(iter+1) = rind;
    cinds(iter+1) = cind;
    C(:,rind) = C(:,rind) + C(:,cind);
    B(:,rind) = C(:,rind) > 0;  % just get the matrix binary
    C(:,cind) = 0;
    B(:,cind) = 0;
    idx(cind) = rind;
    iter = iter + 1;
end

while 1
    count = 0;
    for i=1:rows
        if idx(idx(i)) ~= idx(i)
            count = count + 1;
            idx(i) = idx(idx(i));
        end
    end
    if count == 0
        break;
    end
end

BB = double(full(C > 1)); % multiple detector to verify
sumB = full(sum(BB,1));
c = 1;
for i=1:rows
    if sumB(i) < 1
        idx(idx == i) = 0;
    else
        idx(idx == i) = c;
        c = c + 1;
    end
end

BB = BB(:,sumB >= 1);
rows = size(BB,2);

clusters = cell(rows,1);
for i=1:rows
    clusters{i} = find(BB(:,i));
end

sizes = cellfun(@(x)length(x),clusters);
disp(sizes');
% calculate the threshold
ssizes = sort(sizes,'ascend');
asizes = cumsum(ssizes);
id = sum(asizes <= asizes(end) * (1-ratioDK));
% to make sure
if id == 0
    sizeThres =  0;
else
    sizeThres = min(ssizes(id),sizeDK);
end
disp(['Cluster Size Threshold Detected:',num2str(sizeThres)]);

c = 1;
for i=1:rows
    if sizes(i) <= sizeThres
        idx(idx == i) = 0;
    else
        idx(idx == i) = c;
        c = c + 1;
    end
end

% then take the index out to get indexes from the good detectors
OC(:,idx==0) = 0;
OB(:,idx==0) = 0;

end

