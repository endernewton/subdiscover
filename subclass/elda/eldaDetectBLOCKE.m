function Bbs = eldaDetectBLOCKE(im, models, fname, return_feats, options)

if nargin < 5
    options = [];
end

shrinkTest = 0;
if isfield(options,'shrinkTest')
    shrinkTest = options.shrinkTest;
end

shrinkLayers = 1.5;
if isfield(options,'shrinkLayers')
    shrinkLayers = options.shrinkLayers;
end

numPerDet = inf;
if isfield(options,'numPerDet')
    numPerDet = options.numPerDet;
end

N = length(models);
pyra = featpyramidBLOCK(im,models,fname);
fsize = size(models{1}.w,3);
sizes1 = cellfun(@(x)size(x.w,1),models);
sizes2 = cellfun(@(x)size(x.w,2),models);
interval = models{1}.interval;
thres = cellfun(@(x)single(x.thresh),models);
ws = cellfun2(@(x)single(x.w),models);
clear models
% bs = zeros(N,1,'single');
S = [max(sizes1(:)) max(sizes2(:))];

templates = zeros(S(1),S(2),fsize,N,'single');
% template_masks = zeros(S(1),S(2),fsize,N,'single');

for i = 1:N
    t = zeros(S(1),S(2),fsize,'single');
    t(1:sizes1(i),1:sizes2(i),:) = ws{i};
    
    templates(:,:,:,i) = t;
%     template_masks(:,:,:,i) = repmat(sum(t.^2,3)>0,[1 1 fsize]);
end
clear sizes1 sizes2

padx = pyra.padx;
pady = pyra.pady;

l = length(pyra.feat);
levels   = 1:l;
if shrinkTest
    levels = levels(l-round(interval*shrinkLayers):l);
else
    levels = levels(interval+1:end);
end
pyra.feat = pyra.feat(levels);
l = length(pyra.feat);

pyr_N = cellfun(@(x)prod([size(x,1) size(x,2)]-S+1),pyra.feat);
sumN = sum(pyr_N);

X = zeros(S(1)*S(2)*fsize,sumN,'single');
offsets = cell(l, 1);
uus = cell(l,1);
vvs = cell(l,1);

counter = 1;
for i = 1:length(pyra.feat)
    s = size(pyra.feat{i});
    NW = s(1)*s(2);
    ppp = reshape(1:NW,s(1),s(2));
    b = im2col(ppp,[S(1) S(2)]);
    clear ppp
    
    offsets{i} = b(1,:);
    offsets{i}(end+1,:) = i;
    
    curf = reshape(single(pyra.feat{i}),[],fsize);
    
    for j = 1:size(b,2)
        X(:,counter) = reshape(single(curf(b(:,j),:)),[],1);
        counter = counter + 1;
    end
    
    [uus{i},vvs{i}] = ind2sub(s,offsets{i}(1,:));
end
pscales = pyra.scale(levels);
clear curf pyra

offsets = cat(2,offsets{:});
uus = cat(2,uus{:});
vvs = cat(2,vvs{:});

exemplar_matrix = reshape(single(templates),[],size(templates,4));
clear templates

r = exemplar_matrix' * X;
clear exemplar_matrix X
% r = bsxfun(@minus, r, bs);
clear bs
Bbs = cell(N,1);

for exid = 1:N  
    goods = find(r(exid,:) >= thres(exid));
    
    if isempty(goods)
        continue
    end
    
    [sorted_scores,bb] = ...
        sort(r(exid,goods),'descend');
    bb = goods(bb);
    
    levels = offsets(2,bb);
    scales = pscales(levels);
    o = [uus(bb)' vvs(bb)'];
    
    bbs = ([o(:,2)-padx o(:,1)-pady o(:,2)+size(ws{exid},2)-padx ...
        o(:,1)+size(ws{exid},1)-pady] - 1) .* ...
        repmat(scales,1,4) + repmat([1 1 0 ...
        0],length(scales),1);
    
    bbs(:,5) = sorted_scores;
    
    [~,bbs] = Nms(bbs,.5); % here you do the nms to save the size
    
    if numPerDet < size(bbs,1)
        bbs = bbs(1:numPerDet,:);
    end
    
    Bbs{exid} = bbs;
end

if return_feats
    disp('depreciated!');
end

end

