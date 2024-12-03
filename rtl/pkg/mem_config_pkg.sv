package mem_config_pkg;

import sobel_config_pkg::*;

parameter ADDR_WIDTH = $clog2(IMAGE_ROW_SIZE*IMAGE_COLUMN_SIZE);
parameter DATA_WIDTH = 8;

endpackage