`timescale 1ns/100ps

module sobel_exc_tb
  import sobel_config_pkg::*;
  import mem_config_pkg::*;
();

logic                     clk_i = 0;
logic                     rst_ni = 0;
logic                     start_i = 0;
logic [   DATA_WIDTH-1:0] i_pixel_i;
logic [   ADDR_WIDTH-1:0] i_pixel_addr_o;
logic                     o_wr_en_o;
logic [   DATA_WIDTH-1:0] o_pixel_o;
logic [   ADDR_WIDTH-1:0] o_pixel_addr_o;
logic                     finish_o;

int sobel_out;
int write_cnt = 0;
logic addr_sel;

logic [   ADDR_WIDTH-1:0] o_addr_cnt = 0;
logic [   ADDR_WIDTH-1:0] o_mem_addr;
logic [   DATA_WIDTH-1:0] o_mem_data;


initial begin
  forever #1 clk_i <= ~clk_i;
end

sobel_exc exc(
  .clk_i(clk_i),
  .rst_ni(rst_ni),
  .start_i(start_i),
  .i_pixel_i(i_pixel_i),
  .i_pixel_addr_o(i_pixel_addr_o),
  .o_wr_en_o(o_wr_en_o),
  .o_pixel_o(o_pixel_o),
  .o_pixel_addr_o(o_pixel_addr_o),
  .finish_o(finish_o)
);

input_memory i_mem(
  .clk_i(clk_i),
  .wr_en_i(), // no need write since it is input file
  .addr_i(i_pixel_addr_o),
  .data_i(),
  .data_o(i_pixel_i)
);

output_memory o_mem(
  .clk_i(clk_i),
  .wr_en_i(o_wr_en_o),
  .addr_i(o_mem_addr),
  .data_i(o_pixel_o),
  .data_o(o_mem_data)
);

always_comb begin
  case(addr_sel)
    0: o_mem_addr = o_pixel_addr_o;
    1: o_mem_addr = o_addr_cnt;
  endcase
end

initial begin
  addr_sel <= 0;
  sobel_out = $fopen(OUTPUT_FILE_PATH, "w");
  if(!sobel_out) $error("[ERROR-02]     IN MEMORY - Output file was not opened!");

  rst_ni <= 0;
  repeat(5) @(posedge clk_i);
  rst_ni <= 1;
  repeat(2) @(posedge clk_i);
  start_i <= 1;
  @(posedge clk_i);
  while(!finish_o) begin
    @(posedge o_wr_en_o);
  end
  @(posedge clk_i);
  addr_sel <= 1; 
  repeat ((IMAGE_ROW_SIZE-2)*(IMAGE_COLUMN_SIZE-2)) begin
    @(posedge clk_i);
    o_addr_cnt <= o_addr_cnt + 1;
    $fdisplay(sobel_out, "%2h", o_mem_data);
  end
  $fclose(sobel_out);

  @(posedge clk_i);
  $finish;
end

initial begin
  forever @(posedge o_wr_en_o) write_cnt++;
end

endmodule