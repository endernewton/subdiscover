function [P, J, nPositive, nNegative] = evaluateSegmentation(maskDir, gtDir)


maskFiles = imdir(maskDir);
nMasks = length(maskFiles);
gtMaskFiles = imdir(gtDir);
nGtMasks = length(gtMaskFiles);
    
P = 0;
J = 0;
nPositive = 0;

fig = figure;

for i = 1:nGtMasks
    [~,imageName] = fileparts(gtMaskFiles(i).name);
%     [~,imageName] = fileparts(maskFiles(i).name);
    
    mask = readMask(maskDir, imageName);
    gtMask = readMask(gtDir, imageName);

    mask = double(mask(:,:,1) ~= 0);
    gtMask = double(gtMask(:,:,1) ~= 0);
    
    if ~all(imsize(mask) == imsize(gtMask))
        mask = imresize(mask, imsize(gtMask), 'nearest');
    end
    
    
    figure(fig);
    subplot(1,2,1); imagesc(mask); axis equal tight;
    xlabel('Result');
    subplot(1,2,2); imagesc(gtMask); axis equal tight;
    xlabel('Ground truth');
    colormap gray;
    subtitle(sprintf('Image %d/%d', i, nGtMasks));

    
    P = P + sum(gtMask(:)==mask(:)) ./ prod(imsize(gtMask));
    
    % Compute Jaccard only for images that contain an object
    if any(gtMask(:))
        J = J + sum( (mask(:)==1) & (gtMask(:)==1) ) ./ sum( (mask(:) | gtMask(:))==1 );
        nPositive = nPositive+1;
    end
end


P = P / nGtMasks;
J = J / nPositive;
nNegative = nGtMasks - nPositive;

close(fig);
