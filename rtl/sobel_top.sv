module sobel_top
  import sobel_config_pkg::*;
  import mem_config_pkg::*;
(
  input                       clk_i,
  input                       rst_ni,

  input                       start_i, // to start execution process
  output                      finish_o, // it becomes high when sobel exc. process done

  input                       wr_en_imem_i, // write enable for input memory to load input image
  input   [   ADDR_WIDTH-1:0] addr_imem_i,
  input   [   DATA_WIDTH-1:0] data_imem_i,

  input                       rd_en_omem_i, // to read output image
  input   [   ADDR_WIDTH-1:0] addr_omem_i,
  output  [   DATA_WIDTH-1:0] data_omem_o
);

logic [   DATA_WIDTH-1:0] i_pixel; // read data from input memory
logic [   ADDR_WIDTH-1:0] i_pixel_addr; // addr that comes from sobel exc. unit
logic [   ADDR_WIDTH-1:0] i_mem_addr;
logic [   DATA_WIDTH-1:0] o_pixel;
logic [   ADDR_WIDTH-1:0] o_pixel_addr;
logic [   ADDR_WIDTH-1:0] o_mem_addr;
logic [   DATA_WIDTH-1:0] o_mem_data;
logic                     o_mem_wr_en;
logic                     o_wr_en; // write enable signal to output memory it comes from sobel exc. unit

sobel_exc exc(
  .clk_i(clk_i),
  .rst_ni(rst_ni),
  .start_i(start_i),
  .i_pixel_i(i_pixel),
  .i_pixel_addr_o(i_pixel_addr),
  .o_wr_en_o(o_wr_en),
  .o_pixel_o(o_pixel),
  .o_pixel_addr_o(o_pixel_addr),
  .finish_o(finish_o)
);

input_memory i_mem(
  .clk_i(clk_i),
  .wr_en_i(wr_en_imem_i),
  .addr_i(i_mem_addr),
  .data_i(data_imem_i), // when to load input image, this data is not related with sobel exc. unit
  .data_o(i_pixel)
);

output_memory o_mem(
  .clk_i(clk_i),
  .wr_en_i(o_mem_wr_en),
  .addr_i(o_mem_addr),
  .data_i(o_pixel),
  .data_o(data_omem_o)
);

always_comb begin
  case(rd_en_omem_i)
    0: o_mem_addr = o_pixel_addr;
    1: o_mem_addr = addr_omem_i; // when to read output image, addr comes from outside
  endcase
end

always_comb begin
  case(rd_en_omem_i)
    0: o_mem_wr_en = o_wr_en;
    1: o_mem_wr_en = 0; // when reading output image wr_en signal is no need to be logic high
  endcase
end

always_comb begin
  case(wr_en_imem_i)
    0: i_mem_addr = i_pixel_addr; // when sobel exc. read data from input memory
    1: i_mem_addr = addr_imem_i; // when to load input image to input memory
  endcase
end

endmodule