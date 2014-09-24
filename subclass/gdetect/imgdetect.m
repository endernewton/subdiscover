function [ds, bs, trees] = imgdetect(im, model, thresh, featurename)
% Wrapper around gdetect.m that computes detections in an image.
%   [ds, bs, trees] = imgdetect(im, model, thresh)
%
% Return values (see gdetect.m)
%
% Arguments
%   im        Input image
%   model     Model to use for detection
%   thresh    Detection threshold (scores must be > thresh)

% Feature_opts=Feature_INIT(featurename);

im = color(im);
pyra = lsvmfeatpyramid(im, model, featurename);
[ds, bs, trees] = gdetect(pyra, model, thresh, inf, featurename);
