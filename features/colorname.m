function cn_blocks=colorname(im,sbin)
% load w2c       % load the RGB to color name matrix
persistent w2c;

if isempty(w2c)
    load('w2c');
end

theWhole = im2c(im,w2c,-2); 

if nargin == 2
    cn_blocks = featavg(theWhole, sbin);
else
    cn_blocks = theWhole;
end

end





















 
