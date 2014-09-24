function createComparisonWebpageMultiClass(dataset, methods, outDir)


% Parameters
thumbHeight = 100;
pageWidth = 1024;
margin = 15;
jpgQuality = 90;
segVisType = [1,3];


datasetDir = fullfile(Project.dataDir, dataset);

classes = getDirectoryNames(datasetDir);

nClasses = length(classes);
nMethods = length(methods);

for i = 1:nClasses
    fprintf('%s\n', classes{i});
    
    classOutDir = fullfile(outDir, classes{i});
    
    mkdir(classOutDir);
    
    
    %------------------------------------------------------------------
    % Copy the source images and create thumbnails for the source images
    
    inImageDir = fullfile(datasetDir, classes{i});
    imageFiles = imdir(inImageDir);
    nImages = length(imageFiles);
    
    imageDir = fullfile(classOutDir, 'image');
    imageThumbDir = fullfile(classOutDir, 'image_thumb');
    
    mkdir(imageDir);
    mkdir(imageThumbDir);
    
    for j = 1:nImages
        [~,imageName] = fileparts(imageFiles(j).name);
        im = imread(fullfile(inImageDir, imageFiles(j).name));
        imwrite(im, fullfile(imageDir, [imageName '.jpg']), 'Quality', jpgQuality);
        
        thumb = imresize(im, [thumbHeight,NaN]);
        imwrite(thumb, fullfile(imageThumbDir, [imageName '.jpg']), 'Quality', jpgQuality);
    end
    
    
    %------------------------------------------------------------------
    % Visualize the segmentations
    
    for j = 1:nMethods
        resultDir = fullfile(Project.resultDir, dataset, methods{j});
        maskDir = fullfile(resultDir, classes{i});
        segDir = fullfile(classOutDir, 'segmentation', methods{j});
        
        batchShowSegmentation(inImageDir, maskDir, [], segVisType, jpgQuality, [], segDir);
    end
    
    
    %------------------------------------------------------------------
    % Create thumbnails
    
    for j = 1:nMethods
        segDir = fullfile(classOutDir, 'segmentation', methods{j});
        segFiles = imdir(segDir);
        
        segThumbDir = fullfile(classOutDir, 'segmentation_thumb', methods{j});

        mkdir(segThumbDir);
        
        for k = 1:length(segFiles)
            [~,name] = fileparts(segFiles(k).name);
            im = imread(fullfile(segDir, segFiles(k).name));
            thumb = imresize(im, [thumbHeight,NaN]);
            imwrite(thumb, fullfile(segThumbDir, [name '.jpg']), 'Quality', jpgQuality);
        end
    end
    
    
    %------------------------------------------------------------------
    % Create the comparison webpage
    
    fid = fopen(fullfile(classOutDir, 'index.html'), 'wt');
    title = sprintf('%s/%s', dataset, classes{i});
    writeHeader(fid, title);
    fprintf(fid, '<body>\n');
    fprintf(fid, '<table border="0" align="center">\n');
    
    % title
    fprintf(fid, '<tr>\n');
    fprintf(fid, '<td colspan="%d" align="center">\n', nMethods*2+1);
    fprintf(fid, '<h1>%s</h1>\n', title);
    fprintf(fid, '</td>\n');
    fprintf(fid, '</tr>\n');
    
    % table headers
    fprintf(fid, '<tr>\n');
    fprintf(fid, '<td align="center">\n');
    fprintf(fid, '<h2>%s</h2>\n', 'Source');
    fprintf(fid, '</td>\n');
    
    % seperator
    fprintf(fid, '<td width="%d"></td>\n', margin);
    
    for j = 1:nMethods
        fprintf(fid, '<td align="center">\n');
        fprintf(fid, '<h2>%s</h2>\n', methods{j});
        fprintf(fid, '</td>\n');
        
        if j < nMethods
            % seperator
            fprintf(fid, '<td width="%d"></td>\n', margin);
        end
    end
    fprintf(fid, '</tr>\n');
    
    imageFiles = imdir(imageDir);
    
    for j = 1:nImages
        fprintf(fid,'<tr>\n');
        
        % source image
        fprintf(fid, '<td align="center"><a href="%s/%s"><img src="%s/%s" border="0" height="%d"/></a></td>\n', ...
                'image', imageFiles(j).name, 'image_thumb', imageFiles(j).name, thumbHeight);
        
        fprintf(fid, '<td></td>\n');
            
        % results
        for k = 1:nMethods
            fprintf(fid, '<td align="center"><a href="%s/%s/%s"><img src="%s/%s/%s" border="0" height="%d"/></a></td>\n', ...
                'segmentation', methods{k}, imageFiles(j).name, 'segmentation_thumb', methods{k}, imageFiles(j).name, thumbHeight);
            
            if k < nMethods
                fprintf(fid, '<td></td>\n');
            end
        end
        fprintf(fid, '</tr>\n');
        
        % image name
        [~,imageName] = fileparts(imageFiles(j).name);
        fprintf(fid, '<tr>\n');
        fprintf(fid, '<td align="center">');
        fprintf(fid, '%s\n', imageName);
        fprintf(fid, '</td>\n');
        fprintf(fid, '</tr>\n');
    end
    
    fprintf(fid, '</table>\n');
    fprintf(fid, '</body>\n');
    fprintf(fid, '</html>\n');
    fclose(fid);
end


%------------------------------------------------------------------
% Create the main webpage

fid = fopen(fullfile(outDir, 'index.html'), 'wt');
title = sprintf('%s', dataset);
writeHeader(fid, title);
fprintf(fid, '<body>\n');
fprintf(fid, '<table width="%d" border="0" align="center">\n', pageWidth);

% title
fprintf(fid, '<tr>\n');
fprintf(fid, '<td align="center">\n');
fprintf(fid, '<h1>%s</h1>\n', title);
fprintf(fid, '</td>\n');
fprintf(fid, '</tr>\n');

% methods
fprintf(fid, '<tr>\n');
fprintf(fid, '<td align="left">\n');
fprintf(fid, 'Methods: ');
for i = 1:nMethods
    fprintf(fid, '%s', methods{i});
    if i < nMethods
        fprintf(fid, ', ');
    end
end
fprintf(fid, '<p>&nbsp;</p>\n');
fprintf(fid, '</td>\n');
fprintf(fid, '</tr>\n');

% classes
fprintf(fid, '<tr>\n');
fprintf(fid, '<td align="left">\n');
for i = 1:nClasses
    fprintf(fid, '<a href="%s/index.html">%s</a><br>\n', classes{i}, classes{i});
end
fprintf(fid, '</td>\n');
fprintf(fid, '</tr>\n');

fprintf(fid, '</table>\n');
fprintf(fid, '</body>\n');
fprintf(fid, '</html>\n');
fclose(fid);



function writeHeader(fid, title)

fprintf(fid,'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n');
fprintf(fid,'<html xmlns="http://www.w3.org/1999/xhtml">\n');
fprintf(fid,'<head>\n');
fprintf(fid,'<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />\n');
fprintf(fid,sprintf('<title>%s</title>\n', title));
fprintf(fid,'</head>\n\n');


