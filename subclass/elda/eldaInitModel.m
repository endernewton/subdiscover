function model = eldaInitModel(pos, bg, fname)

% model = initmodel(name, pos, bg)
% Initialize model structure.
% model.maxsize = [y,x] size of root filter in HOG cells
% model.len     = length of weight vector
% model.filters(i)
%  .w  = 8x8xf filter
%  .i = starting index in final weight vector
% model.defs(i)
%  .w      = 5x1 deformation parameters (x x^2 y y^2 bias)
%  .i     = starting index in weight vector
%  .anchor = 3x1 array of relative x, y, and scale of part wrt parent
% model.components{j}{k}
%  .filterid = (pointer to filter)
%  .defid    = (pointer to deformation)
%  .parent   = (pointer to parent node)

% pick mode of aspect ratios
h = [pos(:).y2]' - [pos(:).y1]' + 1;
w = [pos(:).x2]' - [pos(:).x1]' + 1;

xx = -2:.02:2;
filter = exp(-[-100:100].^2/400);
aspects = hist(log(double(h)./double(w)), xx);
aspects = convn(aspects, filter, 'same');
[~, I] = max(aspects);
aspect = exp(xx(I));
%pause;

% pick 20 percentile area
mean(h);
mean(w);
areas = sort(h.*w);
area = areas(max(floor(length(areas) * 0.2),1));
area = max(min(area, 7000), 5000);
%pause;
sbin = bg.sbin;

% pick dimensions
w  = sqrt(double(area)/aspect);
h  = w*aspect;

nf   = length(featuresWrapper(zeros([3 3 3]),1,fname));
size = [round(h/sbin) round(w/sbin) nf];
size = max(size,1);

% initialize the rest of the model structure
model.w        = zeros(size);
model.maxsize  = size(1:2);
model.interval = 10;
model.sbin     = sbin;
model.thresh   = 0;
model.nthresh   = 0;
model.bg       = bg;
model.bg.lambda=0.01;
model.bg;
model.saliency = 0;
end
