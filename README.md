# SOBEL EXECUTION UNIT
Synthesizable sobel execution unit SystemVerilog hardware design.

This sobel edge detector hardware design consists of two block memories and the main module, the sobel execution unit. Data can be loaded from the input memory, and the resulting image can be read from the output memory. These memories have a single port and a byte data width. The execution process starts with the rising edge of the ``start_i`` signal after the system is reset. The ``finish_o`` signal indicates that the process is complete. Since the data is read from the memories byte by byte, the process process varies according to the size of the image. The block level design is as follows:

<p align="center">
  <img title="" alt="Sobel HW Design Block" src="/docs/images/sobel_exc_block.png">
</p>

File tree:

```
│   
├───docs
│   │   sobel_exc_block.drawio
│   │   
│   └───images
├───rtl
│   │   memory.sv
│   │   sobel_exc.sv
│   │   sobel_top.sv
│   │
│   ├───pkg
│   │       mem_config_pkg.sv
│   │       sobel_config_pkg.sv
│   │
│   └───tb
│           sobel_exc_tb.sv
│           sobel_top_tb.sv
└───src
    │   experience.txt
    │   input_test_file.txt
    │   lena_hex.txt
    │   output_test_file.txt
    └───matlab
            ee562_project.m
            lena.mat
```

### About Sobel Algorithm

Sobel edge detection algorithm calculates derivatives of an NxN input image with 3x3 Kx and 3x3 Ky kernels as shown below.

<p align="center">
  <img title="" alt="Kx and Ky Matrices" src="/docs/images/kx_ky_windows.png" width="600" height="auto">
</p>

Then, the magnitude is calculated as shown below.

<p align="center">
  <img title="" alt="Sobel Output" src="/docs/images/sobel_out.png" width="380" height="auto">
</p>

Finally, thresholding is applied in order to eliminate the noise on the edges.

<p align="center">
  <img title="" alt="Thresholding" src="/docs/images/thresholding.png" width="280" height="auto">
</p>

Sobel edge detection algorithm is applied to 3x3 windows for each pixel in the input image as shown below.

<p align="center">
  <img title="" alt="Windowing Operation" src="/docs/images/windowing.png"width="700" height="auto">
</p>

### To run the design on the simulation tools:
In the ``rtl/pkg/sobel_config_pkg.sv`` file, the paths of the input and output image files and the dimensions of the input image must be set.

```
package  sobel_config_pkg;
  localparam IMAGE_ROW_SIZE             = 256;
  localparam IMAGE_COLUMN_SIZE          = 256;
  localparam THRESHOLD                  = 150;
  localparam string INPUT_FILE_PATH     = "__path__";
  localparam string OUTPUT_FILE_PATH    = "__path__";
endpackage
```

### Working principle of the design:
The two windows in the Sobel edge detector algorithm are defined in hardware as constants.
These two windows are traversed line by line in order and grad_x and grad_y values ​​are calculated for all pixels except edge-corners.
Each pixel is read from memory byte by byte. Each byte read is processed. The result of each window traversal is compared with the Sobel result THRESHOLD value and the value resulting from this comparison is written to the output image memory.

This design consists of a sobel execution unit (sobel_exc) and two block memories. One of these memories is for the input image and the other is for the output image.

The important and most complicated point here is how to read and write the data.
I preferred to keep the data (the image) in a block memory.
I wrote the result of each calculated pixel into a different block memory that I call "output memory".
The data is read byte by byte and a mathematical operation is performed for each byte of the data and kept in a register.
After the address is sent to the memory, the data comes one clock cycle later.
When the values ​​for the entire window are calculated, the values ​​are added up and the result is written to the relevant address of the output memory according to the threshold value.

### Reading data from input memory:
Two counters in the design perform this task: "srow and scolumn".
In order to understand this better, it would be better to understand how the image is indexed in the memory.
The design is parametric. Therefore, an image of the desired size can be given.
However, in order to understand the design, I will explain it through the 256x256 byte Lena image that we have.
The first 256 addresses in the memory belong to the first column of the image. The second 256 bytes belong to the second column. This is important in terms of indexing.
I would like to remind you again that the Sobel execution unit design proceeds by operating horizontally.
The addresses to be read in the first window will be as follows: first, addresses 0, 1 and 2 are read.
Immediately afterwards, addresses 256, 257 and 258 are read from the second column, then addresses 512, 513 and 514 are read to complete the reading of the first window addresses.

<p align="center">
  <img title="" alt="Reading indexes from an input image." src="/docs/images/sobel_image_indexing.png">
</p>

Then the window is shifted for the next operation. This time, the first column of the 3x3 matrix to be read is addresses 256, 257 and 258. This is how the input image is read from memory.

Each byte read is processed. After the last value read for each window, a request is sent to write to the output memory as a result of the sobel operation.

### Writing the calculated data to the output memory:
Determining the address of the output memory is easier. The first address read in each window and the sum of the column size of the image plus one gives us the address to be written.

### Filling the edges and corners:
The calculation process for each pixel takes a total of 9 clock cycles. The reason for this is that the data coming from the memory is read byte by byte. Corners and edges are an exception.
The reason for this is that edges and corners copy the data of the pixels that are close to them.
I know where the window is with the column_process_cnt and row_process_cnt counters that I have kept inside. Accordingly, if I am doing a reading process on the corners or edge side, the mathematical operations continue non-stop for the next window, while the same value calculated for the previous window is sent to the output memory for the corners and edges. While one more write process is done for each edge, two more write processes are done for each corner.

### Testing and verification:
Instead of a large image format, I chose a 5x5 matrix for the tests. I would get a 3x3 result from this matrix. I wrote the matrices to the block ram in txt format. I performed the results of all operations (such as multiplication and grad values) with waveform tracking.Finally, I gave the Lena image as input. I wrote the data from the output to a txt file. Then it was examined in MATLAB. There are two testbenches. One of them is for just sobel execution unit (sobel_exc_tb.sv), the other one is for top level design (sobel_top_tb.sv). To run simulation, you can use top level testbench.




Thanks for reviewing the design. If you have any questions you can contact me on ``omerkarsliogluu@gmail.com``