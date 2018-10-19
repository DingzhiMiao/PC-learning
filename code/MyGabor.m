%% HISTORY
% 2010.3.3 
    % 1. Created.
    % 2. 返回的grayscaleImageMatrix的值的范围是-1到1。
    % 3. 对比度contrast,空间频率spatial frequecy, 还有sigma已经调试正确。

% 2009.5.6
    % 1. 取消 param参数， 直接传入PixPerDeg。
    % 2. PixPerDeg可以是根据校正后的值，也可以是更精确的在某特定离心率下算出的值。 

% 2010.9.8
    %1. sigma=sigma/sqrt(2.3548); % don't know why
    %2. contrast is [0 100];
    
% 2011.4.19
%  1. 返回的grayscaleImageMatrix的值的范围是-1到1。

function grayscaleImageMatrix=MyGabor(pixPerDegree, xor, xextd, yor, yextd, contrast, cycPerDeg, sigma, phase, tiltInDegrees, locCx, locCy)

% *** To rotate the grating, set tiltInDegrees to a new value.
%tiltInDegrees = 7; % The tilt of the grating in degrees.
tiltInRadians = (-tiltInDegrees) * pi / 180; % The tilt of the grating in radians.
% actualWidth=20; %这里算时默认显示器为21 inch.所以半宽是20cm.
% PixPerDeg= params.rectWidth/(2*(atan(actualWidth/params.distance))*180/pi);  
% pixPerCyc=PixPerDeg/cycPerDeg;
% pixelsPerPeriod=pixPerCyc;
spatialFrequency=cycPerDeg/pixPerDegree;
sigma=sigma*pixPerDegree;  %原来sigma的单位是度,这里把它变成pixel.
% sigma=sigma*2.3548;
sigma=sigma/sqrt(2); % don't know why
% *** To lengthen the period of the grating, increase pixelsPerPeriod.
% pixelsPerPeriod = 1/spatialFrequency; % How many pixels will each period/cycle occupy?
% spatialFrequency = 1 / pixelsPerPeriod; % How many periods/cycles are
% there in a pixel?
radiansPerPixel = spatialFrequency * (2 * pi); % = (periods per pixel) * (2 pi radians per period)

% *** To enlarge the gaussian mask, increase periodsCoveredByOneStandardDeviation.
% The parameter "periodsCoveredByOneStandardDeviation" is approximately
% equal to
% the number of periods/cycles covered by one standard deviation of the radius of
% the gaussian mask.

%periodsCoveredByOneStandardDeviation = 1.5;

% The parameter "gaussianSpaceConstant" is approximately equal to the
% number of pixels covered by one standard deviation of the radius of
% the gaussian mask.

%gaussianSpaceConstant = periodsCoveredByOneStandardDeviation  * pixelsPerPeriod;
% 

% *** If the grating is clipped on the sides, increase widthOfGrid.
% widthOfGrid = xextd-xor+1;
% heightOfGrid = yextd-yor+1;
% halfWidthOfGrid = ceil(widthOfGrid / 2);
% halfHeightOfGrid = ceil(heightOfGrid / 2);

x0=locCx-xor;
y0=locCy-yor;
x1=xextd-locCx;
y1=yextd-locCy;
widthArray = -x0:x1; 
heightArray=-y0:y1;  % widthArray is used in creating the meshgrid.

% ---------- Image Setup ----------
	% Stores the image in a two dimensional matrix.

	% Creates a two-dimensional square grid.  For each element i = i(x0, y0) of
	% the grid, x = x(x0, y0) corresponds to the x-coordinate of element "i"
	% and y = y(x0, y0) corresponds to the y-coordinate of element "i"
	[x y] = meshgrid(widthArray, heightArray);
    
    % Replaced original method of changing the orientation of the grating
    % (gradient = y - tan() .* x) with sine and cosine (adapted from DriftDemo). 
    % Use of tangent was breakable because it is undefined for theta near pi/2 and the period
    % of the grating changed with change in theta.  

    a=cos(tiltInRadians)*radiansPerPixel;
	b=sin(tiltInRadians)*radiansPerPixel;
	 
	% Converts meshgrid into a sinusoidal grating, where elements
	% along a line with angle theta have the same value and where the
	% period of the sinusoid is equal to "pixelsPerPeriod" pixels.
	% Note that each entry of gratingMatrix varies between minus one and
	% one; -1 <= gratingMatrix(x0, y0)  <= 1
    gratingMatrix = sin(a*x+b*y+phase/180*pi);
    
	 
	% Creates a circular Gaussian mask centered at the origin, where the number
	% of pixels covered by one standard deviation of the radius is
	% approximately equal to "gaussianSpaceConstant."
	% For more information on circular and elliptical Gaussian distributions, please see
	% http://mathworld.wolfram.com/GaussianFunction.html
	% Note that since each entry of circularGaussianMaskMatrix is "e"
	% raised to a negative exponent, each entry of
	% circularGaussianMaskMatrix is one over "e" raised to a positive
	% exponent, which is always between zero and one;
	% 0 < circularGaussianMaskMatrix(x0, y0) <= 1
	circularGaussianMaskMatrix = exp(-((x .^ 2) + (y .^ 2)) / (sigma ^ 2));
	 
	% Since each entry of gratingMatrix varies between minus one and one and each entry of
	% circularGaussianMaskMatrix vary between zero and one, each entry of
	% imageMatrix varies between minus one and one.
	% -1 <= imageMatrix(x0, y0) <= 1
	imageMatrix = gratingMatrix .* circularGaussianMaskMatrix; % imageMatrix 的范围是-1到1；
	 
	% Since each entry of imageMatrix is a fraction between minus one and
	% one, multiplying imageMatrix by absoluteDifferenceBetweenWhiteAndGray
	% and adding the gray CLUT color code baseline
	% converts each entry of imageMatrix into a shade of gray:
	% if an entry of "m" is minus one, then the corresponding pixel is black;
	% if an entry of "m" is zero, then the corresponding pixel is gray;
	% if an entry of "m" is one, then the corresponding pixel is white.
    
    
%     gray=params.gray;
%     absoluteDifferenceBetweenWhiteAndGray=params.inc*contrast;
%     
% 	grayscaleImageMatrix = gray + absoluteDifferenceBetweenWhiteAndGray * imageMatrix;
grayscaleImageMatrix=imageMatrix*contrast/100;   % grayscaleImageMatrix的范围是-1到1。
    

    
    