package mem_config_pkg;

import sobel_config_pkg::*;

localparam ADDR_WIDTH = $clog2(IMAGE_ROW_SIZE * IMAGE_COLUMN_SIZE);
localparam DATA_WIDTH = 8;

endpackage