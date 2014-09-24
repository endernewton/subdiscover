function boxesBLOCK = eldaDetectBLOCK(im, models, fname, return_feats, options)
% Detect model in images

if(nargin<4)
    return_feats=0;
end

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

% feats=[];
boxesBLOCK = cell(length(models),1);

pyra     = featpyramidBLOCK(im,models,fname);
interval = models{1}.interval;
l = length(pyra.feat);
levels   = 1:l;
if shrinkTest
    levels = levels(l-round(interval*shrinkLayers):l);
else
    levels = levels(interval+1:end);
end

% levels = levels(interval+1:min(l,round(2.5*interval)));
padx = pyra.padx;
pady = pyra.pady;

for i = 1:length(models)
    
    boxes    = zeros(10000,5);
    filters  = {models{i}.w};
    
    sizx = size(models{i}.w,2);
    sizy = size(models{i}.w,1);
    
    cnt  = 0;
    
    % Ignore the hallucinated (inteprolated) scales
    t=0;
    
    for l = levels,
        scale = pyra.scale(l);
        resp  = fconv(pyra.feat{l},filters,1,1);
        resp  = resp{1};
        
        [y,x] = find(resp >= models{i}.thresh);
        I  = (x-1)*size(resp,1)+y;
        if(~isempty(I) && return_feats)
            tic
            f1=zeros(sizx*sizy*(size(models{i}.w,3)),numel(y));
            for k=1:numel(y)
                f2=pyra.feat{l}(y(1):y(1)+sizy-1,x(1):x(1)+sizx-1,:);
                %remove last feature
                %f2=f2(:,:,1:end-1);
                f1(:,k)=f2(:);
            end
            %         feats=[feats f1];
            t=t+toc;
        end
        
        x1 = (x-1-padx)*scale+1;
        y1 = (y-1-pady)*scale+1;
        x2 = x1 + sizx*scale-1;
        y2 = y1 + sizy*scale-1;
        
        ii = cnt+1:cnt+length(I);
        
        boxes(ii,:) = [x1 y1 x2 y2 resp(I)];
        cnt = cnt+length(I);
    end
    
%     boxesBLOCK{i} = boxes(1:cnt,:);
    [~,boxesBLOCK{i}] = Nms(boxes(1:cnt,:),.5);
end

end

