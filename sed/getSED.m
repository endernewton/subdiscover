function [E,O] = getSED( I, options )
%GETSKETCHTOKENS Wrapper function for getting sketch token edges
%   by Ender, xinleic@cs.cmu.edu

if nargin < 2
    options = [];
end

modelFnm = 'modelFinal';
if isfield(options,'modelFinal')
    modelFnm = options.modelFnm;
end
options.modelFnm = modelFnm;

persistent model
if isempty(model)
    load([pwd,'/sed/models/forest/modelBsds.mat']);
    model.opts.multiscale=1;          % for top accuracy set multiscale=1
    model.opts.sharpen=2;             % for top speed set sharpen=0
    model.opts.nTreesEval=4;          % for top speed set nTreesEval=1
    model.opts.nThreads=2;            % max number threads for evaluation
    model.opts.nms=0;                 % set to true to enable nms
%     model.opts.multiscale=1;          % for top accuracy set multiscale=1
%     model.opts.nTreesEval=4;          % for top speed set nTreesEval=1
%     model.opts.nThreads=2;            % max number threads for evaluation
%     model.opts.nms=0;                 % set to true to enable nms (fairly slow)
end

[E,O] =edgesDetect(I,model);

end

