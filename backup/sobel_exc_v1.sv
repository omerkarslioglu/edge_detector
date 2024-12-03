module sobel_exc
  import sobel_config_pkg::*;
  import mem_config_pkg::*;
(
  input                                 clk_i, 
  input                                 rst_ni,
  input             [   DATA_WIDTH-1:0] i_pixel_i,
  output logic      [   ADDR_WIDTH-1:0] i_pixel_addr_o,
  output logic                          o_wr_en_o,
  output logic      [   DATA_WIDTH-1:0] o_pixel_o,
  output logic      [   ADDR_WIDTH-1:0] o_pixel_addr_o,
  output logic                          finish_o
);
                          //  row  column
logic [DATA_WIDTH-1:0] window [0:2][0:2];

/* Coeff. for sobel algorithm */
localparam logic signed [3:0] SOBEL_X [0:2][0:2] = '{
  '{ -1,  0,  1},
  '{ -2,  0,  2},
  '{ -1,  0,  1}
};

localparam logic signed [3:0] SOBEL_Y [0:2][0:2] = '{
  '{ -1, -2, -1},
  '{  0,  0,  0},
  '{  1,  2,  1}
};

localparam WINDOW_TRAVAEL_LIMIT = (IMAGE_ROW_SIZE - 2) * (IMAGE_COLUMN_SIZE - 2);

logic [$clog2(WINDOW_TRAVAEL_LIMIT+1):0] limit_cnt;

// each 256 byte on hex image file is column
localparam SWITCH_COLUMN_ADDR = IMAGE_COLUMN_SIZE;

logic [ADDR_WIDTH-1:0] base_addr, next_base_addr;
logic [2:0] w_column, w_row;
logic [2:0] w_column_buff, w_row_buff;
logic signed [DATA_WIDTH+3:0] mul_x, mul_y;
logic signed [DATA_WIDTH+3:0] grad_x, grad_y;
logic signed [DATA_WIDTH+3:0] sobel_out;
logic [$clog2(IMAGE_COLUMN_SIZE)-1:0] column_cnt;
logic [$clog2(IMAGE_ROW_SIZE)-1:0] row_cnt;
logic [$clog2(IMAGE_ROW_SIZE)-1:0] next_row_cnt;

logic o_wr_en;

/* Sobel Algorithm */
always_ff @(posedge clk_i) begin
  if (!rst_ni) begin
    for (int i = 0; i < 3; i++) begin
      for (int j = 0; j < 3; j++) begin
        window[i][j] <= 8'b0;
      end
    end
    w_column  <= 8'b0;
    w_row     <= 8'b0;
    i_pixel_addr_o <= 8'b0;
    base_addr <= 8'b0;
    grad_x <= 0;
    grad_y <= 0;
    limit_cnt <= 0;
    finish_o <= 0;
    column_cnt <= 0;
    row_cnt <= 0;
  end else begin
    o_wr_en <= 0;
    grad_x          <= grad_x + mul_x;
    grad_y          <= grad_y + mul_y;
    if(w_row == 1 && w_column == 0) begin
      w_row           <= w_row + 1;
      i_pixel_addr_o  <= i_pixel_addr_o + 1;
      grad_x          <= mul_x;
      grad_y          <= mul_y;
    end else if(w_row == 2 && w_column == 2) begin
      w_row           <= 0;
      w_column        <= 0;
      i_pixel_addr_o  <= next_base_addr;
      o_wr_en         <= 1;
      if (limit_cnt < WINDOW_TRAVAEL_LIMIT) begin
        limit_cnt       <= limit_cnt + 1;
      end else begin
        finish_o        <= 1;
        o_wr_en         <= 0;
      end
      o_pixel_addr_o  <= next_base_addr + 1;
    end else if (w_row == 2) begin
      i_pixel_addr_o  <= base_addr + SWITCH_COLUMN_ADDR * (w_column + 1);
      w_row           <= 0;
      w_column        <= w_column + 1;
      if(w_column == 1) begin
      if(column_cnt == 5) begin 
        column_cnt <= 0;
        row_cnt <= next_row_cnt;
        base_addr <= next_row_cnt;
      end else begin 
        column_cnt <= column_cnt + 1;
        base_addr <= next_base_addr;
      end
      end
    end else begin
      w_row           <= w_row + 1;
      i_pixel_addr_o  <= i_pixel_addr_o + 1;
    end
  end
end

always_ff @(posedge clk_i) begin
  w_column_buff     <= w_column ;
  w_row_buff        <= w_row    ;
end

always_ff @(posedge clk_i) begin
  o_wr_en_o         <= o_wr_en; 
end

always_comb begin  
  sobel_out        = signed_to_unsigned(grad_x) + signed_to_unsigned(grad_y);
  o_pixel_o        = (THRESHOLD > sobel_out) ? 255 : 0;
end

assign mul_x = $signed(SOBEL_X[w_row_buff][w_column_buff]) * $signed(i_pixel_i);
assign mul_y = $signed(SOBEL_Y[w_row_buff][w_column_buff]) * $signed(i_pixel_i);

assign next_base_addr = base_addr + SWITCH_COLUMN_ADDR;
assign next_row_cnt = row_cnt + 1;

function automatic [DATA_WIDTH+3:0] signed_to_unsigned;
  input signed [DATA_WIDTH+3:0] signed_num;
  begin
      signed_to_unsigned = (signed_num < 0) ? unsigned'(-signed_num) : unsigned'(signed_num); // absolute value
  end
endfunction

endmodule