function mask = readMask(maskDir, imageName)


% masks are stored as either png, bmp, or jpg
maskFile = [];
if exist(fullfile(maskDir, [imageName '.png']))
    maskFile = fullfile(maskDir, [imageName '.png']);
elseif exist(fullfile(maskDir, [imageName '.jpg']))
    maskFile = fullfile(maskDir, [imageName '.jpg']);
elseif exist(fullfile(maskDir, [imageName '.bmp']))
    maskFile = fullfile(maskDir, [imageName '.bmp']);
end
% disp(maskFile);
mask = imread(maskFile);
mask = mask ~= 0;

