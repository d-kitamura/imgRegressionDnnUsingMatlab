function [X, T] = imds2array(imds)
% imds2array Convert an image datastore into a 4-D array
%
% X - Input data as an H-by-W-by-C-by-N array, where H is the
% height and W is the width of the images, C is the number of
% channels, and N is the number of images.
% T - Categorical vector containing the labels for each
% observation.
% Copyright 2016 The MathWorks, Inc.
imagesCellArray = imds.readall();
numImages = numel( imagesCellArray );
[h, w, c] = size( imagesCellArray{1} );
X = zeros( h, w, c, numImages );
for i=1:numImages
X(:,:,:,i) = im2double( imagesCellArray{i} );
end
T = imds.Labels;
end