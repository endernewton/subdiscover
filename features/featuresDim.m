function dim=featuresDim(fname, inc)
% globals;

switch fname
    case 'HOG'
        dim = 31;
    case 'CHOG'
        dim = 42;
end

if nargin == 2
    dim = dim + inc;
end

end
