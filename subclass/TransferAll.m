function TransferAll(clusterfile,modelfile,dpmclusterfile,cosegfolder,classres,classpath,imagenames,options)
% Transfer based figure-ground segmentation, if not found, back out to
% natural prior.
% -------------------------------------------------------------------------
% Unsupervised Object Discovery and Segmentation
% Xinlei Chen, 2014 [enderchen@cs.cmu.edu]
% Please email me if you find bugs, or have suggestions or questions
% -------------------------------------------------------------------------
persistent soft_mask;

locationfile = [options.cachefolder,'prior.mat'];
if isfield(options,'generalpriorfile')
    locationfile = options.generalpriorfile;
end

if isempty(soft_mask)
    load(locationfile,'soft_mask');
end

overlap = 0.5;
if isfield(options,'overlapDet')
    overlap = options.overlapDet;
end

ratio = 0.7;
if isfield(options,'ratioMax')
    ratio = options.ratioMax;
end

cansize = 200;
if isfield(options,'canSize')
    cansize = options.canSize;
end

badSegRate = 0.4;
if isfield(options,'badSegRate')
    badSegRate = options.badSegRate;
end

backGroundRate = 0.2;
if isfield(options,'backGroundRate')
    backGroundRate = options.backGroundRate;
end

nTops = 1;
if isfield(options,'nTopsDet')
    nTops = options.nTopsDet;
end

ratioThres = 1000;
if isfield(options,'ratioThres')
    ratioThres = options.ratioThres;
end

dumpImages = 0;
if isfield(options,'dumpTempImages')
    dumpImages = options.dumpTempImages;
end

if dumpImages == 1
    transferedfolder = [classres,'/Tr/'];
    makeDirOrFail(transferedfolder);
end

load(clusterfile,'idx','ratiosizes');
load(dpmclusterfile,'clusters','detections','detectionimages','leftright');
load(modelfile,'models');
selected = ratiosizes < ratioThres; % get rid of clusters that fire everywhere
ncls = length(models);
clsLabel = 1:ncls;
clear models
clusters = clusters(selected);
clsLabel = clsLabel(selected);

detections = cell2mat(detections);
leftright = cell2mat(leftright);

li = length(imagenames);
lc = length(clusters);

% reverse index the cluster id, given the detection match
clustersids = cell(lc,1);
for i=1:lc
    clustersids{i} = ones(length(clusters{i}),1) * i;
end

clusterindex = cell2mat(clusters);
detections = detections(clusterindex,:);
leftright = leftright(clusterindex,:);
clustersids = cell2mat(clustersids);

for i=1:li
    outputimage = [classres,strrep(imagenames{i},'.jpg','.png')];
    outputlock = [classres,strrep(imagenames{i},'.jpg','.lock')];
    
    if fileExists(outputimage) || ~makeDirOrFail(outputlock)
        continue;
    end
    
    disp(outputimage);
    imagename = [classpath,imagenames{i}]; % get the image name
    im = color(imread(imagename)); % get the image
    [h,w,~] = size(im); % size
    [~,imnamepart,~] = fileparts(imagename);
    
    mask = zeros(h,w);
    inddet = find(strcmp(imagename,detectionimages)); % compare the testing image
    if isempty(inddet)
        % so no detection is found, output blank image
        imwrite(mask,outputimage);
    else
        index = detections(:,end) == inddet;
        
        ids = clustersids(index); % get the cluster id
        detects = detections(index,:);
        leftr = leftright(index,:);
        
        [pick,lidx] = NmsIdx(detects(:,1:5),overlap);
        
        ld = size(pick,1);
        detnum = zeros(1,ld);
        for j=1:ld
            detnum(j) = sum(lidx==pick(j));
        end
        
        disp(detnum);
        
        mid = detnum >= max(ratio * max(detnum),1) & detnum > 1; % the first set
        if sum(mid) == 0
            mid = false(ld,1);
            mid(1:nTops) = true;
        end
        
        for j=1:ld % the number of picked ones
            
            % not selected
            if mid(j) == 0
                continue;
            end
            
            thisPick = lidx==pick(j);
            
            thisIds = ids(thisPick);
            thisDetects = detects(thisPick,:);
            thisLR = leftr(thisPick);
            
            % find the largest region
            [~,ind] = sort(thisDetects(:,5),'descend');
            ind = ind(1:nTops); % first one
            thisIds = thisIds(ind);
            thisDetects = thisDetects(ind,:);
            thisLR = thisLR(ind);
            
            ltd = length(ind);
            tmask = ones(h,w);
            tcount = 0;
            
            for thisj=1:ltd
                bbox = thisDetects(thisj,:);
                id = thisIds(thisj); % get the original cluster label
                lr = thisLR(thisj);

                disp(id);

                H = zeros(cansize);

                if dumpImages == 1
                    imwrite(im(bbox(2):bbox(4),bbox(1):bbox(3),:),[transferedfolder,imnamepart,sprintf('_%03d_%03d_det',j,thisj),'.png']);
                end

                middetector = find(idx == clsLabel(id));
                count = length(middetector);
                amasks = cell(count,1);
                mys = zeros(count,1);

                c = 1;
                for k=middetector
                    load([cosegfolder,sprintf('detector_%03d',k),'.mat'],'avgmasks');

                    % all the things are background??
                    if sum(avgmasks(:) >= 0.5) < cansize^2 * backGroundRate % the entire thing is foreground
                        continue;
                    end

                    avgmasks = 1 - avgmasks;
                    mys(c) = round(sum(sum(avgmasks,2)/cansize .* (1:cansize)') / (cansize + 1) * 2);
                    amasks{c} = avgmasks;
                    c = c + 1;
                end

                count = c - 1;
                mys = mys(1:count);
                amasks = amasks(1:count);
                mysm = round(mean(mys));
                diff = mys - mysm;

                for k=1:count
                    H = H + circshift(amasks{k},[-diff(k),0]);
                end

                x1 = bbox(1);
                y1 = bbox(2);
                x2 = bbox(3);
                y2 = bbox(4);

                if count == 0
                    bbox = round(RefineBbxSED(im,bbox,options));

                    x1 = bbox(1);
                    y1 = bbox(2);
                    x2 = bbox(3);
                    y2 = bbox(4);

                    hb = y2 - y1 + 1;
                    wb = x2 - x1 + 1;

                    H = imresize(soft_mask,[hb,wb]);
                    dmask = min(H(:)) * ones(h,w);

                    dmask(y1:y2,x1:x2) = H;
                    dmask = max(min(dmask,1),0);
                else
                    hb = y2 - y1 + 1;
                    wb = x2 - x1 + 1;

                    H = H / count; % now nothing is lost, so

                    if lr == 0
                        H = fliplr(H);
                    end
                    
                    if dumpImages == 1
                        imwrite(H,[transferedfolder,imnamepart,sprintf('_%03d_%03d_avg',j,thisj),'.png']);
                        imwrite(H >= options.maskThres,[transferedfolder,imnamepart,sprintf('_%03d_%03d_input',j,thisj),'.png']);
                    end

                    dmask = min(H(:)) * ones(h,w);
                    dmask(y1:y2,x1:x2) = imresize(H,[hb,wb]);

                    dmask = max(min(dmask,1),0); % threshold it
                end
                
                dmask = SegmentLoc(im,dmask,options);

                rate = evalSegs(dmask,bbox);
                brate = evalSegArea(dmask,bbox);s
                disp(rate);

                if rate > badSegRate
                    continue;
                end

                if dumpImages == 1
                    imwrite(dmask,[transferedfolder,imnamepart,sprintf('_%03d_%03d_final_%.3f_%.3f',j,thisj,rate,brate),'.png']);
                end
                
                tmask = tmask & dmask;
                tcount = tcount + 1;
            end
            
            if tcount > 0
                mask = mask | tmask;
            end
        end
        
        imwrite(mask,outputimage);
    end
    system(['rm -rf ',outputlock]);
end

end


