function objTestWrapper(iid, options)
% Wrapper function for testing the Latent SVM
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
        
        pclasspath = [options.cachefolder,datasetname,'/',classname,'/paths.mat'];
        load(pclasspath,'imagelist');
        
        detpath = tclasspath;
        testdir = [detpath,'lsvm-test/'];
        makeDirOrFail(testdir);
        modelSetname = [detpath,'lsvm.mat'];
        boxSetname = [detpath,'lsvm-test.mat'];
        boxSetTar = [detpath,'lsvm-test.tar.gz'];
        
        if ~fileExists(modelSetname) || fileExists(boxSetname)
            continue;
        else
            clear models;
            load(modelSetname,'models');
            lf = length(models);
        end
        
        li = length(imagelist);
        boxnames = cell(li,1);
        for k=1:li
            [~,imagename,~] = fileparts(imagelist{k});
            disp(imagename);
            boxpath = [testdir,imagename,'.mat'];
            boxlock = [testdir,imagename,'.lock'];
            boxnames{k} = boxpath;
            
            if ~fileExists(boxpath) && makeDirOrFail(boxlock)
                objTester( models, boxpath, imagelist{k}, options );
                % sync issue, may work on the same image at the same time
                try
                    rmdir(boxlock);
                catch ME
                    disp(ME.message);
                end
                
                if toc(start) > options.timelimit
                    error('Time limit!');
                end
            end
        end
        
        if iid == 1
            boxSetlock = [detpath,'lsvm-test.lock'];
            if ~fileExists(boxSetname) && makeDirOrFail(boxSetlock)
                while ~waitTillExists(boxnames)
                    if toc(start) > options.timelimit
                        rmdir(boxSetlock);
                        error('Time limit!');
                    end
                end
                Bboxes = cell(lf,li);
                bar = createProgressBar();
                for k=1:li
                    bar(k,li);
                    clear bboxes
                    load(boxnames{k}, 'bboxes');
                    Bboxes(:,k) = bboxes;
                end
                save(boxSetname,'Bboxes','-v7.3');
                system(['tar -czvf ',boxSetTar,' ',testdir]);
                system(['rm -rvf ',testdir]);
                
                rmdir(boxSetlock);
            end
        end
    end
    
end

end
