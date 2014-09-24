function batchShowSegmentation(imageDir, maskDir, imageFiles, type, quality, targetSize, outDir)


mkdir(outDir);

if isempty(imageFiles)
    imageFiles = imdir(imageDir);
end

parfor i = 1:length(imageFiles)
    [~,imageName] = fileparts(imageFiles(i).name);
    im = imread(fullfile(imageDir, imageFiles(i).name));
    
    % masks are stored as either png, bmp, or jpg
    maskFile = [];
    if exist(fullfile(maskDir, [imageName '.png']))
        maskFile = fullfile(maskDir, [imageName '.png']);
    elseif exist(fullfile(maskDir, [imageName '.jpg']))
        maskFile = fullfile(maskDir, [imageName '.jpg']);
    elseif exist(fullfile(maskDir, [imageName '.bmp']))
        maskFile = fullfile(maskDir, [imageName '.bmp']);
    end
    
    if isempty(maskFile)
        warning('Cannot find mask for image: %s', imageName);
        continue;
    end
    
    mask = imread(maskFile);
    mask(mask~=0) = 1;

    if ~(all(size(im(:,:,1)) == size(mask)))
        warning('Inconsistent mask size: %s', maskFile);
        mask = imresize(mask, size(im(:,:,1))); % TODO
    end
    
    segIm = showSegmentation(im, mask, type);
    
    if ~isempty(targetSize)
        segIm = imresize(segIm, targetSize, 'bicubic');
    end
    
    saveSegIm(segIm, fullfile(outDir, [imageName '.jpg']), quality);
end


function saveSegIm(segIm, fileName, quality)

imwrite(segIm, fileName, 'Quality', quality);
