function TransferClusteringWrapper(iid, options)
% Wrapper for the transfer based figure-ground segmentation
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
        makeDirOrFail(classres);
        
        pclasspath = [datasetcache,classname,'/gtpaths.mat'];
        if iid == 1
            try
                load(pclasspath,'imagelist');
            catch ME
                disp(ME.message);
                images = dir([classpath,'/GroundTruth/*.*']);
                images = images(3:end); % just get all the images
                images = cat(1,{images(:).name})';
                imagelist = strrep(images,'.png','.jpg');
                save(pclasspath,'imagelist');
            end
        else
            waitTillExists({pclasspath});
            load(pclasspath,'imagelist');
        end
        
        % Then do the transfer-based clustering
        clusterfile = [tclasspath,'clusters.mat'];
        dpmclusterfile = [tclasspath,'dpmclusters.mat'];
        modelfile = [tclasspath,'lsvm.mat'];
        cosegfolder = [tclasspath,'Co-Segment/Mat/'];
        
        TransferAll(clusterfile,modelfile,dpmclusterfile,cosegfolder,classres,classpath,imagelist,options);
        if toc(start) > options.timelimit
            error('Time limit!');
        end
    end    
end

end

