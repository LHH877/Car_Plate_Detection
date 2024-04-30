clc
clear;
% Image input and Preprocessing---------------------------------------------------------------

% Load the car plate image
carPlate = imread('CarYellow1.png');

% Smooth the image using Gaussian filtering
smoothedPlate = imgaussfilt(carPlate, 0.5); 
figure, 
subplot(121),imshow(carPlate), title("originalImage");
subplot(122),imshow(smoothedPlate), title("smoothImage");

% Search for yellow pixels------------------------------------------------------------------------------

% Convert the image to HSV color space
hsvPlate = rgb2hsv(smoothedPlate);

figure, 
subplot(121),imshow(smoothedPlate), title("smoothImage");
subplot(122),imshow(hsvPlate), title("hsvPlate");

% Extract the hue, saturation, and value channels
hueChannel = hsvPlate(:,:,1);
saturationChannel = hsvPlate(:,:,2);
valueChannel = hsvPlate(:,:,3);

% Define the ranges for yellow color in HSV space
yellowHueRange = [15/180, 35/180]; % Adjust Hue
yellowSaturationRange = [0, 1]; % Adjust Saturation
yellowValueRange = [0, 1]; % Adjust Value


% Define the ranges for black color in HSV space
%blackHueRange = [0, 1]; % Adjust Hue
%blackSaturationRange = [0, 0.1]; % Adjust Saturation
%blackValueRange = [0, 0.1]; % Adjust Value

% Create binary masks for yellow regions based on hue, saturation, and value
hueMask = (hueChannel >= yellowHueRange(1)) & (hueChannel <= yellowHueRange(2));
saturationMask = (saturationChannel >= yellowSaturationRange(1)) & (saturationChannel <= yellowSaturationRange(2));
valueMask = (valueChannel >= yellowValueRange(1)) & (valueChannel <= yellowValueRange(2));

% Combine the masks
yellowMask_hsv = hueMask & saturationMask & valueMask;


% Set pixels within the yellow range to white (255) and pixels outside the range to black (0)
yellowBinary_hsv = yellowMask_hsv * 255; % Convert logical values to uint8 (0 or 255)

% Display the yellow binary image
figure, 
subplot(121),imshow(hsvPlate), title("hsvPlate");
subplot(122),imshow(yellowBinary_hsv), title("yellowBinary hsv");

% Remove noise and specify ROI ------------------------------------------------------------------------------

% Remove white patches connected to the border
cleanedBinaryEdge_hsv = imclearborder(yellowBinary_hsv);
figure;
imshow(cleanedBinaryEdge_hsv);
title('cleanedBinaryHsvEdge');
figure, 
subplot(121),imshow(yellowBinary_hsv), title("yellowBinary hsv");
subplot(122),imshow(cleanedBinaryEdge_hsv), title("cleanedBinaryHsvEdge");


% Remove small regions in the binary image (other than the plate region)
minRegionSize = 1500; % Adjust 
cleanedBinarySmall_hsv = bwareaopen(cleanedBinaryEdge_hsv, minRegionSize);

figure, 
subplot(121),imshow(cleanedBinaryEdge_hsv), title("cleanedBinaryHsvEdge");
subplot(122),imshow(cleanedBinarySmall_hsv), title("cleanedBinaryHsvSmall");


% Crop out ROI --------------------------------------------------------------------------------
% Find connected components in the binary image
cc = bwconncomp(cleanedBinarySmall_hsv);

% Get properties of connected components
stats = regionprops(cc, 'BoundingBox');

% Extract bounding box of the largest connected component (assumed to be the number plate)
largestBoundingBox = stats.BoundingBox;

% Convert the bounding box to integer coordinates
x = floor(largestBoundingBox(1));
y = floor(largestBoundingBox(2));
width = ceil(largestBoundingBox(3));
height = ceil(largestBoundingBox(4));

% Extract the number plate region using the bounding box coordinates
plateExtracted_bbox = smoothedPlate(y:y+height, x:x+width, :);

% Display the extracted number plate using bounding box from the smoothed image
figure, 
subplot(121),imshow(cleanedBinarySmall_hsv), title("cleanedBinaryHsvSmall");
subplot(122),imshow(plateExtracted_bbox), title("plateExtracted_bbox");
% Preprocessing for OCR ------------------------------------------------------------------------------

% Convert the cropped plate region to grayscale
plateGray = rgb2gray(plateExtracted_bbox);
% Apply adaptive thresholding to convert the grayscale image to binary
binaryPlate = imbinarize(plateGray);

% Specify the scaling factor
scalingFactor = 1.5;
% Resize the image
resizedImage = imresize(binaryPlate, scalingFactor);

figure, 
subplot(221),imshow(plateExtracted_bbox), title("plateExtracted_bbox");
subplot(222),imshow(plateGray), title("Gray Plate Image");
subplot(223),imshow(binaryPlate), title("Binary Plate Image");
subplot(224),imshow(resizedImage), title("Resized Image");

% Perform OCR-----------------------------------------------------------------------------

% Perform OCR with custom options
results = ocr(resizedImage)

% Display the recognized text
recognizedText = results.Text;
disp('Recognized Text:');
disp(recognizedText);



