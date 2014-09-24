function bbox = RefineBbxSED(img,bb,options)
% Modified July 19th, 2013

if nargin < 3
    options = [];
end

img = img(ceil(bb(2)):floor(bb(4)),ceil(bb(1)):floor(bb(3)),:);
% clear img

THRES = 0.99;
if isfield(options,'thresEdge')
    THRES = options.thresEdge;
end

h = size(img,1);
w = size(img,2);
% res = getSED(imresize(im,[100 100],'bicubic'));
res = max(imresize(getSED(img),[100,100],'bicubic'),0); % because of the approximation

if sum(res(:)) == 0
    bbox = bb;
    return;
end

res = res./(sum(res(:))+eps);

px = sum(res,2);
py = sum(res,1);

sum_x = sum(px.^2); % get the powers
sum_y = sum(py.^2);

% [~,idx_x] = sort(px,'descend');
% [~,idx_y] = sort(py,'descend');
% 
% center_x = idx_x(50); % take the pixel where the energy is median
% center_y = idx_y(50);

center_x = max(sum(cumsum(px.^2) < sum_x / 2),1);
center_y = max(sum(cumsum(py.^2) < sum_y / 2),1);

x1 = 0; x2 = 0;
while true
    s = 0;
    for i = center_x - x1 : center_x + x2
        s = s+ px(i)^2;
    end
    if s >= THRES*sum_x
        x_lim1 = center_x - x1;
        x_lim2 = center_x + x2;
        break;
    end
    if center_x - x1 < 2 && center_x + x2 > 99
        break;
    elseif center_x - x1 < 2
        x2 = x2 + 1;
    elseif center_x + x2 > 99
        x1 = x1 + 1;
    elseif px(center_x - x1 - 1) > px(center_x + x2 + 1)
        x1 = x1 + 1;
    else
        x2 = x2 + 1;
    end
end

x1 = 0; x2 = 0;
while true
    s = 0;
    for i = center_y - x1 : center_y + x2
        s = s+ py(i)^2;
    end
    if s >= THRES*sum_y
        y_lim1 = center_y - x1;
        y_lim2 = center_y + x2;
        break;
    end
    
    if center_y - x1 < 2 && center_y + x2 > 99
        break;
    elseif center_y - x1 < 2
        x2 = x2 + 1;
    elseif center_y + x2 > 99
        x1 = x1 + 1;
    elseif py(center_y - x1 - 1) > py(center_y + x2 + 1)
        x1 = x1 + 1;
    else
        x2 = x2 + 1;
    end
    
end

while true
    s = 0;
    for i = x_lim1+1:x_lim2
        s = s+ px(i)^2;
    end
    if s >= THRES*sum_x
        x_lim1 = x_lim1 + 1;
    else
        break;
    end
end

while true
    s = 0;
    for i = x_lim1:x_lim2-1
        s = s+ px(i)^2;
    end
    if s >= THRES*sum_x
        x_lim2 = x_lim2 - 1;
    else
        break;
    end
end

while true
    s = 0;
    for i = y_lim1+1:y_lim2
        s = s+ py(i)^2;
    end
    if s >= THRES*sum_y
        y_lim1 = y_lim1 + 1;
    else
        break;
    end
end

while true
    s = 0;
    for i = y_lim1:y_lim2-1
        s = s+ py(i)^2;
    end
    if s >= THRES*sum_y
        y_lim2 = y_lim2 - 1;
    else
        break;
    end
end

x_lim1 = (x_lim1*h/100) + bb(2);
x_lim2 = min((x_lim2*h/100) + bb(2),bb(4));
y_lim1 = (y_lim1*w/100) + bb(1);
y_lim2 = min((y_lim2*w/100) + bb(1),bb(3));

if length(bb) == 5 % the scores
    bbox = [y_lim1 x_lim1 y_lim2 x_lim2 bb(5)];
else
    bbox = [ceil(y_lim1) ceil(x_lim1) floor(y_lim2) floor(x_lim2)];
end

end