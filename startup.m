% -------------------------------------------------------------------------
% Unsupervised Object Discovery and Segmentation
% Xinlei Chen, 2014 [enderchen@cs.cmu.edu]
% Please email me if you find bugs, or have suggestions or questions
% -------------------------------------------------------------------------

% add paths
addpath('features');
addpath(genpath('dataset')); 
addpath(genpath('grabcut')); 
addpath(genpath('maxflow')); 
addpath(genpath('sed'));
addpath(genpath('subclass')); 
addpath(genpath('toolbox'));
addpath(genpath('utility'));

options = [];

% time
options.now = 0;
options.timelimit = 10 * 3600; % time limit to run each component

% seed
options.fixedSeed = 1; % if use fixed random seed

%% Below is the options for all paths, for new datasets you will have to set the path yourself
% data
options.datafolder = '/IUS/homes4/rohytg/projects/003_SelfieSeg/datasets/selfie_tiny/'; % PATH to the directory that contains all the datasets to run, in the format of PATH/DATASET/CATEGORY/,
% e.g. PATH/Rubinstein100/Car/ has ONLY .jpg images, where PATH/Rubinstein100/Car/GroundTruth has .png ground truth.
options.cachefolder = fullfile(pwd, 'CachesR/'); % cache intermediate files
options.resultfolder = fullfile(pwd, 'ResultsR/'); % folder that holds the result
options.eldafile = fullfile(pwd,'/subclass/elda/background.mat'); % background file for ELDA, representing the negative world
options.generalpriorfile = fullfile(pwd,'/grabcut/prior.mat'); % segmentation prior for objects, used when no segmentation prior is learned for that class
options.lsvmNegFolders = {'/IUS/homes4/rohytg/projects/003_SelfieSeg/datasets/ScenesSub/'}; % negative image sets used for training detectors

% elda Training/Testing
options.initCandMeth = 'sed'; % full or sed, methods used for initial bboxes
options.eldaFeat = 'HOG'; % HOG or CHOG, features used
options.maxModelsOnes = 500; % how many detectors fire in parallel (trade-off between memory and time)
options.thresEdge = 0.99; % threshold if refinebox is used for each image
options.bgSample = 2000;
options.randomNeg = 300;
options.poolSize = 150;
options.poolOrder = 20;
options.poolInterval = 5;
options.poolSbin = 8;

% second-step clustering
options.ratioS = 0.5;
options.ratioDK = 0.8; % how much of the data should be kept, so 0.8 means 20% of the data is noise
options.sizeDK = 70; % if the cluster is too big, then probably you would still keep them, this is especially the case for large collections of data
options.topN = 4; % (rohit) WHY?? number of top detections to be used
options.overlapDouble = 0.5; % maximum overlap between two patches in the same 'detection'
options.sizeThres = 1; % (rohit) CHANGE THIS!!! threshold for the minimum number of instances in each cluster
options.maxIterMerge = 0.8; % probe clustering to get rid of bad images
options.minIterMerge = 0.5; % final clustering for merging
options.maxSimiMerge = 0.6; % final clustering for merging
options.minSimiMerge = 0.2; % probe clustering to get rid of bad images

% latent SVM training
options.lsvmFeatureName = 'HOG'; % HOG or CHOG, features for latent SVM
options.cachesize = 24000;
options.cachebyte = 2*2^30;
options.wlssvmM = 0;
options.fgOverlap = 0.7;
options.bFlipPos = 1;
options.imSubDir = ''; % sub directory in each folder in options.lsvmNegFolders that contains images
options.trainPath = 'train_path.mat';
options.lowerNeg = 3; % starting index for negative images, not important
options.higherNeg = 12; % ending index for negative images, not important
options.maxnegsmall = 200;
options.maxneglarge = 1000;
options.lsvmSbin = 8;
options.lsvmInterval = 10;
options.lsvmRegu = 0.02;
options.nComp = 1;

% latent SVM testing
options.thresOffset = -.5; % offset of the model threshold to get the detections
options.testIntervalScene = 10; % intervals for detection
options.testInterval = 10; % intervals for detection
options.padding = 0.15;
options.bFlipTest = 1; % fliped detection, preferred to be 1
options.offsetGet = -0.3; % the offset when getting the clusters
options.offsetRat = -0.4; % the offset to compute ratios of detections with the training data

% get the masks for joint clusters
options.diffThreshold = 1e-3;
options.maxIterGC = 200; % maximum number of iterations for GrabCut
options.KGC = 5;
options.KGCGroup = 5;
options.GGC = 50;
options.Beta = 0.5;
options.Alpha = 1;
options.convergeRateGroup = 0.1;

% detection + segmentation
options.doMorph = true; % apply morphological operator for post-processing
options.Gamma = 50; % weight from the smooth term
options.maskThres = 0.5; % threshold on the mask to initialize fg/bg appearance models
options.overlapDet = 0.5; % NMS to get the good detections
options.ratioMax = 0.7; % ratio to the maxium number of detections for detection
options.canSize = 200; % cannonical size for averaging the segmentation
options.dumpTempImages = 1; % whether to dump the temp images
