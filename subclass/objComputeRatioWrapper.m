function objComputeRatioWrapper(iid, options)
% Compute the Ratio between the detection cluster and the cluster used for
% training
% -------------------------------------------------------------------------
% Unsupervised Object Discovery and Segmentation
% Xinlei Chen, 2014 [enderchen@cs.cmu.edu]
% Please email me if you find bugs, or have suggestions or questions
% -------------------------------------------------------------------------

pause(mod(iid,5) + 1);

offset = -0.4;
if isfield(options,'offsetRat')
    offset = options.offsetRat;
end

disp(offset);

datasets = dir(options.datafolder);
datasets = datasets(3:end);

for d=1:length(datasets)
    if ~datasets(d).isdir
        continue;
    end
    
    datasetname = datasets(d).name;
    disp(datasetname);
    datasetpath = [options.datafolder,datasets(d).name,'/'];
    datasetcache = [options.cachefolder,datasets(d).name,'/'];
    makeDirOrFail(datasetcache);
    
    classes = dir(datasetpath);
    classes = classes(3:end);
    
    for i=1:length(classes)
        if ~classes(i).isdir
            continue;
        end
        classname = classes(i).name;
        disp(classname);
        
        if strcmpi(options.initCandMeth,'full')
            tclasspath = [datasetcache,classname,'/detection/'];
        elseif strcmpi(options.initCandMeth,'sed')
            tclasspath = [datasetcache,classname,'/detectsed/'];
            disp('Structured Edge Detection...');
        end
        
        pclasspath = [options.cachefolder,datasetname,'/',classname,'/paths.mat'];
        load(pclasspath,'imagelist');
        
        detectionimages = imagelist;
        
        detpath = tclasspath;
        modelSetname = [detpath,'lsvm.mat'];
        boxSetname = [detpath,'lsvm-test.mat'];
        
        rationame = [detpath,'ratios.mat'];
        clusterfile = [detpath,'clusters.mat'];
        
        if ~fileExists(modelSetname) || ~fileExists(boxSetname) || fileExists(rationame)
            continue;
        else
            clear models
            disp('Loading models...');
            load(modelSetname,'models');
            threshes = cellfun(@(x)x.thresh,models);
            disp(threshes');
            clear clusters
            load(clusterfile,'clusters');
            orgsizes = cellfun(@(x)length(x),clusters);
            threshes = threshes + offset;
            clear Bboxes
            disp('Loading bboxes...');
            load(boxSetname,'Bboxes');
        end
        
        nimg = length(detectionimages);
        ncls = length(threshes);
        
        clusters = cell(ncls,1);
        detections = cell(ncls,1);
        leftright = cell(ncls,1);
        
        C = 1;
        bar = createProgressBar();
        for k=1:ncls
            bar(k,ncls);
            bboxes = Bboxes(k,:)';
            for p=1:nimg
                if ~isempty(bboxes{p})
                    bboxes{p} = [bboxes{p},p*ones(size(bboxes{p},1),1)];
                end
            end
            bboxes = cell2mat(bboxes);
            if ~isempty(bboxes)
                bboxes = bboxes(bboxes(:,end-1) >= threshes(k),:); % thresh
                scores = bboxes(:,end-1);
                [~,index] = sort(scores,'descend');
                bboxes = bboxes(index,:);
                detections{k} = [round(bboxes(:,1:4)),bboxes(:,6:7)]; % except the left right flipping
                leftright{k} = bboxes(:,5); % left right flipping
                c = size(bboxes,1);
                clusters{k} = (C:(C+c-1))';
                C = C + c;
            end
        end
        
        detsizes = cellfun(@(x)length(x),clusters);
        ratiosizes = detsizes ./ max(orgsizes,1);
        [cvalues,cindeces] = sort(ratiosizes','descend');
        disp(cvalues);
        disp(cindeces);
        save(rationame,'ratiosizes','detsizes','cvalues','cindeces');
        save(clusterfile,'ratiosizes','-append');
    end
    
end

end
