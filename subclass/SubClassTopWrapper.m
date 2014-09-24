function SubClassTopWrapper( iid, options )
% Wrapper function to get the top detections of ELDA detectors
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
        
        detpath = tclasspath;
        detfinished = [detpath,'Finished.flag'];
        matpath = [detpath,'tops.mat'];
        lockpath = [detpath,'tops.lock'];
        
        if fileExists(detfinished) && ~fileExists(matpath) && makeDirOrFail(lockpath)
            options.now = toc(start);
            detmodelpath = [detpath,'Models.mat'];
            detbboxpath = [detpath,'Bboxes.mat'];
            [ detectors, detectorimages, detectionimages, topNscores, topNsizes, topNresults ] = SubClassClusterTop( detmodelpath, detbboxpath, options );
            save(matpath, 'detectors', 'detectorimages', 'detectionimages', 'topNsizes', 'topNscores', 'topNresults');
            
            rmdir(lockpath);
            if toc(start) > options.timelimit
                error('Time limit!');
            end
        end
    end
end

end

