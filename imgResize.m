function [outImg] = imgResize(img,outRow,outCol,isConvertGray,method,extrapval)
% resizeImg: 画像のリサイズ
% 入力された画像（img）をoutRow行outCol列のサイズにリサイズ
%
% [Syntax]
%   [outImg] = imgResize(img,outRow,outCol,isConvertGray)
%   [outImg] = imgResize(img,outRow,outCol,isConvertGray,method)
%   [outImg] = imgResize(img,outRow,outCol,isConvertGray,method,extrapval)
%
% [Input]
%           img: input image (integer or double, inRow x inCol x inCh x nData)
%        outRow: number of rows of resized image (integer, scalar)
%        outCol: number of columns of resized image (integer, scalar)
% isConvertGray: converge image to gray or not (logical, default: false)
%        method: method of interpolation (string, default: linear)
%                "linear", "nearest", "cubic", "makima", or "spline"
%                See "doc interp3"
%     extrapval: value of extrapolation for interp3 (integer or double, scalar, default: 0)
%                See "doc interp3"
%
% [Output]
%        outImg: resized image (double, outRow x outCol x outCh x nData)
%

arguments % 引数検証
    img double
    outRow (1,1) {mustBeInteger}
    outCol (1,1) {mustBeInteger}
    isConvertGray (1,1) = false
    method string = "linear"
    extrapval (1,1) = 0
end

[inRow, inCol, inCh, nData] = size(img); % inRow: リサイズ前の行，inCol: リサイズ前の列，inCh: 色，nData: 画像数
if isConvertGray
    outCh = 1;
else
    outCh = inCh;
end

% リサイズ前のメッシュ（X, Y, Z）とリサイズ後のメッシュ（Xi, Yi, Zi）を作成
[X, Y, Z] = meshgrid(1:inCol, 1:inRow, 1:inCh);
xi = linspace(1, inCol, outCol); 
yi = linspace(1, inRow, outRow); 
zi = 1:1:outCh;
[Xi, Yi, Zi] = meshgrid(xi, yi, zi);

% 内挿（interp3）による画像リサイズ
outImg = zeros(outRow, outCol, outCh, nData);
for iData = 1:nData
    outImg(:,:,:,iData) = interp3(X, Y, Z, img(:,:,:,iData), Xi, Yi, Zi, method, extrapval);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EOF %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%