function histInter = distanceToSet(wordHist, histograms, options)
% by Ender, xinleic@cs.cmu.edu
% Oct 16 2012,
% Each column is a datum point

if nargin < 3
    options = [];
end

distance = 'histInter';
if isfield(options,'distance')
    distance = options.distance;
end

if strcmp(distance,'histInter')
    histInter = sum(bsxfun(@min,histograms,wordHist),1);
    histInter = -histInter;
elseif strcmp(distance,'euclidean')
    histInter = bsxfun(@minus,histograms,wordHist);
    histInter = sum(histInter.^2,1);
elseif strcmp(distance,'hellinger')
    wordHist = sqrt(wordHist);
    histInter = bsxfun(@minus,histograms,wordHist);
    histInter = sum(histInter.^2,1);    
elseif strcmp(distance,'chi2')
    histInter = bsxfun(@minus,histograms,wordHist);
    getSum = bsxfun(@plus,histograms,wordHist);
    histInter = sum(histInter.^2./(getSum+eps),1);
end

end
