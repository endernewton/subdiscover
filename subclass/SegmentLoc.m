function seg = SegmentLoc(image,mask,options)
% Segments the image using the mask to initialize Grabcut. Modified
% version.
% Credit: Alexander Vezhnevets, Matthieu Guillaumin, et al. 
% ImageNet Auto-annotation with Segmentation Propagation
% -------------------------------------------------------------------------
% Unsupervised Object Discovery and Segmentation
% Xinlei Chen, 2014 [enderchen@cs.cmu.edu]
% Please email me if you find bugs, or have suggestions or questions
% -------------------------------------------------------------------------

if nargin < 3
    options = [];
end

threshold = 0.5;
if isfield(options,'maskThres')
    threshold = options.maskThres;
end

maxIterations = 10;
if isfield(options,'maxIterGC')
    maxIterations = options.maxIterGC;
end

fixedSeed = 0;
if isfield(options,'fixedSeed')
    fixedSeed = options.fixedSeed;
end

if fixedSeed
    RandStream('twister','Seed',0); % just to make sure the performance
end

if iscell(image)
    seg = map('c','par',@compute,'cc--',{image,mask,threshold,maxIterations,options});
else
    seg = compute(image,mask,threshold,maxIterations,options);
end

end

function [seg,energy,segs,flows,energies] = compute(image,mask,threshold,maxIterations,options)
% For one image only.

% settings
doMorph = false; % apply morphological operations at the end (as in original GrabCut)
if isfield(options,'doMorph')
    doMorph = options.doMorph;
end

% output
segs = cell(1,maxIterations+1);
flows = zeros(1,maxIterations+1);
energies = zeros(1,maxIterations+1);
converged = false;

% initialization
[img,h,w] = getImage(image);
clear image
[P,~] = getPairwise(img,h,w,options);
[fgm bgm] = initializeModel(img,mask>=threshold,options);
U_loc = cat(3,mask,1-mask);

for i = 1:maxIterations
    
    %	pg_message('iteration %d/%d',i,maxIterations);
    
    [fgk bgk] = assignComponents(img,fgm,bgm);
    U_app = getUnary_app(img,fgm,bgm,fgk,bgk);
    U = getUnary(U_app,U_loc);
    clear U_app
    
    [segs{i} flows(i) energies(i)] = getSegmentation(P,U,w,h);
    disp(energies(i));
    
    %	pg_message('flow = %g, energy = %g',flows(i),energies(i));
    
    % TODO assert energy/flow decrease
    
    if i>1 && (all(segs{i-1}(:)==segs{i}(:)) || energies(i-1) < energies(i))
        %		pg_message('converged after %d/%d iterations',i,maxIterations);
        converged = true;
        break;
    end
    
    [fgm bgm] = learnModel(img,segs{i},fgm,bgm,fgk,bgk,options);
    
end

if ~converged
    %	pg_message('did not converge after %d iterations',maxIterations);
    fprintf('did not converge after %d iterations\n',maxIterations);
end

segs = segs(1:i);
flows = flows(1:i);
energies = energies(1:i);

seg = segs{end};
energy = energies(end);

if doMorph
    seg = applyMorph(seg);
end

end

function energy = getEnergy(A,T,labels)

energy = 0;
energy = energy + sum(T(labels==0,2));
energy = energy + sum(T(labels==1,1));
energy = energy + sum(sum(A(labels==0,labels==1)));

end

function [img h w] = getImage(img)
img = color(img);
img = double(img);
% assert(ndims(img)==3);

h = size(img,1);
w = size(img,2);
% assert(size(img,3)==3);
end

function [fg bg] = initializeModel(img,mask,options)

% pg_message('initializeModel');

assert(any(mask(:)));
assert(any(~mask(:)));

img = reshape(img,[],3);

K = 5;
if isfield(options,'KGC')
    K = options.KGC;
end

% keyboard;

fg = pdf_gm.fit_using_vectorquantisation(img(mask,:),K);
bg = pdf_gm.fit_using_vectorquantisation(img(~mask,:),K);

end

function [fk bk] = assignComponents(img,fg,bg)

% pg_message('assignComponents');
fk = fg.cluster_2d(img);
bk = bg.cluster_2d(img);

end

function [fg bg] = learnModel(img,seg,fg,bg,fk,bk,options)

% pg_message('learnModel');

K = 5;
if isfield(options,'KGC')
    K = options.KGC;
end

img = reshape(img,[],3);
seg = reshape(seg,[],1);
fk = reshape(fk,[],1);
bk = reshape(bk,[],1);

fg = pdf_gm.fit_given_labels(img(seg,:),fk(seg),K,fg);
bg = pdf_gm.fit_given_labels(img(~seg,:),bk(~seg),K,bg);
end

function [A,K] = getPairwise(img,h,w,options)

% pg_message('getPairwise');

% [h,w,~] = size(img);
n = h*w;

imgr = img(:,:,1); imgr = imgr(:);
imgg = img(:,:,2); imgg = imgg(:);
imgb = img(:,:,3); imgb = imgb(:);

% locations
[x,y] = meshgrid(1:w,1:h);
x = x(:); y = y(:);

% neighbors down -> y+1 -> idx+1
n1_i1 = 1:n; n1_i1 = n1_i1(y<h);
n1_i2 = n1_i1+1;

% neighbors right-down -> x+1,y+1 -> idx+1+h
n2_i1 = 1:n; n2_i1 = n2_i1(y<h & x<w);
n2_i2 = n2_i1+1+h;

% neighbors right -> x+1 -> idx+h
n3_i1 = 1:n; n3_i1 = n3_i1(x<w);
n3_i2 = n3_i1+h;

% neighbors right-up -> x+1,y-1 -> idx+h-1
n4_i1 = 1:n; n4_i1 = n4_i1(x<w & h>1);
n4_i2 = n4_i1+h-1;

from = [n1_i1 n2_i1 n3_i1 n4_i1];
to = [n1_i2 n2_i2 n3_i2 n4_i2];

gamma = 50; % TODO could be trained
if isfield(options,'Gamma')
    gamma = options.Gamma;
end

invdis = 1./sqrt((x(from)-x(to)).^2+(y(from)-y(to)).^2);
dz2 = (imgr(from)-imgr(to)).^2 + (imgg(from)-imgg(to)).^2 + (imgb(from)-imgb(to)).^2;
beta = (2*mean(dz2.*invdis))^-1; % TODO changed, .*invdis is not in paper, but in gco
expb = exp(-beta*dz2);
c = gamma * invdis .* expb;

A = sparse([from to],[to from],[c c]); % TODO do i need to explicitely make it symmetric?

K = 1+max(sum(A,2)); % TODO changed, gco seems to have only half of this, not correct
end

function T = getUnary_app(img,fg,bg,fk,bk)
% pg_message('getUnary');
T = cat(3,fg.pdf_2d(img,fk),bg.pdf_2d(img,bk));
end

function U = getUnary(U_app,U_loc)
U = -log(U_app) - log(U_loc); % U_loc .* U_app
U = reshape(U,[],2);
U = sparse(U);
end

function [seg flow energy] = getSegmentation(P,U,w,h)

[flow labels] = maxflow(50*P,50*U);
seg = reshape(labels==1,h,w);
energy = getEnergy(P,U,labels);

end

function seg = applyMorph(seg)

oseg = seg;
try
    seg = imclose(seg,strel('disk',3));
    seg = imfill(seg,'holes');
    seg = bwmorph(seg,'open'); % remove thin regions
    [~,N] = bwlabel(seg); % select largest 8-connected region
    h = hist(seg(:),1:N);
    [~,i] = max(h);
    seg = seg==i;
catch ME
    disp(ME.message);
    seg = oseg;
    return;
end

end
