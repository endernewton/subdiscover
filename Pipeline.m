% -------------------------------------------------------------------------
% Unsupervised Object Discovery and Segmentation
% Xinlei Chen, 2014 [enderchen@cs.cmu.edu]
% Please email me if you find bugs, or have suggestions or questions
% -------------------------------------------------------------------------


% WARNING: You first need to set the paths in startup.m and compile
% everything in grabcut/, maxflow/, features/, toolbox/, subclass/,

% instructions to compile for each of them can be find at:

% >> grabcut: cd grabcut; compile_gc (see http://vision.csd.uwo.ca/code/)
% >> maxflow: cd maxflow; maxflow_make (see http://vision.csd.uwo.ca/code/)
% >> toolbox: cd toolbox/external; toolboxCompile (it is from
% http://vision.ucsd.edu/~pdollar/toolbox/)
% >> features and subclass: (originally from DPM v5, so see
% http://www.cs.berkeley.edu/~rbg/latent/)

if ~exist('options','var')
    startup; % get the options
end

% start of the pipeline
%% Set this node to be master node or slave node
iid = 1; 
% 1 for master node, only ONE instance can be run at the same time,
% everything else for slave node, can be launched multiple times (like 100 times in a computing cluster)
% what slave node does is to process jobs in parallel, but you can
% accomplish the same thing with the master node only, just taking longer
% time

% NOTE: For each of the following, if you are running on a computing cluster, please
% wait till every node has done for its job, and submit the next!

%% ELDA Training and Testing
SubClassTTWrapper(iid,options);

%% Get Top ELDA Results
SubClassTopWrapper(iid,options);

%% Get Subcategories
SubClassClusterMWrapper(iid,options);

%% Graph-Cut based Group Segmentation
BBCLMaskClass(iid,options);

%% Train Latent SVM Detectors
objTrainWrapperMAT(iid,options);

%% Test Latent SVM Detectors
objTestWrapper(iid,options);

%% Get Measurements of the Subcategory
objComputeRatioWrapper(iid,options); 
% intuition is the detection number should not be significantly larger 
% than the original instances used for training

%% Get Latent SVM Detections
objGetDetectionsWrapper(iid,options);

%% Transfer The Segmentation Labels and Get the final Segmentations
TransferClusteringWrapper(iid,options);

%% Evaluation, Code from http://people.csail.mit.edu/mrub/ObjectDiscovery/
EvaluateDataSetWrapper(iid,options);

% end of the pipeline