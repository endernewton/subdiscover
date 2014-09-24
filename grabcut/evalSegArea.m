function ratop = evalSegArea(segs,bbox)
area = segs(bbox(2):bbox(4),bbox(1):bbox(3));
area = area(:);
ratop = sum(area) / numel(area);
end