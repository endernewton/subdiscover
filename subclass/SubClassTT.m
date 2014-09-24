function SubClassTT( iid, imagelist, targetdir, options )
% The function that does training and testing of ELDA
% -------------------------------------------------------------------------
% Unsupervised Object Discovery and Segmentation
% Xinlei Chen, 2014 [enderchen@cs.cmu.edu]
% Please email me if you find bugs, or have suggestions or questions
% -------------------------------------------------------------------------

start = tic;

makeDirOrFail(targetdir);
cachebg = [targetdir,'Corr.mat'];

%% background images
if iid == 1
    try
        load (cachebg,'bg');
    catch ME
        disp(ME.message);
        load(options.eldafile,'bg');
        save(cachebg,'bg');
    end
else
    while ~waitTillExists({cachebg})
    end
    pause(3);
    load(cachebg,'bg');
end

signalmodelfile = [targetdir,'Models.flag'];
trainedTag = [targetdir,'Trained.flag'];
cachemodel = [targetdir,'Models/'];
makeDirOrFail(cachemodel);

%% training and testing images
if iid == 1
    try
        load([targetdir,'Models.mat'],'models','testimgs','count');
    catch ME
        disp(ME.message);
        
        fprintf('Creating files for training and testing...\n');
        
        if ~fileExists([targetdir,'TrainInfo.mat'])
            makeDirOrFail([targetdir,'Filenames/']);
            pBar = createProgressBar();
            count = length(imagelist);
            testimgs = repmat(struct('im','','y1',0,'y2',0,'x1',0,'x2',0),count,1);
            posimgs = testimgs;
            for i=1:count
                pBar(i,count);
                testimgs(i).im = imagelist{i};
                im = color(imread(imagelist{i}));
                sizeI = size(im);
                
                testimgs(i).x1 = 1;
                testimgs(i).y1 = 1;
                testimgs(i).x2 = sizeI(2);
                testimgs(i).y2 = sizeI(1);
                
                filename = [targetdir,'Filenames/',int2str(i),'.mat'];
                
                if fileExists(filename)
                    clear bb
                    % needs to give cluster the time to sync, try until the
                    % sync is done
                    flag = 1;
                    while flag == 1
                        try
                            load(filename,'bb');
                            flag = 0;
                        catch ME
                            disp(ME.message);
                            pause(1); % wait 1s and load again
                        end
                    end
                    posimgs(i) = testimgs(i);
                    posimgs(i).x1 = bb(1);
                    posimgs(i).y1 = bb(2);
                    posimgs(i).x2 = bb(3);
                    posimgs(i).y2 = bb(4);
                else
                    if strcmpi(options.initCandMeth,'full')
                        posimgs(i) = testimgs(i);
                    elseif strcmpi(options.initCandMeth,'sed')
                        posimgs(i) = testimgs(i);
                        bb = [1,1,sizeI(2),sizeI(1)];
                        bb = RefineBbxSED(im,bb,options);
                        posimgs(i).x1 = bb(1);
                        posimgs(i).y1 = bb(2);
                        posimgs(i).x2 = bb(3);
                        posimgs(i).y2 = bb(4);
                    end
                end
            end
            
            save([targetdir,'TrainInfo.mat'],'testimgs','posimgs','count','-v7.3');
            pause(5);
            system(['rm -rvf ',targetdir,'Filenames']);
        else
            load([targetdir,'TrainInfo.mat'],'testimgs','posimgs','count');
        end
        
        modelnames = cell(count,1);
        for j=1:count
            modelname = sprintf('%06d_model',j);
            modelnames{j} = [cachemodel,modelname,'.mat'];
            modellock = [cachemodel,modelname,'.lock'];
            if ~fileExists(modelnames{j}) && makeDirOrFail(modellock)
                disp(['Training for model:',int2str(j)]);
                pos = posimgs(j);
                
                model = eldaLearnDataset(pos, [], modelname, cachebg, options.eldaFeat, options); % should add some more things
                model.cachebg = cachebg;
                model.imname = pos.im;
                
                save(modelnames{j},'model');
                try
                    rmdir(modellock);
                catch ME
                    disp(ME.message);
                end
            end
        end
        
        models = cell(count,1);
        while ~waitTillExists(modelnames)
            now = toc(start);
            if now + options.now > options.timelimit
                return;
            end
        end
        
        system(['touch ',signalmodelfile]);
        
        for j=1:count
            clear model
            load(modelnames{j},'model');
            models{j} = model;
        end
        
        save([targetdir,'Models.mat'],'models','testimgs','posimgs','count','-v7.3');
        system(['tar -czvf ',targetdir,'Model.tar.gz ',cachemodel]);
        system(['rm -rvf ',cachemodel]);
        system(['rm -v ',signalmodelfile]);
        system(['touch ',trainedTag]);
    end
else
    try
        load([targetdir,'Models.mat'],'models','testimgs','count');
    catch ME
        disp(ME.message);
        
        if ~fileExists([targetdir,'TrainInfo.mat'])
            makeDirOrFail([targetdir,'Filenames/']);
            count = length(imagelist);
            for i=randperm(count)
                im = color(imread(imagelist{i}));
                sizeI = size(im);
                
                filename = [targetdir,'Filenames/',int2str(i),'.mat'];
                lockname = [targetdir,'Filenames/',int2str(i),'.lock'];
                
                if ~fileExists(filename) && makeDirOrFail(lockname)
                    bb = [1,1,sizeI(2),sizeI(1)];
                    if strcmpi(options.initCandMeth,'full')
                    elseif strcmpi(options.initCandMeth,'sed')
                        bb = RefineBbxSED(im,bb,options);
                    end
                    save(filename,'bb');
                    try
                        rmdir(lockname);
                    catch ME
                        disp(ME.message);
                    end
                end
            end
        end
        
        while ~waitTillExists({[targetdir,'TrainInfo.mat']})
        end
        load([targetdir,'TrainInfo.mat'],'testimgs','posimgs','count');
        
        for j=randperm(count)
            modelname = sprintf('%06d_model',j);
            modelpath = [cachemodel,modelname,'.mat'];
            modellock = [cachemodel,modelname,'.lock'];
            if ~fileExists(signalmodelfile) && ~fileExists(modelpath) && makeDirOrFail(modellock)
                disp(['Training for model:',int2str(j)]);
                pos = posimgs(j);
                
                model = eldaLearnDataset(pos, [], modelname, cachebg, options.eldaFeat, options); % should add some more things
                model.cachebg = cachebg;
                model.imname = pos.im;
                
                save(modelpath,'model');
                try
                    rmdir(modellock);
                catch ME
                    disp(ME.message);
                end
            end
        end
        while ~waitTillExists({trainedTag})
        end
        load([targetdir,'Models.mat'],'models','testimgs','count');
    end
end

select = randperm(count);
if iid == 1
    bboxnames = cell(count,1);
end

cachebox = [targetdir,'Bboxes/'];
signalboxfile = [targetdir,'Bboxes.flag'];
makeDirOrFail(cachebox);
[~,target,~] = fileparts(targetdir(1:end-1));
disp(target);

for c=select
    bboxname = sprintf('%06d_bbox',c);
    
    if iid == 1
        bboxnames{c} = [cachebox,bboxname,'.mat'];
    end
    
    lockname = sprintf('%06d.lock',c);
    if ~fileExists(signalboxfile) && ~fileExists([cachebox,bboxname,'.mat']) && makeDirOrFail([cachebox,lockname])
        iters = ceil(count / options.maxModelsOnes);
        boxes = cell(iters,1);
        for i=1:iters
            startIter = (i - 1) * options.maxModelsOnes + 1;
            endIter = min(count, startIter + options.maxModelsOnes - 1);
            disp([startIter,endIter]);
            boxes{i}=eldaDetectDatasetBSim(testimgs(c), models(startIter:endIter), [target,'-',int2str(c)], options.eldaFeat, options);
        end
        boxes = cat(1,boxes{:});
        save([cachebox,bboxname],'boxes','-v7.3');
        try
            rmdir([cachebox,lockname]);
        catch ME
            disp(ME.message);
        end
    end
    
    now = toc(start);
    if now + options.now > options.timelimit
        return;
    end
end

if iid == 1
    while ~waitTillExists(bboxnames)
        now = toc(start);
        if now + options.now > options.timelimit
            return;
        end
    end
    
    system(['touch ',signalboxfile]);
    
    bboxes = cell(count);
    pBar = createProgressBar();
    for c = 1:count
        pBar(c,count);
        load(bboxnames{c},'boxes');
        bboxes(:,c) = boxes;
    end
    
    finalboxfile = [targetdir,'Bboxes.mat'];
    
    if fileExists(finalboxfile)
        delete(finalboxfile);
    end
    
    save(finalboxfile,'bboxes','-v7.3');
    
    system(['tar -czvf ',targetdir,'Bboxes.tar.gz ',cachebox]);
    system(['rm -rvf ',cachebox(1:end-1)]);
    system(['rm -v ',signalboxfile]);
    finishedflag = [targetdir,'Finished.flag'];
    system(['touch ',finishedflag]);
end

end

