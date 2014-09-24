function pyra = featpyramidPadder(im, models, pad, fname, flip)
% pyra = featpyramid(im, model, padx, pady);
% Compute feature pyramid.
%
% pyra.feat{i} is the i-th level of the feature pyramid.
% pyra.scales{i} is the scaling factor used for the i-th level.
% pyra.feat{i+interval} is computed at exactly half the resolution of feat{i}.
% first octave halucinates higher resolution data.

% These two parameters should be the same

if (flip == 1)
    im = flip_image(im);
end

interval  = models{1}.interval;
sbin = models{1}.sbin;

% Select padding, allowing for one cell in model to be visible
% Even padding allows for consistent spatial relations across 2X scales

% sizesx = cellfun(@(x)x.maxsize(2),models);
% sizesy = cellfun(@(x)x.maxsize(1),models);
% sizesx = reshape(sizesx,[],1);
% sizesy = reshape(sizesy,[],1);

padx = pad;
pady = pad;

% padx = max(models.maxsize(2)-1-1,0);
% pady = max(models.maxsize(1)-1-1,0);
%padx = model.maxsize(2);
%pady = model.maxsize(1);

% padx = ceil(padx/2)*2;
% pady = ceil(pady/2)*2;

sc = 2 ^(1/interval);
imsize = [size(im, 1) size(im, 2)];
% if size(im,3) == 1
%     im = repmat(im,[1,1,3]);
% end

max_scale = 1 + floor(log(min(double(imsize))/(double(5*sbin)))/log(sc));
pyra.feat  = cell(max_scale + interval, 1);
pyra.scale = zeros(max_scale + interval, 1);
% our resize function wants floating point values
im = double(im);
for i = 1:interval
    scaled = resize(im, 1/sc^(i-1));
    % "first" 2x interval
    pyra.feat{i} = featuresWrapper(scaled, sbin/2, fname);
    pyra.scale(i) = 2/sc^(i-1);
    % "second" 2x interval
    pyra.feat{i+interval} = featuresWrapper(scaled, sbin, fname);
    pyra.scale(i+interval) = 1/sc^(i-1);
    % remaining interals
    for j = i+interval:interval:max_scale
        scaled = reduce(scaled);
        pyra.feat{j+interval} = featuresWrapper(scaled, sbin, fname);
        pyra.scale(j+interval) = 0.5 * pyra.scale(j);
    end
end

for i = 1:length(pyra.feat)
    % add 1 to padding because feature generation deletes a 1-cell
    % wide border around the feature map
    pyra.feat{i} = mypadarray(pyra.feat{i}, [pady+1 padx+1 0], 0);
    % write boundary occlusion feature
    pyra.feat{i}(1:pady+1, :, end) = 1;
    pyra.feat{i}(end-pady:end, :, end) = 1;
    pyra.feat{i}(:, 1:padx+1, end) = 1;
    pyra.feat{i}(:, end-padx:end, end) = 1;
end

pyra.scale    = sbin./pyra.scale;
pyra.interval = interval;
pyra.imy = imsize(1);
pyra.imx = imsize(2);
pyra.pady = pady;
pyra.padx = padx;
pyra.sbin = sbin;
pyra.interval = interval;

end

function newf=mypadarray(f, amt, val)
newsize=size(f)+2*amt;
startpos=amt+1;
endpos=startpos+size(f)-1;
newf=val*ones(newsize);
newf(startpos(1):endpos(1), startpos(2):endpos(2), startpos(3):endpos(3))=f;
end
