clear; close all; clc; % ワークスペース開放（clear），プロットフィギュア消去（close all），コマンドラインクリア（clc）

%% 設定値
inFolderName = "inputImages"; % 入力画像のあるフォルダのパス
devTestRatio = 0.8; % 全データ中の開発データ（学習データ＋検証データ）の分割割合
trainValRatio = 0.8; % 開発データ中の学習データと検証データの分割割合
resizedRow = 50; % リサイズ後の画像の行数
resizedCol = 50; % リサイズ後の画像の列数
conv2gray = true; % リサイズ後の画像をグレイスケール化
augIsFlip = 1; % 上下や左右の反転による画像のデータ拡張（0: 反転しない，1: 上下左右反転，2: 上下反転，3: 左右反転）
augIsRot = true; % 90・180・270度の回転による画像のデータ拡張（true/false）

%% 入力画像読み込み，ラベル付け，学習データ・検証データ・評価データへの分割
imds = imageDatastore("./" + inFolderName); % フォルダの中の画像をデータストア化

% 各画像にラベルを付与（ラベルはファイル名のアンダースコアの前の1文字）
filePath = string(imds.Files); % 各画像のファイルパスを取得（全画像に対して）
labels = extractBetween(filePath, inFolderName + "\", "_"); % 「入力画像フォルダパス+\」と「_」の間の文字列を取得（全画像に対して）
imds.Labels = cellstr(labels); % データストアのラベルに設定（stringをcell型に変換してから代入）
sample = readimage(imds, 1); % サンプルとして画像を1枚読み込み
[row, col, ch] = size(sample); % 画像サイズ取得（200 x 200 x 3）

% データ分割
[devImds, testImds] = splitEachLabel(imds, devTestRatio, "randomized"); % 全データを開発データと評価データにランダム分割
[trainImds, valImds] = splitEachLabel(devImds, trainValRatio, "randomized"); % 開発データを学習データと検証データにランダム分割

%% 画像のリサイズとデータ拡張
% imageDatastoreをdoubleにキャストし全データをメモリに格納
[trainX, trainY] = imds2array(trainImds);
trainY = str2double(trainY);
[valX, valY] = imds2array(valImds);
valY = str2double(valY);
[testX, testY] = imds2array(testImds);
testY = str2double(testY);

% 画像をリサイズしグレイスケール化
if row ~= resizedRow || col ~= resizedCol || conv2gray
    trainX = imgResize(trainX, resizedRow, resizedCol, conv2gray);
    valX = imgResize(valX, resizedRow, resizedCol, conv2gray);
    testX = imgResize(testX, resizedRow, resizedCol, conv2gray);
end

% 上下左右の反転と90・180・270度回転を加えて学習データを8倍に拡張
[trainX, trainY] = imgAugFlipRot(trainX, trainY, augIsFlip, augIsRot);

%% DNNの構築
convFilterSize = [2 2]; % 畳み込み層のフィルタサイズ（height width）
convFilterStride = [1 1]; % 畳み込み層のフィルタのストライド（height width）
poolWinSize = [2 2];  % プーリング層のウィンドウサイズ（height width）
poolWinStride = poolWinSize; % プーリング層のウィンドウのストライド（height width）
if conv2gray; ch = 1; end % グレイスケール化した場合はch=1に置き換え

layers = [
    imageInputLayer([resizedRow resizedCol ch],"Name","imageinput")
    convolution2dLayer(convFilterSize,16,"Name","conv_11","Padding","same","Stride",convFilterStride)
    convolution2dLayer(convFilterSize,16,"Name","conv_12","Padding","same","Stride",convFilterStride)
    reluLayer("Name","relu_1")
    maxPooling2dLayer(poolWinSize,"Name","maxpool_1","Padding","same","Stride",poolWinStride)
    convolution2dLayer(convFilterSize,32,"Name","conv_21","Padding","same","Stride",convFilterStride)
    convolution2dLayer(convFilterSize,32,"Name","conv_22","Padding","same","Stride",convFilterStride)
    reluLayer("Name","relu_2")
    maxPooling2dLayer(poolWinSize,"Name","maxpool_2","Padding","same","Stride",poolWinStride)
    convolution2dLayer(convFilterSize,64,"Name","conv_31","Padding","same","Stride",convFilterStride)
    convolution2dLayer(convFilterSize,64,"Name","conv_32","Padding","same","Stride",convFilterStride)
    reluLayer("Name","relu_3")
    maxPooling2dLayer(poolWinSize,"Name","maxpool_3","Padding","same","Stride",poolWinStride)
    convolution2dLayer(convFilterSize,128,"Name","conv_41","Padding","same","Stride",convFilterStride)
    convolution2dLayer(convFilterSize,128,"Name","conv_42","Padding","same","Stride",convFilterStride)
    reluLayer("Name","relu_4")
    maxPooling2dLayer(poolWinSize,"Name","maxpool_4","Padding","same","Stride",poolWinStride)
    fullyConnectedLayer(64,"Name","fc_1")
    reluLayer("Name","relu_5")
    fullyConnectedLayer(32,"Name","fc_2")
    reluLayer("Name","relu_6")    
    fullyConnectedLayer(1,"Name","fc_3")
    reluLayer("Name","relu_7")
    regressionLayer("Name","regressionoutput")];

%% 学習の設定
opts = trainingOptions("adam",...
    "ExecutionEnvironment","auto",...
    "InitialLearnRate",0.001,...
    "MiniBatchSize",512,...
    "MaxEpochs",100,...
    "Shuffle","every-epoch",...
    "ValidationFrequency",64,...
    "ValidationPatience",8,...
    "Plots","training-progress",...
    "ValidationData",{valX,valY});

%% 学習
[net, traininfo] = trainNetwork(trainX, trainY, layers, opts);

%% 評価
predY = predict(net, testX);
figure; swarmchart(testY, predY);
xlim([-0.5, 9.5]); ylim([0, 10]); grid on;
xlabel("Correct number of circles"); ylabel("Predicted number of circles");
xticks(0:9); yticks(0:10);
set(gca, "FontSize", 14);

%% 保存
save('trainedNet.mat','net');