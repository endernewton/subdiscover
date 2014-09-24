function Bbs = imgdetectBLOCK(im, models, threshs, featurename, options)

if nargin < 5
    options = [];
end

shrinkTest = 0;
if isfield(options,'shrinkTestObj')
    shrinkTest = options.shrinkTestObj;
end

shrinkLayers = 1.5;
if isfield(options,'shrinkLayersObj')
    shrinkLayers = options.shrinkLayersObj;
end

im = color(im);
hIm = size(im,1);
wIm = size(im,2);

N = length(models);
nComp = models{1}.numfilters / 2;
% pyra = lsvmfeatpyramid(im, model, featurename);
pyra = lsvmfeatpyramidBLOCK(im,models,featurename);
sbin = models{1}.sbin;
interval = models{1}.interval;
fsize = models{1}.blocks(1).shape(3);
sizes1 = zeros(N,nComp); 
sizes2 = zeros(N,nComp);
if ~options.bFlipTest
    ws = cell(N,nComp);
else
    ws = cell(N,nComp*2);
end
bs = zeros(nComp,N); 
count = 1;
ct = 1;
for j=1:nComp
    sizes1(:,j) = cellfun(@(x)(x.filters(ct).size(1)),models);
    sizes2(:,j) = cellfun(@(x)(x.filters(ct).size(2)),models);
    bs(j,:) = cellfun(@(x)single(x.blocks(count+1).w*x.features.bias),models);
    ws(:,j) = cellfun2(@(x)reshape(single(x.blocks(count).w),x.blocks(count).shape),models);
    ct = ct + 2;
    count = count + 6;
end
clear models

S = [max(sizes1(:)) max(sizes2(:))];
% flip the thing
if options.bFlipTest
    for i=1:N
        for j=1:nComp
            ws{i,j+nComp} = flipfeat(ws{i,j},featurename);
        end
    end
    sizes1 = repmat(sizes1,1,2);
    sizes2 = repmat(sizes2,1,2);
    bs = repmat(bs,2,1);
    nComp = 2*nComp;
end
bs = bs(:);

templates = zeros(S(1),S(2),fsize,N*nComp,'single');
% template_masks = zeros(S(1),S(2),fsize,N,'single');

for i = 1:N
    for j=1:nComp
        count = i * nComp - nComp + j;
        t = zeros(S(1),S(2),fsize,'single');
        t(1:sizes1(i,j),1:sizes2(i,j),:) = ws{i,j};
        
        templates(:,:,:,count) = t;
    end
%     template_masks(:,:,:,i) = repmat(sum(t.^2,3)>0,[1 1 fsize]);
end

padx = pyra.padx;
pady = pyra.pady;

l = length(pyra.feat);
levels   = 1:l;
if shrinkTest
    levels = levels(max(1,l-round(interval*shrinkLayers)):l);
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
pscales = pyra.scales(levels);
clear curf pyra

offsets = cat(2,offsets{:});
uus = cat(2,uus{:});
vvs = cat(2,vvs{:});

exemplar_matrix = reshape(single(templates),[],size(templates,4));
clear templates

r = exemplar_matrix' * X;
clear exemplar_matrix X
r = bsxfun(@plus, r, bs);
clear bs
Bbs = cell(N,1);

count = 1;
for exid = 1:N
    result = r(count:count+nComp-1,:);
    if nComp > 1
        [result,ind] = max(result);
    else
        ind = ones(1,length(result));
    end
    goods = find(result >= threshs(exid));
    
    count = count + nComp;
    
    if isempty(goods)
        continue
    end
    
    [sorted_scores,bb] = ...
        sort(result(goods),'descend');
    bb = goods(bb);
    ind = ind(bb);
    
    levels = offsets(2,bb);
    scales = pscales(levels);
    o = [uus(bb)' vvs(bb)'];
    
    try
        bbs = ([o(:,2)-padx o(:,1)-pady o(:,2)+sizes2(exid,ind)'-padx ...
            o(:,1)+sizes1(exid,ind)'-pady] - 1) .* ...
            repmat(sbin./scales,1,4) + repmat([1 1 0 ...
            0],length(scales),1);
        
        if options.bFlipTest
            idp = (ind-nComp/2) > 0;
            bbs(idp,5) = ind(idp) * 2 - 1 - nComp;
            bbs(~idp,5) = ind(~idp) * 2 - 2;
        else
            bbs(:,5) = ind * 2 - 2;
        end
        bbs(:,6) = sorted_scores;
        
        bbs(:,1) = max(bbs(:,1), 1);
        bbs(:,2) = max(bbs(:,2), 1);
        bbs(:,3) = min(bbs(:,3), wIm);
        bbs(:,4) = min(bbs(:,4), hIm);
        
        w = bbs(:,3)-bbs(:,1)+1;
        h = bbs(:,4)-bbs(:,2)+1;
        I = (w <= 0) | (h <= 0);
        bbs(I,:) = [];
            
        Bbs{exid} = bbs;
    catch ME
        disp(ME.message);
    end

end

end
