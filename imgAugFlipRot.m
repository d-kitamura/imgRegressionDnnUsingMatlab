function [augImg,augLabel] = imgAugFlipRot(img,label,isFlip,isRot)
% imgAugFlipRot: 画像用のデータ拡張
% 入力された画像（img）とそのラベル（label）に(1) 上下反転，(2) 左右反転，
% (3) 90・180・270度回転の3種類の任意の変形を加えデータ数を拡張
% 　(1)のみ又は(2)のみ：データ数を2倍に拡張
%   (1)と(2)：データ数を4倍に拡張
% 　(3)のみ：データ数を4倍に拡張
% 　(1)と(3)，(2)と(3)，又は(1)～(3)全て：データ数を8倍に拡張（全て同じ結果）
% いずれのデータ拡張においても，処理後の返り値は変形前の元画像を含む点に注意
%
% [Syntax]
%   [augImg,augLabel] = imgAugFlipRot(img,label)
%   [augImg,augLabel] = imgAugFlipRot(img,label,isFlip)
%   [augImg,augLabel] = imgAugFlipRot(img,label,isFlip,isRot)
%
% [Input]
%       img: input images (double, row x col x ch x nData)
%     label: labels of each image (categorical or double, nData x 1)
%    isFlip: apply augmentation using up-down or/and left-right flipping (integer, 0: no flipping, 1: up-down and left-right filpping, 2: up-down flipping, 3: left-right flipping, default: 1)
%     isRot: apply augmentation using 90, 180, 270 degree rotation (logical, default: true)
%
% [Output]
%    augImg: augmented images (double, row x col x ch x nAugData)
%  augLabel: labels for augmented images (categorical or double, nAugData x 1)
%

arguments % 引数検証
    img (:,:,:,:) double
    label (:,1) double
    isFlip (1,1) {mustBeInteger} = 1
    isRot (1,1) logical = true
end

if isFlip ~= 0 && ~isRot % flipのみ（左右反転のみ又は上下反転のみで2倍に拡張，左右反転と上下反転の両方で4倍に拡張）
    [augImg, augLabel] = onlyFlip_local(img, label, isFlip);
elseif isFlip == 0 && isRot % rotのみ，90・180・270度回転で4倍に拡張
    [augImg, augLabel] = onlyRot_local(img,label);
elseif isFlip ~= 0 && isRot % flipとrot，反転前画像と左右反転画像のそれぞれに90・180・270度回転して8倍に拡張
    [augImg, augLabel] = flipRot_local(img,label);
else
    augImg = img;
    augLabel = label;
    warning("No augmentation is requested. Nothing processed in 'imgAugFlipRot'.\n");
end
end

%% Local functions
function [augImg,augLabel] = onlyFlip_local(img,label,isFlip)
[row, col, ch, nData] = size(img); % row: 行，col: 列，ch: 色，nData: 画像数
if isFlip == 1 % 左右反転と上下反転の両方を適用
    augImg = zeros(row, col, ch, 4*nData);
    augImg(:,:,:,1:nData) = img; % 元画像をストア
    for iData = 1:nData
        augImg(:,:,:,nData+iData) = fliplr(augImg(:,:,:,iData)); % 左右反転
        augImg(:,:,:,2*nData+iData) = flipud(augImg(:,:,:,iData)); % 上下反転
        augImg(:,:,:,3*nData+iData) = flipud(augImg(:,:,:,nData+iData)); % 上下左右反転
    end
    augLabel = repmat(label, [4,1]); % ラベルをコピー
elseif isFlip == 2 % 上下反転のみを適用
    augImg = zeros(row, col, ch, 2*nData);
    augImg(:,:,:,1:nData) = img; % 元画像をストア
    for iData = 1:nData
        augImg(:,:,:,nData+iData) = flipud(augImg(:,:,:,iData)); % 上下反転
    end
    augLabel = repmat(label, [2,1]); % ラベルをコピー
elseif isFlip == 3 % 左右反転のみを適用
    augImg = zeros(row, col, ch, 2*nData);
    augImg(:,:,:,1:nData) = img; % 元画像をストア
    for iData = 1:nData
        augImg(:,:,:,nData+iData) = fliplr(augImg(:,:,:,iData)); % 左右反転
    end
    augLabel = repmat(label, [2,1]); % ラベルをコピー
else
    error("Input argument 'isFlip' must be 0, 1, or 2.\n");
end
end

function [augImg,augLabel] = onlyRot_local(img,label)
[row, col, ch, nData] = size(img); % row: 行，col: 列，ch: 色，nData: 画像数
augImg = zeros(row, col, ch, 4*nData);
augImg(:,:,:,1:nData) = img; % 元画像をストア
for iData = 1:nData
    augImg(:,:,:,nData+iData) = rot90(augImg(:,:,:,iData), 1); % 反転前画像を反時計回りに90度回転
    augImg(:,:,:,2*nData+iData) = rot90(augImg(:,:,:,iData), 2); % 反転前画像を反時計回りに180度回転
    augImg(:,:,:,3*nData+iData) = rot90(augImg(:,:,:,iData), 3); % 左右反転画像を反時計回りに270度回転
end
augLabel = repmat(label, [4,1]); % ラベルをコピー
end

function [augImg,augLabel] = flipRot_local(img,label)
[row, col, ch, nData] = size(img); % row: 行，col: 列，ch: 色，nData: 画像数
augImg = zeros(row, col, ch, 8*nData);
augImg(:,:,:,1:nData) = img; % 元画像をストア
for iData = 1:nData
    augImg(:,:,:,nData+iData) = fliplr(augImg(:,:,:,iData)); % 左右反転（上下反転も用意すると回転により画像が重複する，左右反転と回転だけで網羅される）
end
for iData = 1:nData
    augImg(:,:,:,2*nData+iData) = rot90(augImg(:,:,:,iData), 1); % 反転前画像を反時計回りに90度回転
    augImg(:,:,:,3*nData+iData) = rot90(augImg(:,:,:,iData), 2); % 反転前画像を反時計回りに180度回転
    augImg(:,:,:,4*nData+iData) = rot90(augImg(:,:,:,iData), 3); % 反転前画像を反時計回りに270度回転
    augImg(:,:,:,5*nData+iData) = rot90(augImg(:,:,:,nData+iData), 1); % 左右反転画像を反時計回りに90度回転
    augImg(:,:,:,6*nData+iData) = rot90(augImg(:,:,:,nData+iData), 2); % 左右反転画像を反時計回りに180度回転
    augImg(:,:,:,7*nData+iData) = rot90(augImg(:,:,:,nData+iData), 3); % 左右反転画像を反時計回りに270度回転
end
augLabel = repmat(label, [8,1]); % ラベルをコピー
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EOF %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%