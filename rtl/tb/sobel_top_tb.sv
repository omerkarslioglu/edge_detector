module sobel_top_tb
  import sobel_config_pkg::*;
  import mem_config_pkg::*;
();

logic                     clk_i = 0;
logic                     rst_ni;
logic                     start_i;
logic                     finish_o;
logic                     wr_en_imem_i;
logic [   ADDR_WIDTH-1:0] addr_imem_i;
logic [   DATA_WIDTH-1:0] data_imem_i;
logic                     rd_en_omem_i;
logic [   ADDR_WIDTH-1:0] addr_omem_i;
logic [   DATA_WIDTH-1:0] data_omem_o;

int sobel_out;

initial begin
  forever #1 clk_i <= ~clk_i;
end

sobel_top dut(
  .clk_i(clk_i),
  .rst_ni(rst_ni),
  .start_i(start_i), // to start execution process
  .finish_o(finish_o), // it becomes high when sobel exc. process done
  .wr_en_imem_i(wr_en_imem_i), // write enable for input memory to load input image
  .addr_imem_i(addr_imem_i),
  .data_imem_i(data_imem_i),
  .rd_en_omem_i(rd_en_omem_i), // to read output image
  .addr_omem_i(addr_omem_i),
  .data_omem_o(data_omem_o)
);

initial begin
  addr_omem_i <= 0;
  rd_en_omem_i <= 0;
  wr_en_imem_i <= 0; // no need to write input image for simulation it takes image from txt file format.
  start_i <= 0;
  sobel_out = $fopen(OUTPUT_FILE_PATH, "w");
  if(!sobel_out) $error("[ERROR-02]     IN MEMORY - Output file was not opened!");

  rst_ni <= 0;
  repeat(5) @(posedge clk_i);
  rst_ni <= 1;
  repeat(2) @(posedge clk_i);
  start_i <= 1;
  @(posedge clk_i);
  start_i <= 0;
  
  @(posedge finish_o);
  
  @(posedge clk_i);
  @(posedge clk_i);

  rd_en_omem_i <= 1;

  @(posedge clk_i);

  repeat (IMAGE_ROW_SIZE*IMAGE_COLUMN_SIZE) begin // write the output image to the txt file
    addr_omem_i <= addr_omem_i + 1;
    @(posedge clk_i);
    $fdisplay(sobel_out, "%2h", data_omem_o);
  end
  $fclose(sobel_out);

  @(posedge clk_i);
  $finish;
end

endmodule
