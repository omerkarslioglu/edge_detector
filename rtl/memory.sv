/*
  Block ram to hold image
*/

module input_memory
  import sobel_config_pkg::*;
  import mem_config_pkg::*;
(
  input                           clk_i,
  input                           wr_en_i,
  input         [ ADDR_WIDTH-1:0] addr_i,
  input         [ DATA_WIDTH-1:0] data_i,
  output logic  [ DATA_WIDTH-1:0] data_o
);

(* ram_style="block" *)
logic [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];
int initial_file;

initial begin
  initial_file =  $fopen(INPUT_FILE_PATH, "r");
  if(!initial_file) $error("[ERROR-01]     IN MEMORY - Input file was not opened!");
  /* load image */
  $readmemh(INPUT_FILE_PATH, mem);
  /* check mem */
  for (int i = 0; i < 5; i++) begin
    $display("memory[%0d] = %h", i, mem[i]);
  end
end

always_ff @(posedge clk_i) begin
  if (wr_en_i) mem[addr_i] <= data_i;
  data_o <= mem[addr_i];
end

endmodule

module output_memory
  import sobel_config_pkg::*;
  import mem_config_pkg::*;
(
  input                           clk_i,
  input                           wr_en_i,
  input         [ ADDR_WIDTH-1:0] addr_i,
  input         [ DATA_WIDTH-1:0] data_i,
  output logic  [ DATA_WIDTH-1:0] data_o
);

(* ram_style="block" *)
logic [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];

always_ff @(posedge clk_i) begin
  if (wr_en_i) mem[addr_i] <= data_i;
  data_o <= mem[addr_i];
end

endmodule