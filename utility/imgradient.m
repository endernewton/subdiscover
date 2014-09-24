function [Gmag, Gdir] = imgradient(varargin)
%IMGRADIENT Find the gradient magnitude and direction of an image.
%   [Gmag, Gdir] = IMGRADIENT(I) takes a grayscale or binary image I as
%   input and returns the gradient magnitude, Gmag, and the gradient
%   direction, Gdir. Gmag and Gdir are the same size as the input image I.
%   Gdir contains angles in degrees within the range [-180 180] measured
%   counterclockwise from the positive X axis (X axis points in the
%   direction of increasing column subscripts).
%
%   [Gmag, Gdir] = IMGRADIENT(I, METHOD) calculates the gradient magnitude
%   and direction using the specified METHOD. Supported METHODs are:
%
%       'Sobel'                 : Sobel gradient operator (default)
%
%       'Prewitt'               : Prewitt gradient operator
%
%       'CentralDifference'     : Central difference gradient dI/dx = (I(x+1)- I(x-1))/ 2
%
%       'IntermediateDifference': Intermediate difference gradient dI/dx = I(x+1) - I(x)
% 
%       'Roberts'               : Roberts gradient operator
%
%   [Gmag, Gdir] = IMGRADIENT(Gx, Gy) calculates the gradient magnitude and
%   direction from the directional gradients along the X axis, Gx, and
%   Y axis, Gy, such as that returned by IMGRADIENTXY. X axis points in the
%   direction of increasing column subscripts and Y axis points in the
%   direction of increasing row subscripts.
% 
%   Class Support 
%   ------------- 
%   The input image I and the input directional gradients Gx and Gy can be
%   numeric or logical two-dimensional matrices, and they must be
%   nonsparse. Both Gmag and Gdir are of class double in all cases, except
%   when the input image I or either one or both of the directional
%   gradients Gx and Gy is of class single. In that case Gmag and Gdir will
%   be of class single.
%
%   Notes
%   -----
%   1. When applying the gradient operator at the boundaries of the image,
%      values outside the bounds of the image are assumed to equal the
%      nearest image border value. This is similar to the 'replicate'
%      boundary option in IMFILTER.
% 
%   Example 1
%   ---------
%   This example computes and displays the gradient magnitude and direction
%   of the image coins.png using Prewitt's gradient operator.
%
%   I = imread('coins.png');
%   imshow(I)
%   
%   [Gmag, Gdir] = imgradient(I,'prewitt');
% 
%   figure, imshow(Gmag, []), title('Gradient magnitude')
%   figure, imshow(Gdir, []), title('Gradient direction')
%
%   Example 2
%   ---------
%   This example computes and displays both the directional gradients and the
%   gradient magnitude and gradient direction for the image coins.png.
%
%   I = imread('coins.png');
%   imshow(I)
%   
%   [Gx, Gy] = imgradientxy(I);
%   [Gmag, Gdir] = imgradient(Gx, Gy);
% 
%   figure, imshow(Gmag, []), title('Gradient magnitude')
%   figure, imshow(Gdir, []), title('Gradient direction')
%   figure, imshow(Gx, []), title('Directional gradient: X axis')
%   figure, imshow(Gy, []), title('Directional gradient: Y axis')
%
%   See also EDGE, FSPECIAL, IMGRADIENTXY.

% Copyright 2012 The MathWorks, Inc. 
% $Revision: 1.1.6.2.2.1 $ $Date: 2012/06/27 13:58:08 $

% narginchk(1,2);

[I, Gx, Gy, method] = parse_inputs(varargin{:});

% Compute directional gradients
if (isempty(I))     
    % Gx, Gy are given as inputs
    if ~isfloat(Gx)
        Gx = double(Gx);
    end
    if ~isfloat(Gy)
        Gy = double(Gy);
    end
    
else   
    % If Gx, Gy not given, compute them. For all others except Roberts
    % method, use IMGRADIENTXY to compute Gx and Gy. 
    if (strcmpi(method,'roberts'))        
        if ~isfloat(I)
            I = double(I);
        end
        Gx = imfilter(I,[1 0; 0 -1],'replicate');         
        Gy = imfilter(I,[0 1; -1 0],'replicate'); 
        
    else        
        [Gx, Gy] = imgradientxy(I,method);
        
    end
end

% Compute gradient magnitude
Gmag = hypot(Gx,Gy);

% Compute gradient direction
if (nargout > 1)
    if (strcmpi(method,'roberts'))
        
        Gdir = zeros(size(Gx));
        
        % For pixels with zero gradient (both Gx and Gy zero), Gdir is set
        % to 0. Compute direction only for pixels with non-zero gradient.
        xyNonZero = ~((Gx == 0) & (Gy == 0)); 
        Gdir(xyNonZero) = atan2(Gy(xyNonZero),-Gx(xyNonZero)) - (pi/4);
        Gdir(Gdir < -pi) = Gdir(Gdir < -pi) + 2*pi; % To account for the discontinuity at +-pi.
        
        Gdir = Gdir*180/pi; % Radians to degrees
        
    else
        
        Gdir = atan2(-Gy,Gx)*180/pi; % Radians to degrees
    end    
end

end
%======================================================================
function [I, Gx, Gy, method] = parse_inputs(varargin)

methodstrings = {'sobel','prewitt','roberts','centraldifference', ...
            'intermediatedifference'};
I = []; 
Gx = []; 
Gy = [];
method = 'sobel'; % Default method

if (nargin == 1)
    I = varargin{1};
    validateattributes(I,{'numeric','logical'},{'2d','nonsparse','real'}, ...
                       mfilename,'I',1);
        
else % (nargin == 2)
    if ischar(varargin{2})
        I = varargin{1};
        validateattributes(I,{'numeric','logical'},{'2d','nonsparse', ...
                           'real'},mfilename,'I',1);
        method = validatestring(varargin{2}, methodstrings, ...
            mfilename, 'Method', 2);
    else
        Gx = varargin{1};
        Gy = varargin{2}; 
        validateattributes(Gx,{'numeric','logical'},{'2d','nonsparse', ...
                           'real'},mfilename,'Gx',1);
        validateattributes(Gy,{'numeric','logical'},{'2d','nonsparse', ...
                           'real'},mfilename,'Gy',2);
        if (~isequal(size(Gx),size(Gy)))
            error(message('images:validate:unequalSizeMatrices','Gx','Gy'));
        end
    end
         
end

end
%----------------------------------------------------------------------


