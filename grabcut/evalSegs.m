function ratop = evalSegs(segs,bbox)
r1 = segs([bbox(2),bbox(4)],bbox(1):bbox(3));
r2 = segs(bbox(2):bbox(4),[bbox(1),bbox(3)]);
r = [r1(:);r2(:)];
ratop = sum(r) / length(r);
end