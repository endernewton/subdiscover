function objTrainWrapperMAT(iid, options)
% train SVM detectors for clusters.mat, which is discovered by merging the
% ELDA top detections
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
        clusterfile = [detpath,'clusters.mat'];
        modeldir = [detpath,'lsvm/'];
        
        if ~fileExists(clusterfile)
            disp('Cannot find files!');
            continue;
        else
            makeDirOrFail(modeldir);
            
            try
                clear detections detectionimages clusters
                load(clusterfile,'detections','detectionimages','clusters');
            catch ME
                disp(ME.message);
                continue;
            end
            
            if ~exist('detections','var') || ~exist('clusters','var') || ~exist('detectionimages','var')
                disp('Cannot find files!');
                continue;
            else
                detections = cell2mat(detections);
            end
            
            lf = length(clusters);
            modelnames = cell(lf,1);
            
            for k=1:lf
                modelname = [modeldir,sprintf('%03d_model.mat',k)];
                disp(modelname);
                modelnames{k} = modelname;
                modellock = [modeldir,sprintf('%03d_model.lock',k)];
                modellog = [modeldir,sprintf('%03d_model.log',k)];
                if ~fileExists(modelname) && makeDirOrFail(modellog)
                    disp(modellock);
                    makeDirOrFail(modellock);
                    options.now = toc(start);
                    objTrainerMAT(classname, modelname, modellock, modellog, detectionimages, detections, clusters{k}, options);
                    system(['rm -rvf ',modellock,' ',modellog]);
                end
                
                if toc(start) > options.timelimit
                    error('Time limit!');
                end
                
            end
            
            if iid == 1
                modelSetname = [detpath,'lsvm.mat'];
                modelSetlock = [detpath,'lsvm.lock'];
                if ~fileExists(modelSetname) && makeDirOrFail(modelSetlock)
                    while ~waitTillExists(modelnames)
                        if toc(start) > options.timelimit
                            rmdir(modelSetlock);
                            error('Time limit!');
                        end
                    end
                    models = cell(lf,1);
                    for k=1:lf
                        clear model
                        load(modelnames{k}, 'model');
                        models{k} = model;
                    end
                    save(modelSetname,'models');
                    rmdir(modelSetlock);
                end
            end
            
            if toc(start) > options.timelimit
                error('Time limit!');
            end
            
        end
        
        if toc(start) > options.timelimit
            error('Time limit!');
        end
            
    end
end

end
