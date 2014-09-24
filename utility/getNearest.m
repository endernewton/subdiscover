function idx = getNearest( datapoints, centers )
%GETNEAREST by Ender, xinleic
%   rows as data points

% opts.distance = 'euclidean';
centers = centers';
centerssq = sum(centers.^2, 1);

l = size(datapoints,1);
idx = zeros(l,1);
for i=1:l
    dist = centerssq - 2*datapoints(i, :) * centers;
    [~,idx(i)] = min(dist);
end

end

