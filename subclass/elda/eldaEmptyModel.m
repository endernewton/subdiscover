function model=eldaEmptyModel(size)
model.w        = zeros(size);
model.maxsize  = size(1:2);
model.interval = 10;
model.sbin     = 8;
model.thresh   = 0;
model.bg       = [];
fprintf('size = [%d %d %d]\n',size);
end
