% Load grayscale Lena image
load lena.mat

% Load output as hex file
fid = fopen('lena_hex.txt', 'r');
lena_hex = fscanf(fid, '%2x');
fclose(fid);

% Reshape and convert to uint8
lena_hex = uint8(reshape(lena_hex, 256, 256));

% Display input and output images side by side
figure;
subplot(1,2,1); imshow(lena); title('Input Image');
subplot(1,2,2); imshow(lena_hex); title('Output Image');
