% function to super-impose mask
function Im = imAddMask(background,mask,im)

if ~isa(background,'double')
    background = im2double(background);
end
if ~isa(mask,'double')
    mask = double(mask);
end
if ~isa(im,'double')
    im = im2double(im);
end

% first add mask as a shadow to background
[height,width] = size(mask);
background = background(1:height,1:width,:);
if size(background,3)==1
    background = repmat(background,[1 1 3]);
end
if size(im,3)==1
    im = repmat(im,[1 1 3]);
end

Mask = zeros(height,width);
Mask(5:end,5:end) = mask(1:end-4,1:end-4);
Mask = imfilter(Mask,fspecial('gaussian',11,2.5),'same','replicate');
Mask = repmat(Mask,[1 1 3]);
mask = imfilter(mask,fspecial('gaussian',5,1),'same','replicate');
mask = repmat(mask,[1 1 3]);

Im = (background.*(1-Mask)+Mask*0.02).*(1-mask)+im.*mask;
Im = max(min(Im,1),0);
