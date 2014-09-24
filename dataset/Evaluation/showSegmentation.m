function segIm = showSegmentation(im, mask, type)
% type:
%   1 = image + mask + foreground
%   2 = image + foreground
%   3 = mask + foreground
%   4 = foreground


if exist('type') ~= 1
    type = [1,2];
end

im = im2double(im);
if size(im,3)==1
    im = repmat(im,[1,1,3]);
end

assert(all(size(im(:,:,1))==size(mask)));
[height,width,nChannels] = size(im);

switch type(1)
    case 1
        ShowSegmentationFun = @ShowSegmentationCheckerboardBackground;
    case 2
        ShowSegmentationFun = @ShowSegmentationOutline;
end

switch type(2)
    case 1
        segIm = zeros(height,width*3,nChannels,'double');
        segIm(:,1:width,:) = im2double(im);
        segIm(:,width+1:width*2,:) = repmat(mask,[1,1,3]);
        segIm(:,width*2+1:end,:) = ShowSegmentationFun(im, mask);
    case 2
        segIm = zeros(height,width*2,nChannels,'double');
        segIm(:,1:width,:) = im2double(im);
        segIm(:,width+1:end,:) = ShowSegmentationFun(im, mask);
    case 3
        segIm = zeros(height,width*2,nChannels,'double');
        segIm(:,1:width,:) = repmat(mask,[1,1,3]);
        segIm(:,width+1:end,:) = ShowSegmentationFun(im, mask);
    case 4
        segIm = ShowSegmentationFun(im, mask);
end


function segIm = ShowSegmentationCheckerboardBackground(im, mask)

[height,width,~] = size(im);

bkgrnd = imread('background.png');

if size(bkgrnd,1)<height || size(bkgrnd,2)<width
    sx = ceil(width/size(bkgrnd,2));
    sy = ceil(height/size(bkgrnd,1));
    bkgrnd = repmat(bkgrnd,[sy,sx,1]);
end

bkgrnd = bkgrnd(1:height,1:width,:);

segIm = imAddMask(bkgrnd, mask, im);


function segIm = ShowSegmentationOutline(im, mask)

[height, width] = size(mask);

% compute edges
xEdges = [zeros(height,1), (mask(:,2:end)-mask(:,1:end-1))];
yEdges = [zeros(1,width); (mask(2:end,:)-mask(1:end-1,:))];
edges = xEdges | yEdges;
edges = imdilate(edges, strel('square',3));

segIm = im;
color = [1,0,0];
for c = 1:3
    tmp = segIm(:,:,c);
    tmp(edges) = color(c);
    segIm(:,:,c) = tmp;
end
