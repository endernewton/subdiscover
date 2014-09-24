% GNU licence:
% Copyright (C) 2012  Itay Blumenthal
% 
%     This program is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 2 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program; if not, write to the Free Software
%     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USAfunction finalLabel = GCAlgo( im, fixedBG,  K, G, maxIterations, Beta, diffThreshold, myHandle )

function finalLabel = GCAlgo( im, fixedBG,  K, G, maxIterations, Beta, diffThreshold, myHandle )

%%%%%%%%%%%%%%%%%%%%%
%%% Get definite labels defining absolute Background :
prevLabel = double(fixedBG);

%%%%%%%%%%%%%%%%%%%%%
%%% Calculate the smoothness term defined by the entire image's RGB values
bNormGrad = true;

%%% Get the image gradient
gradH = im(:,2:end,:) - im(:,1:end-1,:);
gradV = im(2:end,:,:) - im(1:end-1,:,:);

gradH = sum(gradH.^2, 3);
gradV = sum(gradV.^2, 3);

%%% Use the gradient to calculate the graph's inter-pixels weights
if ( bNormGrad )
    hC = exp(-Beta.*gradH./mean(gradH(:)));
    vC = exp(-Beta.*gradV./mean(gradV(:)));
else
    hC = exp(-Beta.*gradH);
    vC = exp(-Beta.*gradV);
end

%%% These matrices will evantually use as inputs to Bagon's code
hC = [hC zeros(size(hC,1),1)];
vC = [vC ;zeros(1, size(vC,2))];
sc = [0 G;G 0];

%%%%%%%%%%%%%%%%%%%%%
%%% Start the EM iterations :
bgMean = [];
fgMean = [];
for iter=1:maxIterations
%     iter;
    if ~isempty(myHandle)
        set(myHandle,'String',strcat(num2str(100* iter/maxIterations),' %'  ));
        pause(0.2);
    end
    bgIds   = find(prevLabel == 1);
    fgIds   = find(prevLabel == 0);
    
    %%% Use NOT FIXED labels to get the Log Probability Likelihood 
    %%% of the pixels to a GMM color model (inferred from the labels...)
    bgMeanInit = bgMean;
    fgMeanInit = fgMean;
    [bgLogPL fgLogPL bgMean fgMean ] =  CalcLogPLikelihood(im, K, bgIds,fgIds, bgMeanInit, fgMeanInit );
    
    %%% Use our A-Priori knowledge of Background labels & set the Forground
    %%% weights according to it.
    fgLogPL(fixedBG) = max(max(fgLogPL));
        
    %%% Now that we have all inputs, calculate the min-cut of the graph
    %%% using Bagon's code. Not much to explain here, for more details read
    %%% the graph cut documentation in the   GraphCut.m    file.
    dc = cat(3, bgLogPL, fgLogPL);
    graphHandle = GraphCut('open', dc , sc, vC, hC);
    graphHandle = GraphCut('set', graphHandle, int32(prevLabel == 0));
    [graphHandle currLabel] = GraphCut('expand', graphHandle);
    currLabel = 1 - currLabel;
    GraphCut('close', graphHandle);
    
    %%% Break if current result is somewhat similar to previuos result
    if nnz(prevLabel(:)~=currLabel(:)) < diffThreshold*numel(currLabel)
        break;
    end
    
    prevLabel = currLabel;
        
end
finalLabel = currLabel;

function [ bgLogPL fgLogPL bgMean fgMean ] = CalcLogPLikelihood(im, K, bgIds,fgIds , bgMeanInit, fgMeanInit )

numPixels = size(im,1) * size(im,2);
allBGLogPL = zeros(numPixels,K);
allFGLogPL = zeros(numPixels,K);

%%% Seperate color channels 
R = im(:,:,1);
G = im(:,:,2);
B = im(:,:,3);

%%% Prepare the color datasets according to the input labels 
imageValues = [R(:) G(:) B(:)];
bgValues = [R(bgIds)    G(bgIds)     B(bgIds)];
fgValues = [R(fgIds)    G(fgIds)     B(fgIds)];
numBGValues = size(bgValues,1);
numFGValues = size(fgValues,1);

%%%%%%
% Use a 'manual' way to calculate the GMM parameters, instead of using
% Matlab's gmdistribution.fit() function. This is due to better speed 
% results..
% Start with Kmeans centroids calculation :
opts = statset('kmeans');
opts.MaxIter = 200;

if ( ~isempty(bgMeanInit) && ~isempty(fgMeanInit) )
    [bgClusterIds bgMean] = kmeans(bgValues, K, 'start', bgMeanInit,  'emptyaction','singleton' ,'Options',opts);
    [fgClusterIds fgMean] = kmeans(fgValues, K, 'start', fgMeanInit,  'emptyaction','singleton', 'Options',opts);
else
    [bgClusterIds bgMean] = kmeans(bgValues, K, 'emptyaction','singleton' ,'Options',opts);
    [fgClusterIds fgMean] = kmeans(fgValues, K, 'emptyaction','singleton', 'Options',opts);
end

checkSumFG = 0;
checkSumBG = 0;

for k=1:K
    %%% Get the k Gaussian weights for Background & Forground 
    bgGaussianWeight = nnz(bgClusterIds==k)/numBGValues;
    fgGaussianWeight = nnz(fgClusterIds==k)/numFGValues;
    checkSumBG = checkSumBG + bgGaussianWeight;
    checkSumFG = checkSumFG + fgGaussianWeight;

    %%% FOR ALL PIXELS - calculate the distance from the k gaussian (BG & FG)
    bgDist = imageValues - repmat(bgMean(k,:),size(imageValues,1),1);
    fgDist = imageValues - repmat(fgMean(k,:),size(imageValues,1),1);

    %%% Calculate the gaussian covariance matrix & use it to calculate
    %%% all of the pixels likelihood to it :
    bgCovarianceMat = cov(bgValues(bgClusterIds==k,:));
    fgCovarianceMat = cov(fgValues(fgClusterIds==k,:));
    allBGLogPL(:,k) = -log(bgGaussianWeight)+0.5*log(det(bgCovarianceMat)) + 0.5*sum( (bgDist/bgCovarianceMat).*bgDist, 2 );
    allFGLogPL(:,k) = -log(fgGaussianWeight)+0.5*log(det(fgCovarianceMat)) + 0.5*sum( (fgDist/fgCovarianceMat).*fgDist, 2 );
end

assert(abs(checkSumBG - 1) < 1e-6 && abs(checkSumFG - 1)  < 1e-6 );

%%% Last, as seen in the GrabCut paper, take the minimum Log likelihood
%%% (    argmin(Dn)    )
bgLogPL = reshape(min(allBGLogPL, [], 2),size(im,1), size(im,2));
fgLogPL = reshape(min(allFGLogPL, [], 2),size(im,1), size(im,2));


