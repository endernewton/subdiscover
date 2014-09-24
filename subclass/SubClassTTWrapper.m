function SubClassTTWrapper( iid, options )
% Wrapper function to train an ELDA detector for every image, and fire it
% on all the images to get detection bounding boxes
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
        classpath = [datasetpath,classes(i).name,'/'];
        disp(classname);
        
        if strcmpi(options.initCandMeth,'full')
            tclasspath = [datasetcache,classname,'/detection/'];
        elseif strcmpi(options.initCandMeth,'sed')
            tclasspath = [datasetcache,classname,'/detectsed/'];
            disp('Structured Edge Detection...');
        end
        makeDirOrFail(tclasspath);
        pclasspath = [datasetcache,classname,'/paths.mat'];
        
        if iid == 1
            try
                load(pclasspath,'imagelist');
            catch ME
                disp(ME.message);
                images = dir([classpath,'*.*']);
                images = images(3:end); % just get all the images
                images = cat(1,{images(:).name})';
                imagelist = strcat(classpath,images);
                save(pclasspath,'imagelist');
            end
        else
            waitTillExists({pclasspath});
            load(pclasspath,'imagelist');
        end
        
        detpath = tclasspath;
        detfinished = [detpath,'Finished.flag'];
        lockpath = [detpath,'working.lock'];
        
        if iid == 1 && ~fileExists(detfinished) && makeDirOrFail(lockpath)
            options.now = toc(start);
            SubClassTT( iid, imagelist, detpath, options );
            rmdir(lockpath);
            
            if toc(start) > options.timelimit
                error('Time limit!');
            end
        elseif iid ~= 1 && ~fileExists(detfinished)
            options.now = toc(start);
            SubClassTT( iid, imagelist, detpath, options );
            
            if toc(start) > options.timelimit
                error('Time limit!');
            end
        end
    end
    
end

end

