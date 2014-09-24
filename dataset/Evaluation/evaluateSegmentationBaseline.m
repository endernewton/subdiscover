function [P, J] = evaluateSegmentationBaseline(gtDir, baselineType)
% baselineType: 1 = all pixels classified as background
% baselineType: 2 = all pixels classified as foreground


gtMaskFiles = imdir(gtDir);
nGtMasks = length(gtMaskFiles);
    
P = 0;
J = 0;
nPositive = 0;

for i = 1:nGtMasks
    [~,imageName] = fileparts(gtMaskFiles(i).name);
    
    gtMask = readMask(gtDir, imageName);

    gtMask = double(gtMask(:,:,1) ~= 0);
    
    switch baselineType
        case 1
            mask = zeros(imsize(gtMask));
        case 2
            mask = ones(imsize(gtMask));
        otherwise
            error('Invalid baseline type!');
    end
    
    P = P + sum(gtMask(:)==mask(:)) ./ prod(imsize(gtMask));
    
    % Compute Jaccard only for images that contain an object
    if any(gtMask(:))
        J = J + sum( (mask(:)==1) & (gtMask(:)==1) ) ./ sum( (mask(:) | gtMask(:))==1 );
        nPositive = nPositive+1;
    end
end

P = P / nGtMasks;
J = J / nPositive;
