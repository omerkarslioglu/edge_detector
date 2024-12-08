module sobel_exc
  import sobel_config_pkg::*;
  import mem_config_pkg::*;
(
  input                                 clk_i, 
  input                                 rst_ni,
  input                                 start_i,
  input signed      [   DATA_WIDTH-1:0] i_pixel_i,
  output logic      [   ADDR_WIDTH-1:0] i_pixel_addr_o,
  output logic                          o_wr_en_o,
  output logic      [   DATA_WIDTH-1:0] o_pixel_o,
  output logic      [   ADDR_WIDTH-1:0] o_pixel_addr_o,
  output logic                          finish_o
);

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

localparam OUTPUT_COLUMN_SIZE = IMAGE_COLUMN_SIZE - 2;
localparam LAST_OUTPUT_COLUMN_INDEX = IMAGE_COLUMN_SIZE - 3;
localparam LAST_OUTPUT_ROW_INDEX = IMAGE_ROW_SIZE - 3;

localparam IDLE = 2'b00;
localparam START_STATE = 2'b01;
localparam FIRST_STATE = 2'b10;
localparam SECOND_STATE = 2'b11;

logic [1:0] state;
logic [ADDR_WIDTH-1:0] i_increased_pixel_addr;
logic signed [DATA_WIDTH+3:0] mul_x, mul_y;
logic signed [DATA_WIDTH+3:0] grad_x, grad_y;
logic signed [DATA_WIDTH+3:0] grad_x_buff, grad_y_buff;
logic signed [DATA_WIDTH+3:0] grad_x_mux, grad_y_mux;
logic signed [DATA_WIDTH+3:0] sum_grad_and_mul_x, sum_grad_and_mul_y;
logic [2:0] scolumn, srow;
logic [2:0] increased_scolumn, increased_srow;
logic start_f;
logic start_q;
logic finish_sobel_f;
logic [$clog2(IMAGE_COLUMN_SIZE)-1:0] column_process_cnt, increased_column_process_cnt;
logic [$clog2(IMAGE_ROW_SIZE)-1:0] row_process_cnt, increased_row_process_cnt;
logic signed [DATA_WIDTH+3:0] sobel_out;
logic [($clog2(IMAGE_COLUMN_SIZE) + $clog2(IMAGE_ROW_SIZE)-1):0] mul_of_inc_row_process_cnt_and_i_column_size;
logic [ADDR_WIDTH-1:0] o_pixel_addr;
logic writed_f;
logic grads_buffered_flag;

assign finish_o = finish_sobel_f; // TODO: it will become fixed

assign grad_x_mux = (grads_buffered_flag) ? grad_x_buff : grad_x;
assign grad_y_mux = (grads_buffered_flag) ? grad_y_buff : grad_y;

/* posedge detector for start signal */
always_ff @(posedge clk_i) begin
  if(!rst_ni) start_q <= 0;
  else start_q <= start_i;
end

assign start_f = start_i & !start_q;

/* Sobel Algorithm */
always_ff @(posedge clk_i) begin
  if (!rst_ni) begin
    grad_x <= '0;
    grad_y <= '0;
    finish_sobel_f <= '0;
    scolumn <= '0;
    srow <= '0;
    state <= IDLE;
    o_pixel_o <= '0;
    o_pixel_addr_o <= '0;
    o_wr_en_o <= 1'b0;
    writed_f <= 0;
    grads_buffered_flag <= 0;
  end else begin
    grads_buffered_flag <= 0;
    case(state)
      IDLE: begin
        if (start_f) state <= START_STATE; 
        else state <= IDLE;
        srow <= 0;
        scolumn <= 0;
      end
      START_STATE: begin
        state <= FIRST_STATE;
        srow <= 0;
        scolumn <= 0;
      end
      FIRST_STATE: begin
        grad_x <= sum_grad_and_mul_x;
        grad_y <= sum_grad_and_mul_y;
        grad_x_buff <= mul_x;
        grad_y_buff <= mul_y;
        grads_buffered_flag <= 1;
        srow <= increased_srow;
        scolumn <= '0;
        state <= SECOND_STATE;
        if (scolumn == 2 && srow == 2) begin
          srow <= 0;
          o_wr_en_o <= 1;
          writed_f <= 1;
          o_pixel_o <= (sobel_out > THRESHOLD) ? 'd0 : 'd255;
          //$display("sobel output data: %0d", sobel_out);
          o_pixel_addr_o <= o_pixel_addr; //row_process_cnt * OUTPUT_COLUMN_SIZE + column_process_cnt; // Setting output image addres
          if (column_process_cnt == LAST_OUTPUT_ROW_INDEX && row_process_cnt == LAST_OUTPUT_COLUMN_INDEX) finish_sobel_f <= 1; // if column and row counters are done, set sobel is done
          else finish_sobel_f <= '0;
        end else begin
          o_wr_en_o <= '0;
          writed_f <= 0;
          o_pixel_o <= '0;
          o_pixel_addr_o <= '0;
          finish_sobel_f <= '0;
        end
      end
      SECOND_STATE: begin
        grads_buffered_flag <= 0;
        if(!grads_buffered_flag) begin
          grad_x <= sum_grad_and_mul_x;
          grad_y <= sum_grad_and_mul_y;
        end else begin
          grad_x <= mul_x;
          grad_y <= mul_y;
        end
        if (srow != 2) begin 
          srow <= increased_srow;
          scolumn <= scolumn;
        end else begin  
          srow <= 0;
          scolumn <= increased_scolumn;
        end
        if (scolumn == 2 && srow == 1) state <= FIRST_STATE;
        // detect corner addresses:
/*         if (writed_f && (column_process_cnt == 0 || column_process_cnt == LAST_OUTPUT_ROW_INDEX || row_process_cnt == 0 || row_process_cnt == LAST_OUTPUT_COLUMN_INDEX)) begin */
        if (writed_f) begin
          writed_f <= 0;
          if (column_process_cnt == 0) begin 
            // if (o_pixel_addr_o == IMAGE_COLUMN_SIZE + 1) writed_f2 <= 1; // for edges, writing operation should become more then one (left-up) o_pixel_addr_o - IMAGEIMAGE_COLUMN_SIZE ; write_f2=0 write_f3 = 1 ; o_pixel_addr_o - 1 write_f3=0
            o_pixel_addr_o <= o_pixel_addr_o - 1;
            o_wr_en_o <= 1;
            o_pixel_o <= o_pixel_o;
          end else if (column_process_cnt == LAST_OUTPUT_ROW_INDEX) begin
            // if (o_pixel_addr_o == (IMAGE_COLUMN_SIZE-1)*(IMAGE_ROW_SIZE) + 1) writed_f2 <= 1; // for edges, writing operation should become more then one (right-up corner) o_pixel_addr_o + IMAGE_COLUMN_SIZE; write_f2=0 write_f3=0; o_pixel_addr_o = o_pixel_addr_o -1 write_f3=0
            o_pixel_addr_o <= o_pixel_addr_o + 1; 
            o_wr_en_o <= 1;
            o_pixel_o <= o_pixel_o;
          end else if (row_process_cnt == 0) begin
            // if (o_pixel_addr_o == (IMAGE_COLUMN_SIZE-1)*(IMAGE_ROW_SIZE) + 1) writed_f2 <= 1; // for edges, writing operation should become more then one
            o_pixel_addr_o <= o_pixel_addr_o - IMAGE_COLUMN_SIZE;
            o_wr_en_o <= 1;
            o_pixel_o <= o_pixel_o;
          end else if (row_process_cnt == LAST_OUTPUT_COLUMN_INDEX) begin
            o_pixel_addr_o <= o_pixel_addr_o + IMAGE_COLUMN_SIZE;
            o_wr_en_o <= 1;
            o_pixel_o <= o_pixel_o;
          end else begin
            o_pixel_addr_o <= 0;
            o_wr_en_o <= 0;
            o_pixel_o <= 0;
          end
        end else begin
          writed_f <= 0;
          o_wr_en_o <= '0;
          o_pixel_o <= '0;
          o_pixel_addr_o <= '0;
        end
        finish_sobel_f <= '0;
      end
    endcase 
  end
end

/* Setting input image mem addres, when addr is set, data comes one clock period after */
always_ff @(posedge clk_i) begin
  if (!rst_ni) begin
    i_pixel_addr_o <= '0;
  end else begin
    if(state == START_STATE) begin
      i_pixel_addr_o  <= 1;
    end else if (state inside {FIRST_STATE, SECOND_STATE}) begin
      if (row_process_cnt == LAST_OUTPUT_COLUMN_INDEX && srow==1 && scolumn==2) i_pixel_addr_o  <= increased_column_process_cnt; // on one bottom row, for new process (new window)
      else if(srow==0) i_pixel_addr_o <= i_increased_pixel_addr;
      else if (srow==1 && scolumn==2) i_pixel_addr_o <= mul_of_inc_row_process_cnt_and_i_column_size + column_process_cnt; // on same row, for new process (new window)
      else if (srow==1) i_pixel_addr_o <= IMAGE_COLUMN_SIZE + i_pixel_addr_o - 2; // in same process, one right side column
      else if (srow==2) i_pixel_addr_o <= i_increased_pixel_addr;
      else i_pixel_addr_o  <= '0;
    end
  end
end

/* Output image address */
always_ff @(posedge clk_i) begin
  if (!rst_ni) begin
    o_pixel_addr <= '0;
  end else begin
    if (srow==2 && scolumn==0) o_pixel_addr <= i_increased_pixel_addr;
  end
end

/* Counters for indexing */
always_ff @(posedge clk_i) begin
  if(!rst_ni) begin
    row_process_cnt <= '0;
    column_process_cnt <= '0;
  end else begin
    if(writed_f) begin
      if(row_process_cnt != (LAST_OUTPUT_COLUMN_INDEX)) begin
        row_process_cnt <= increased_row_process_cnt;
      end else begin
        row_process_cnt <= '0;
        column_process_cnt <= increased_column_process_cnt;
      end
    end
  end
end

assign increased_row_process_cnt = row_process_cnt + 1;
assign increased_column_process_cnt = column_process_cnt + 1;
assign increased_scolumn = scolumn + 1;
assign increased_srow = srow + 1;
assign sum_grad_and_mul_x = mul_x + grad_x_mux;
assign sum_grad_and_mul_y = mul_y + grad_y_mux;
assign i_increased_pixel_addr = i_pixel_addr_o + 1;
assign mul_of_inc_row_process_cnt_and_i_column_size = increased_row_process_cnt * IMAGE_COLUMN_SIZE;

assign mul_x = i_pixel_i * SOBEL_X[srow][scolumn];
assign mul_y = i_pixel_i * SOBEL_Y[srow][scolumn];

assign sobel_out = abs_value(grad_x) + abs_value(grad_y);

/* Absolute Value Function */
function automatic logic signed [$bits(grad_x)-1:0] abs_value(input logic signed [$bits(grad_x)-1:0] input_num);
    return (input_num < 0) ? -input_num : input_num;
endfunction

endmodule