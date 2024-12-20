%% Main image processing
% Read the image
img = imread('yeniceri.jpg');

% Convert to grayscale if the image is RGB
if size(img, 3) == 3
    img = rgb2gray(img);
end

% Resize to 256x256
img_resized = imresize(img, [256 256]);

% Save the variable with a new name
image_data = img_resized;

% Save as MAT file
save('image_data.mat', 'image_data');

%% Save column by column (each byte in new line)
fid_col = fopen('image_col.txt', 'w');
if fid_col == -1
    error('Cannot open column file for writing');
end

% Write each byte in hexadecimal format, column by column
for j = 1:size(image_data, 2)
    for i = 1:size(image_data, 1)
        fprintf(fid_col, '%02X\n', image_data(i,j));
    end
end
fclose(fid_col);

%% Read and verify
% Read the column-wise hex file
fid_col = fopen('image_col.txt', 'r');
hex_data_col = fscanf(fid_col, '%2x');
fclose(fid_col);

% Reshape the data properly without rotating
hex_image_col = uint8(reshape(hex_data_col, size(image_data, 1), size(image_data, 2)));

% First figure for verification
figure;
subplot(1,2,1);
imshow(image_data);
title('Original Image');
subplot(1,2,2);
imshow(hex_image_col);
title('Column-wise Reconstruction');

% Print verification information
fprintf('Original image dimensions: %dx%d\n', size(image_data));
fprintf('Column file size: %d bytes\n', length(hex_data_col));

% Verify if images match
if isequal(image_data, hex_image_col)
    fprintf('Column-wise verification successful\n');
else
    fprintf('Warning: Column-wise reconstruction mismatch\n');
end

% Read Sobel output
fid0 = fopen('sobel_out.txt', 'r');
sobel_out = fscanf(fid0, '%2x');

% Reshape Sobel output
sobel_out = uint8(reshape(sobel_out, 256, 256));

% Second figure with all three images
figure;
subplot(1,3,1); imshow(image_data); title('Input Image');
subplot(1,3,2); imshow(hex_image_col); title('Hex Image');
subplot(1,3,3); imshow(sobel_out); title('Sobel Out');