function warped = eldaWarpPos(model, pos)
% warped = warppos(name, model, pos)
% Warp positive examples to fit model dimensions.
% Used for training root filters from positive bounding boxes.
siz = size(model.w);
siz = siz(1:2);
pixels = double(siz * model.sbin);
heights = double([pos(:).y2]' - [pos(:).y1]' + 1);
widths = double([pos(:).x2]' - [pos(:).x1]' + 1);
numpos = length(pos);
cropsize = (siz+2) * model.sbin;
% minsize = prod(pixels);
warped  = {};
lastreadimg='';
for i = 1:numpos
%  fprintf('%s: warp: %d/%d\n', name, i, numpos);
  % skip small examples
  %if widths(i)*heights(i) < minsize
  %  continue
  %end
  if(~strcmp(pos(i).im, lastreadimg))	    
  	im = imread(pos(i).im);
    if size(im,3) == 1
        im = repmat(im,[1,1,3]);
    end
	lastreadimg=pos(i).im;
  end
  padx = model.sbin * widths(i) / pixels(2);
  pady = model.sbin * heights(i) / pixels(1);
  x1 = round(double(pos(i).x1)-padx);
  x2 = round(double(pos(i).x2)+padx);
  y1 = round(double(pos(i).y1)-pady);
  y2 = round(double(pos(i).y2)+pady);
%  pos(i).y1
  window = eldasubarray(im, y1, y2, x1, x2, 1);
  warped{end+1} = imresize(window, cropsize, 'bilinear');
end

if numpos == 1,
  assert(~isempty(warped));
end

function B = eldasubarray(A, i1, i2, j1, j2, pad)

% B = subarray(A, i1, i2, j1, j2, pad)
% Extract subarray from array
% pad with boundary values if pad = 1
% pad with zeros if pad = 0

dim = size(A);
%i1
%i2
is = i1:i2;
js = j1:j2;

if pad,
  is = max(is,1);
  js = max(js,1);
  is = min(is,dim(1));
  js = min(js,dim(2));
  B  = A(is,js,:);
else
  % todo
end

