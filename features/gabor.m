function [evenFilter,oddFilter] = gabor( wavelength, angle, kx, ky )
%GARBOR Summary of this function goes here
%   Detailed explanation goes here

    sigmax = wavelength*kx;
    sigmay = wavelength*ky;
    
    sze = round(3*max(sigmax,sigmay));
    [x,y] = meshgrid(-sze:sze);
    evenFilter = exp(-(x.^2/sigmax^2 + y.^2/sigmay^2)/2)...
	     .*cos(2*pi*(1/wavelength)*x);
    
    oddFilter = exp(-(x.^2/sigmax^2 + y.^2/sigmay^2)/2)...
	     .*sin(2*pi*(1/wavelength)*x);    

    evenFilter = imrotate(evenFilter, angle, 'bilinear');
    oddFilter = imrotate(oddFilter, angle, 'bilinear');   

end

