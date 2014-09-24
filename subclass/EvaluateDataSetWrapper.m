function EvaluateDataSetWrapper(iid, options)
% Wrapper for evaluating figure-ground segmentation
% -------------------------------------------------------------------------
% Unsupervised Object Discovery and Segmentation
% Xinlei Chen, 2014 [enderchen@cs.cmu.edu]
% Please email me if you find bugs, or have suggestions or questions
% -------------------------------------------------------------------------

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
    datasetres = [options.resultfolder,datasets(d).name,'/']; % result folder
    makeDirOrFail(datasetres);
    
    classes = dir(datasetpath);
    classes = classes(3:end);
    
    for i=1:length(classes)
        if ~classes(i).isdir
            continue;
        end
        classname = classes(i).name;
        classpath = [datasetpath,classes(i).name,'/'];
        disp(classname);
        
        if strcmpi(options.initCandMeth,'full')
            tclasspath = [datasetcache,classname,'/detection/'];
        elseif strcmpi(options.initCandMeth,'sed')
            tclasspath = [datasetcache,classname,'/detectsed/'];
            disp('Structured Edge Detection...');
        end
        classres = [datasetres,classname,'/'];
        gtpath = [classpath,'/GroundTruth/'];
        
        if exist(classres,'dir')
            [P, J, nPositive, nNegative] = evaluateSegmentation(classres, gtpath);
            fprintf('%s in %s: P %.4f J %.4f\n',classname,datasetname,P,J);
            save([tclasspath,'eval.mat'],'P', 'J', 'nPositive', 'nNegative');
        end
    end    
end

end

