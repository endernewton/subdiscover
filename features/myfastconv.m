function [res, resch] = myfastconv(feat, filters, stNumFilt, enNumFilt)
% feat : 3D array
% filters : cell array
% stNumFilt : starting index of filter to apply
% enNumFilt : ending index of filter to apply

if nargin<3
  stNumFilt = 1;
  enNumFilt = numel(filters);
end
numFilters = enNumFilt-stNumFilt+1;

if ~ippl %IPP library not present, use fconv_var_dim in vanila form...
  res = fconv_var_dim(feat, filters, stNumFilt, enNumFilt);
else
  res = cell(1, numFilters);
  resch = cell(1, numFilters);
  for p = stNumFilt:enNumFilt
    filt = filters{p};
    tmp = zeros(size(feat));
    for ch=1:size(feat, 3)
      tmp(:,:,ch) = imfilter(double(feat(:,:,ch)), double(filt(:,:,ch)));
    end
    fz = size(filt);
    sti = ceil(fz(1)/2);
    eni = size(feat, 1) - floor(fz(1)/2);
    stj = ceil(fz(2)/2);
    enj = size(feat, 2) - floor(fz(2)/2);
    res{p} = sum(tmp(sti:eni, stj:enj, :),3);
    resch{p} = tmp;
  end
end
