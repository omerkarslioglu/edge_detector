% Load grayscale Lena image
load lena.mat

% Load output as hex file
fid = fopen('lena_hex.txt', 'r');
lena_hex = fscanf(fid, '%2x');

fid0 = fopen('sobel_out.txt', 'r');
sobel_out = fscanf(fid0, '%2x');

fclose(fid);
fclose(fid0);

% Reshape and convert to uint8
lena_hex = uint8(reshape(lena_hex, 256, 256));
sobel_out = uint8(reshape(sobel_out, 256, 256));
% Display input and output images side by side
figure;
subplot(1,3,1); imshow(lena); title('Input Image');
subplot(1,3,2); imshow(lena_hex); title('Hex Image');
subplot(1,3,3); imshow(sobel_out); title('Sobel Out');