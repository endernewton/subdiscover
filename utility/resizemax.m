function img = resizemax( img, maxsize )
%RESIZEMAX by Ender, xinleic@cs.cmu.edu
% Resize an image so that the biggest length of an edge is maxsize

sizeI = size(img);
sizeI = sizeI(1:2);

ratio = maxsize / max(sizeI);
img = imresize(img, ratio, 'cubic');

end

