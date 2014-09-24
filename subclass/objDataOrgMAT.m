function [ pos, neg, impos ] = objDataOrgMAT( imagenames, detections, clusterind, cachedir, options )
% Get the data from the negative images pool, and the positive images. This
% is from latent SVM training
% -------------------------------------------------------------------------
% Unsupervised Object Discovery and Segmentation
% Xinlei Chen, 2014 [enderchen@cs.cmu.edu]
% Please email me if you find bugs, or have suggestions or questions
% -------------------------------------------------------------------------

if nargin < 5
    options = [];
end

bFlipPos = 1;
if isfield(options,'bFlipPos')
    bFlipPos = options.bFlipPos;
end

imSubDir = '/images';
if isfield(options,'imSubDir')
    imSubDir = options.imSubDir;
end

negPreDirSet = {'/i/dont/love/you','/i/hate/you'};
if isfield(options,'lsvmNegFolders')
    negPreDirSet = options.lsvmNegFolders;
end

lowerNeg = 3;
if isfield(options,'lowerNeg')
    lowerNeg = options.lowerNeg;
end

higherNeg = inf;
if isfield(options,'higherNeg')
    higherNeg = options.higherNeg;
end

dataPath = [cachedir,'/',options.trainPath];
try
    load(dataPath,'pos','neg','impos');
catch ME
    
    disp(ME.message);
    
    %% Load Positive Examples
    pos = [];
    impos = [];
    numpos = 0;
    numimpos = 0;
    dataid = 0;
    
    count = 0;
    
    lf = length(clusterind);
    
    for i=1:lf
        
        detid = clusterind(i);
        bbox = round(detections(detid,1:4));
        posimname = imagenames{detections(detid,end)};

        im = imread(posimname);
        sizeI = size(im);
        sizeI = sizeI(1:2);
        
        numpos = numpos+1;
        dataid = dataid + 1;
        pos(numpos).im = posimname;
        
        pos(numpos).x1 = bbox(1);
        pos(numpos).y1 = bbox(2);
        pos(numpos).x2 = bbox(3);
        pos(numpos).y2 = bbox(4);
        pos(numpos).boxes   = bbox;
        pos(numpos).flip = false;
        pos(numpos).trunc = 0;
        pos(numpos).dataids = dataid;
        pos(numpos).sizes = (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1);
        
        numimpos = numimpos + 1;
        dataid = dataid + 1;
        impos(numimpos).im      = posimname;
        impos(numimpos).boxes   = bbox;
        impos(numimpos).dataids = dataid;
        impos(numimpos).sizes   = (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1);
        impos(numimpos).flip    = false;
        
        if bFlipPos
            oldx1 = bbox(1);
            oldx2 = bbox(3);
            bbox(1) = sizeI(2) - oldx2 + 1;
            bbox(3) = sizeI(2) - oldx1 + 1;
            numpos = numpos+1;
            dataid = dataid + 1;
            pos(numpos).im = posimname;
            pos(numpos).x1 = bbox(1);
            pos(numpos).y1 = bbox(2);
            pos(numpos).x2 = bbox(3);
            pos(numpos).y2 = bbox(4);
            pos(numpos).boxes   = bbox;
            pos(numpos).flip = true;
            pos(numpos).trunc = 0;
            pos(numpos).dataids = dataid;
            pos(numpos).sizes   = (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1);
            
            numimpos = numimpos + 1;
            dataid = dataid + 1;
            impos(numimpos).im      = posimname;
            impos(numimpos).boxes   = bbox;
            impos(numimpos).dataids = dataid;
            impos(numimpos).sizes   = (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1);
            impos(numimpos).flip    = true;
        end
        
        count = count + 1;
        
    end
    disp(['Number of positive images (no flip):',int2str(count)]);
    %% Load Negative Examples
    neg = [];
    numneg = 0;
    for n = 1:length(negPreDirSet)
%     for negPreDir = negPreDirSet
        negPreDir = negPreDirSet{n};
        disp(negPreDir);
        negclses = dir(negPreDir);
        negbigL = length(negclses);
        disp(['Number of negative classes (aprox):',int2str(negbigL-2)]);
        
        for i=3:negbigL
            negPath = [negPreDir,negclses(i).name,imSubDir];           
            if ~exist(negPath,'dir')
                continue;
            else
                disp(negPath);
            end
            
            negimages = dir(negPath);
            negL = length(negimages);
            disp(['Number of images in this class (aprox):',int2str(negL-2)]);
            
            lower = max(lowerNeg,3);
            higher = min(higherNeg,negL);
            
            for j=lower:higher
                negimname = [negPath,'/',negimages(j).name];
                if isempty(strfind(negimname,'.jpg')) && isempty(strfind(negimname,'.JPEG'))
                    continue;
                else
                    numneg = numneg+1;
                    dataid = dataid + 1;
                    neg(numneg).im = negimname;
                    neg(numneg).flip = false;
                    neg(numneg).dataid = dataid;
                end
            end
        end
        
    end
    disp(['Number of pure negative images:',int2str(numneg)]);
    save(dataPath,'pos','neg','impos','-v7.3');
end

end

