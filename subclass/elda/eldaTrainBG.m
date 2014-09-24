function BG = eldaTrainBG(all,order,interval,sbin,fname,options)
% model = trainBG(all,order,interval,sbin)
% Trains a spatial autocorrelation function a from a list of images

ignore = true;

nf  = length(featuresWrapper(zeros([3 3 3]),1,fname));
if ignore,
    display('Ignoring last truncation feature');
    nf  = nf-1;
end
neg = zeros(nf,1);
n   = 0;

BG.sbin = sbin;
BG.interval = interval;
BG.maxsize = [0 0];

fprintf('Learning negative mean\n');
bhcnt=0;
for I = all,
    disp(I.im);
    bhcnt=bhcnt+1;
    if(rem(bhcnt,100)==0), fprintf('.'); end
    im = imread(I.im);
    sizeI = size(im);
    if length(sizeI) > 2
        if length(sizeI) ~= 3
            continue;
        end
%         sizeI = sizeI(1:2);
    else
        im = color(im);
    end
    
    if strcmpi(options.initCandMeth,'stoken')
        bb = [1,1,sizeI(2),sizeI(1)];
        bb = RefineBbxToken(im,bb,options);
        im = im(bb(2):bb(4),bb(1):bb(3),:);
    end
    
    % Extract feature pryamid, removing hallucinated octave
    pyra = featpyramid(im,BG,fname);
    pyra.feat = pyra.feat(interval+1:end);
    for s = 1:length(pyra.feat)
        featIm = pyra.feat{s};
        if ignore,
            featIm = featIm(:,:,1:end-1);
        end
        [imy,imx,imz] = size(featIm);
        t = imy*imx;
        for it = 1:2,
            feat = reshape(featIm,t,imz);
            n    = n + t;
            neg  = neg + sum(feat)';
            %      featIm = flipfeat(featIm);
        end
    end
end

neg = neg'/n;

w    = order;
h    = order;
dxy = [];
for x = 0:w-1,
    for y = 0:h-1,
        dxy = [dxy; [x y]];
        if x > 0 && y > 0,
            dxy = [dxy; [x -y]];
        end
    end
end
k    = size(dxy,1);
ns   = zeros(k,1);
cov  = zeros(nf,nf,k);


fprintf('\nLearning stationairy negative covariance');
for I = all,
    fprintf('.');
    disp(I.im);
    im = imread(I.im);
    sizeI = size(im);
    if length(sizeI) > 2
        if length(sizeI) ~= 3
            continue;
        end
%         sizeI = sizeI(1:2);
    else
        im = repmat(im,[1,1,3]);
    end
    % Extract feature pryamid, removing hallucinated octave
    pyra = featpyramid(im,BG,fname);
    pyra.feat = pyra.feat(interval+1:end);
    % Subtract mean
    for s = 1:length(pyra.feat),
        featIm = pyra.feat{s};
        if ignore,
            featIm = featIm(:,:,1:end-1);
        end
        [imy,imx,imz] = size(featIm);
        featIm = reshape(featIm,imy*imx,imz);
        featIm = bsxfun(@minus,featIm,neg);
        featIm = reshape(featIm,[imy imx imz]);
        pyra.feat{s} = featIm;
    end
    for it = 1:2,
        for s = 1:length(pyra.feat),
            for i = 1:k,
                dx = dxy(i,1);
                dy = dxy(i,2);
                [imy,imx,foo] = size(pyra.feat{s});
                if dy > 0,
                    y11 = 1;
                    y12 = imy - dy;
                else
                    y11 = -dy + 1;
                    y12 = imy;
                end
                if dx > 0,
                    x11 = 1;
                    x12 = imx - dx;
                else
                    x11 = -dx + 1;
                    x12 = imx;
                end
                if y12 < y11 || x12 < x11,
                    continue;
                end
                y21 = y11 + dy;
                y22 = y12 + dy;
                x21 = x11 + dx;
                x22 = x12 + dx;
                assert(y11 >= 1 && y12 <= imy && ...
                    x21 >= 1 && x22 <= imx);
                t    = (y12 - y11 + 1)*(x12 - x11 + 1);
                feat1 = reshape(pyra.feat{s}(y11:y12,x11:x12,:),t,nf);
                feat2 = reshape(pyra.feat{s}(y21:y22,x21:x22,:),t,nf);
                cov(:,:,i) = cov(:,:,i) + feat1'*feat2;
                ns(i) = ns(i) + t;
            end
        end
        % Flip features
%         for s = 1:length(pyra.feat),
%             %     pyra.feat{s} = flipfeat(pyra.feat{s});
%         end
    end
end

fprintf('\n');
neg = neg';

for i = 1:k,
    cov(:,:,i) = cov(:,:,i) / ns(i);
end

BG.neg = neg;
BG.cov = cov;
BG.dxy = dxy;
BG.ns  = ns;
BG.lambda = .01;

end
