function histInter = similarityToSet(wordHist, histograms, options)
% by Ender, xinleic@cs.cmu.edu
% Oct 16 2012,
% Each column is a datum point

if nargin < 3
    options = [];
end

similarity = 'histInter';
if isfield(options,'similarity')
    similarity = options.similarity;
end

if strcmp(similarity,'histInter')
    histInter = sum(bsxfun(@min,histograms,wordHist),1);
elseif strcmp(similarity,'cosine')
    histInter = wordHist' * histograms;
elseif strcmp(similarity,'histInterNorm')
    histInter = sum(bsxfun(@min,histograms,wordHist),1) ./ sum(bsxfun(@max,histograms,wordHist),1);
elseif strcmp(similarity,'euclidean')
    histInter = bsxfun(@minus,histograms,wordHist);
    histInter = -sum(histInter.^2,1);
end

end