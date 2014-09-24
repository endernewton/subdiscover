function [pick,index,area] = NmsIdx(boxes, overlap)
% top = nms_fast(boxes, overlap)
% Non-maximum suppression. (FAST VERSION)
% Greedily select high-scoring detections and skip detections
% that are significantly covered by a previously selected
% detection.
% NOTE: This is adapted from Pedro Felzenszwalb's version (nms.m),
% but an inner loop has been eliminated to significantly speed it
% up in the case of a large number of boxes
% Tomasz Maliseiwicz (tomasz@cmu.edu)
% Modified by Xinlei Chen xinleic@cs.cmu.edu

if isempty(boxes)
  pick = [];
  index = [];
  area = [];
  return;
end

x1 = boxes(:,1);
y1 = boxes(:,2);
x2 = boxes(:,3);
y2 = boxes(:,4);
s = boxes(:,end);

index = zeros(size(boxes,1),1);
area = (x2-x1+1) .* (y2-y1+1);

[~, I] = sort(s);

pick = s*0;
counter = 1;
while ~isempty(I)
  
  last = length(I);
  i = I(last);  
  pick(counter) = i;
  index(i) = i;
  
  xx1 = max(x1(i), x1(I(1:last-1)));
  yy1 = max(y1(i), y1(I(1:last-1)));
  xx2 = min(x2(i), x2(I(1:last-1)));
  yy2 = min(y2(i), y2(I(1:last-1)));
  
  w = max(0.0, xx2-xx1+1);
  h = max(0.0, yy2-yy1+1);
  
  s = w.*h;
  o = s./(area(I(1:last-1)));
  
  idx = o > overlap;
%   disp(idx);
  index(I([last; find(idx)])) = i;
  
  I([last; find(idx)]) = [];
  counter = counter + 1;
end

pick = pick(1:(counter-1));

end
