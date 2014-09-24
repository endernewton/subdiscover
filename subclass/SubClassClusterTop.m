function [ detectors, detectorimages, detectionimages, topNscores, topNsizes, topNresults ] = SubClassClusterTop( modelfile, bboxfile, options )
% The function that finds the top detections for each ELDA detector
% -------------------------------------------------------------------------
% Unsupervised Object Discovery and Segmentation
% Xinlei Chen, 2014 [enderchen@cs.cmu.edu]
% Please email me if you find bugs, or have suggestions or questions
% -------------------------------------------------------------------------

if nargin < 3
    options = [];
end

topN = 6;
if isfield(options,'topN')
    topN = options.topN;
end

ratioS = .5;
if isfield(options,'ratioS')
    ratioS = options.ratioS;
end

ratioDK = 0.5;
if isfield(options,'ratioDK')
    ratioDK = options.ratioDK;
end

%% retrieve all the top detections for every model
try
    load(modelfile,'models','posimgs','testimgs');
catch ME
    disp(ME.message);
    error('No model file found!');
end

nDetectors = length(models);
fprintf('Number of detectors : %d\n',nDetectors);
keptDetectors = round(ratioDK*nDetectors);

detectors = zeros(nDetectors,6);
detectorimages = cell(nDetectors,1);

for i=1:nDetectors
    detectorimages{i} = posimgs(i).im;
    detectors(i,:) = [posimgs(i).x1,posimgs(i).y1,posimgs(i).x2,posimgs(i).y2,(posimgs(i).x2 - posimgs(i).x1 + 1)*(posimgs(i).y2 - posimgs(i).y1 + 1),0];
end
[detectorimages,~,detectors(:,6)] = unique(detectorimages);

try
    load(bboxfile,'bboxes');
catch ME
    disp(ME.message);
    error('No bounding box file found!');
end
nImages = size(bboxes,2);
fprintf('Number of images for test : %d\n',nImages);

detectionimages = cell(nImages,1);
for i=1:nImages
    detectionimages{i} = testimgs(i).im;
    testimgs(i).width = testimgs(i).x2 - testimgs(i).x1 + 1;
    testimgs(i).height = testimgs(i).y2 - testimgs(i).y1 + 1;
end

topNresults = cell(nDetectors,1);
topNscores = zeros(nDetectors,1);
topNsizes = zeros(nDetectors,1);

for i=1:nDetectors
    boxes = bboxes(i,:)';
    allIndexes = cell(nImages,1);
    
    ii = find(strcmp(detectionimages,detectorimages{detectors(i,6)}));
    Tindex = 1:nImages;
    
    for j=Tindex
        now = boxes{j};
        if ~isempty(now)
            now(:,5) = now(:,end);
            now = now(:,1:5);
            now(:,1:4) = round(now(:,1:4));
            now(:,1:2) = max(now(:,1:2),1);
            now(:,3) = min(now(:,3),testimgs(j).width);
            now(:,4) = min(now(:,4),testimgs(j).height);
            wr = (now(:,3) - now(:,1) + 1) / testimgs(j).width;
            hr = (now(:,4) - now(:,2) + 1) / testimgs(j).height;
            r = sqrt(wr .* hr);
            [pick,now] = Nms(now(max(wr,hr)>=ratioS,:),.5);
            boxes{j} = [now,r(pick)];
            allIndexes{j} = ones(length(pick),1) * j;
            if j == ii && ~isempty(now) % just keep one on itself
                [~,idx] = max(now(:,end));
                wr = (now(idx,3) - now(idx,1) + 1) / testimgs(j).width;
                hr = (now(idx,4) - now(idx,2) + 1) / testimgs(j).height;
                r = sqrt(wr * hr);
                boxes{j} = [now(idx,:),r];
                allIndexes{j} = j;
            end
        end
    end
    
    allThings = cell2mat(boxes);
    allIndexes = cell2mat(allIndexes);
    l = size(allThings,1);
    fprintf('Number of detections for detector %d : %d\n',i,l);
    m = min(l,topN);
    if m == topN % if does not have enough detections, the topNscores will remain 0, which is removed afterwards
        allScores = allThings(:,end-1);
        [~,index] = sort(allScores,'descend');
        index = index(1:m);
        topNscores(i) = mean(allScores(index));
        topNsizes(i) = mean(allThings(index,end));
        topNresults{i} = [allThings(index,:),allIndexes(index),ones(m,1) * i];
    end
end

[~,Index] = sort(topNscores,'descend');
keptDetectors = min(keptDetectors,sum(topNscores > 0)); % remove the ones
fprintf('Number of detectors kept : %d\n',keptDetectors);
Index = Index(1:keptDetectors);

detectors = detectors(Index,:);
topNscores = topNscores(Index);
topNsizes = topNsizes(Index);
topNresults = topNresults(Index);
for i=1:keptDetectors
    topNresults{i}(:,end) = i;
end

end

