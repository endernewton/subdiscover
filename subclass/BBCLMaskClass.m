function BBCLMaskClass(iid,options)
% Wrapper function to get the priors for each tight clusters, using a joint
% segmentation algorithm
% -------------------------------------------------------------------------
% Unsupervised Object Discovery and Segmentation
% Xinlei Chen, 2014 [enderchen@cs.cmu.edu]
% Please email me if you find bugs, or have suggestions or questions
% -------------------------------------------------------------------------

start = tic;
pause(mod(iid,5) + 1);

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
    
    classes = dir(datasetpath);
    classes = classes(3:end);
    
    for c=1:length(classes)
        if ~classes(c).isdir
            continue;
        end
        classname = classes(c).name;
        disp(classname);
        
        if strcmpi(options.initCandMeth,'full')
            tclasspath = [datasetcache,classname,'/detection/'];
        elseif strcmpi(options.initCandMeth,'sed')
            tclasspath = [datasetcache,classname,'/detectsed/'];
            disp('Structured Edge Detection...');
        end
        
        outputfolder = [tclasspath,'Co-Segment/Mat/'];
        outputfolderimg = [tclasspath,'Co-Segment/Img/'];
        
        makeDirOrFail(outputfolder);
        makeDirOrFail(outputfolderimg);
        
        matpath = [tclasspath,'clusters.mat'];
        if ~fileExists(matpath)
            continue;
        else
            load(matpath,'topNresults','detectionimages');
        end
        nDetectors = length(topNresults);
        
        % then get the masks
        for i=1:nDetectors
            detects = topNresults{i};
            outputpath = [outputfolder,sprintf('detector_%03d.mat',i)];
            outputlock = [outputfolder,sprintf('detector_%03d.lock',i)];
            outimagepath = [outputfolderimg,sprintf('detector_%03d.png',i)];
            
            if fileExists(outputpath) || ~makeDirOrFail(outputlock)
                continue;
            end
            disp(outputpath);
            disp(outimagepath);
            
            li = size(detects,1);
            
            imgs = cell(li,1);
            masks = cell(li,1);
            maskimages = cell(li,1);
            for j=1:li
                jt = detects(j,end-2);
                impatho = detectionimages{jt};
                disp(impatho);
                
                im = color(imread(impatho));
                imgs{j} = im;
                
                [h,w,~] = size(im);
                
                x1 = max(1,detects(j,1));
                y1 = max(1,detects(j,2));
                x2 = min(w,detects(j,3));
                y2 = min(h,detects(j,4));
                
                mask = false(h,w);
                mask(y1:y2,x1:x2) = true;
                
                % just to avoid the case where the entire images are set to
                % be foreground, so it becomes impossible to model the
                % background
                if sum(mask(:)) >= h*w - 50
                    detects(j,1:4) = RefineBbxSED(im,detects(j,1:4),options);
                    
                    x1 = detects(j,1);
                    y1 = detects(j,2);
                    x2 = detects(j,3);
                    y2 = detects(j,4);
                    
                    mask = false(h,w);
                    mask(y1:y2,x1:x2) = true;
                end
                
                masks{j} = mask;
            end
            
            options.maskimages = maskimages;
            [masks,numelchange,evalresset,avgmasks,BGMean,FGMean,BGCov,FGCov] = GCAlgoTransferNB(imgs,masks,mat2cell(detects(:,1:4),ones(li,1),4),options);
            
            imwrite(avgmasks,outimagepath);
            save(outputpath,'masks','numelchange','evalresset','avgmasks','BGMean','FGMean','BGCov','FGCov');
            
            try
                rmdir(outputlock);
            catch ME
                disp(ME.message);
            end
            
            if toc(start) > options.timelimit
                error('Time limit!');
            end
        end
        
    end
end

end

