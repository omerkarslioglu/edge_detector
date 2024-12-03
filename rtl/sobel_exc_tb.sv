`timescale 1ns/100ps

module sobel_exc_tb
  import sobel_config_pkg::*;
  import mem_config_pkg::*;
();

logic                    clk_i = 0;
logic                    rst_ni = 0;
logic                    start_i = 0;
logic[   DATA_WIDTH-1:0] i_pixel_i;
logic[   ADDR_WIDTH-1:0] i_pixel_addr_o;
logic                    o_wr_en_o;
logic[   DATA_WIDTH-1:0] o_pixel_o;
logic[   ADDR_WIDTH-1:0] o_pixel_addr_o;
logic                    finish_o;

int sobel_out;

int write_cnt = 0;

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

memory mem(
  .clk_i(clk_i),
  .wr_en_i(), // no need write since it is input file
  .addr_i(i_pixel_addr_o),
  .data_i(),
  .data_o(i_pixel_i)
);

initial begin
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
      $fdisplay(sobel_out, "%2h", o_pixel_o);
  end
  $fclose(sobel_out);

  @(posedge clk_i);
  $finish;
end

initial begin
  forever @(posedge o_wr_en_o) write_cnt++;
end

endmodule