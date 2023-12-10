
`include "defines.vh"
//---------------------------------------------------------------------------
// DUT 
//---------------------------------------------------------------------------
module MyDesign(
//---------------------------------------------------------------------------
//System signals
  input wire reset_n                      ,  
  input wire clk                          ,

//---------------------------------------------------------------------------
//Control signals
  input wire dut_valid                    , 
  output wire dut_ready                   ,

//---------------------------------------------------------------------------
//q_state_input SRAM interface
  output wire                                               q_state_input_sram_write_enable  ,
  output wire [`Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_input_sram_write_address ,
  output wire [`Q_STATE_INPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_input_sram_write_data    ,
  output wire [`Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_input_sram_read_address  , 
  input  wire [`Q_STATE_INPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_input_sram_read_data     ,

//---------------------------------------------------------------------------
//q_state_output SRAM interface
  output wire                                                q_state_output_sram_write_enable  ,
  output wire [`Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_output_sram_write_address ,
  output wire [`Q_STATE_OUTPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_output_sram_write_data    ,
  output wire [`Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_output_sram_read_address  , 
  input  wire [`Q_STATE_OUTPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_output_sram_read_data     ,

//---------------------------------------------------------------------------
//scratchpad SRAM interface                                                       
  output wire                                                scratchpad_sram_write_enable        ,
  output wire [`SCRATCHPAD_SRAM_ADDRESS_UPPER_BOUND-1:0]     scratchpad_sram_write_address       ,
  output wire [`SCRATCHPAD_SRAM_DATA_UPPER_BOUND-1:0]        scratchpad_sram_write_data          ,
  output wire [`SCRATCHPAD_SRAM_ADDRESS_UPPER_BOUND-1:0]     scratchpad_sram_read_address        , 
  input  wire [`SCRATCHPAD_SRAM_DATA_UPPER_BOUND-1:0]        scratchpad_sram_read_data           ,

//---------------------------------------------------------------------------
//q_gates SRAM interface                                                       
  output wire                                                q_gates_sram_write_enable           ,
  output wire [`Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0]        q_gates_sram_write_address          ,
  output wire [`Q_GATES_SRAM_DATA_UPPER_BOUND-1:0]           q_gates_sram_write_data             ,
  output wire [`Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0]        q_gates_sram_read_address           ,  
  input  wire [`Q_GATES_SRAM_DATA_UPPER_BOUND-1:0]           q_gates_sram_read_data              
);

  localparam inst_sig_width = 52;
  localparam inst_exp_width = 11;
  localparam inst_ieee_compliance = 3;

  reg  [inst_sig_width+inst_exp_width : 0] inst_a;
  reg  [inst_sig_width+inst_exp_width : 0] inst_b;
  reg  [inst_sig_width+inst_exp_width : 0] inst_c;
  reg  [2 : 0] inst_rnd;
  wire [inst_sig_width+inst_exp_width : 0] z_inst;
  wire [7 : 0] status_inst;


//---------------------------------------------------------------------------
//Control signals registers
  reg dut_ready_r;
  
//q_state_input SRAM interface registers
  reg [`Q_STATE_INPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_input_sram_read_address_r; 

//---------------------------------------------------------------------------
//q_state_output SRAM interface registers
  reg [1:0]                                          q_state_output_sram_write_enable_r;
  reg [`Q_STATE_OUTPUT_SRAM_ADDRESS_UPPER_BOUND-1:0] q_state_output_sram_write_address_r;
  reg [`Q_STATE_OUTPUT_SRAM_DATA_UPPER_BOUND-1:0]    q_state_output_sram_write_data_r;

//---------------------------------------------------------------------------
//q_gates SRAM interface registers                                                       
  reg [`Q_GATES_SRAM_ADDRESS_UPPER_BOUND-1:0]        q_gates_sram_read_address_r;

//---------------------------------------------------------------------------
//matrix registers
  reg [63:0] reg_a;        
  reg [63:0] reg_b;
  reg [63:0] reg_c;        
  reg [63:0] reg_d;

  reg [63:0] new_a;
  reg [63:0] new_b;
  reg [63:0] new_c;
  reg [63:0] new_d;


//---------------------------------------------------------------------------
//Q & M registers
  reg [63:0] q_reg;
  reg [63:0] m_reg;
  reg [3:0] counter;
  reg [63:0] sum;

//---------------------------------------------------------------------------
//select registers
  reg [1:0] qm_sel;
  reg [1:0] q_in_r_sel;
  reg [1:0] q_g_r_sel;
  reg [1:0] q_out_w_sel;
  reg d_ready_sel;
  reg [2:0] mac_sel;                       
  reg [2:0] in_matrix_sel;
  reg [1:0] count_sel;
  reg [1:0] new_sel;
  reg [1:0] write_out_sel;
  reg [1:0] write_en_sel;

//---------------------------------------------------------------------------
//state vectors & parameters
  reg [4:0] current_state, next_state;
  localparam s0 = 4'b0000;
  localparam s1 = 4'b0001;
  localparam s2 = 4'b0010;
  localparam s3 = 4'b0011;
  localparam s4 = 4'b0100;
  localparam s5 = 4'b0101;
  localparam s6 = 4'b0110;
  localparam s7 = 4'b0111;
  localparam s8 = 4'b1000;
  localparam s9 = 4'b1001;
  localparam s10 = 4'b1010;
  localparam s11 = 4'b1011;
  localparam s12 = 4'b1100;
  localparam s13 = 4'b1101;
  localparam s14 = 4'b1110;
  localparam s15 = 4'b1111;

//---------------------------------------------------------------------------
//CONTROL PATH
//---------------------------------------------------------------------------

  always@(posedge clk or negedge reset_n) begin
    if(!reset_n)
      current_state <= s0;
    else
      current_state <= next_state;
  end


  //FSM
  always@(*) begin
    case(current_state)
      s0 : begin                      //wait for dut_valid
        qm_sel = 2'b00;
        q_in_r_sel = 2'b00;
        q_g_r_sel = 2'b00;
        q_out_w_sel = 2'b00;
        d_ready_sel = 1'b1;
        mac_sel = 3'b0;
        in_matrix_sel = 3'b111;
        count_sel = 2'b00;
        new_sel = 2'b00;
        write_out_sel = 2'b0;
        write_en_sel = 2'b0;

        if(dut_valid) begin
          next_state = s1;
          d_ready_sel = 1'b0;
        end
        else
          next_state = s0;
      end

      s1 : begin                      //set q_input_read_address to 0 to get ready to read in input matrix
        qm_sel = 2'b00;
        q_in_r_sel = 2'b00;
        q_g_r_sel = 2'b10;
        q_out_w_sel = 2'b10;
        d_ready_sel = 1'b0;
        mac_sel = 3'b0;
        in_matrix_sel = 3'b0;
        count_sel = 2'b00;
        new_sel = 2'b1;
        write_out_sel = 2'b10;
        write_en_sel = 2'b10;

        next_state = s2;
      end

      s2 : begin                      //read in Q and M
        qm_sel = 2'b01;
        q_in_r_sel = 2'b01;
        q_g_r_sel = 2'b10;
        q_out_w_sel = 2'b10;
        d_ready_sel = 1'b0;
        mac_sel = 3'b0;
        in_matrix_sel = 3'b0;
        count_sel = 2'b00;
        new_sel = 2'b1;
        write_out_sel = 2'b10;
        write_en_sel = 2'b10;

        next_state = s3;
      end

      s3 : begin                      //read in input matrix
        qm_sel = 2'b10;
        q_in_r_sel = 2'b01;
        q_g_r_sel = 2'b10;
        q_out_w_sel = 2'b10;
        d_ready_sel = 1'b0;
        mac_sel = 3'b0;
        in_matrix_sel = 3'b0;
        count_sel = 2'b00;
        new_sel = 2'b1;
        write_out_sel = 2'b10;
        write_en_sel = 2'b10;

        next_state = s4;
      end

      s4 : begin                      //input matrix A
        qm_sel = 2'b10;
        q_in_r_sel = 2'b01;
        q_g_r_sel = 2'b10;
        q_out_w_sel = 2'b10;
        d_ready_sel = 1'b0;
        mac_sel = 3'b0;
        in_matrix_sel = 3'b1;
        count_sel = 2'b00;
        new_sel = 2'b1;
        write_out_sel = 2'b10;
        write_en_sel = 2'b10;

        next_state = s5;
      end

      s5 : begin                      //input matrix B
        qm_sel = 2'b10;
        q_in_r_sel = 2'b01;
        q_g_r_sel = 2'b10;
        q_out_w_sel = 2'b10;
        d_ready_sel = 1'b0;
        mac_sel = 3'b0;
        in_matrix_sel = 3'b10;
        count_sel = 2'b00;
        new_sel = 2'b1;
        write_out_sel = 2'b10;
        write_en_sel = 2'b10;

        next_state = s6;
      end

      s6 : begin                        //input matrix C
        qm_sel = 2'b10;
        q_in_r_sel = 2'b10;
        q_g_r_sel = 2'b10;
        q_out_w_sel = 2'b10;
        d_ready_sel = 1'b0;
        mac_sel = 3'b0;
        in_matrix_sel = 3'b11;
        count_sel = 2'b00;
        new_sel = 2'b1;
        write_out_sel = 2'b10;
        write_en_sel = 2'b10;

        next_state = s7;
      end

      s7 : begin                        //input matrix D
        qm_sel = 2'b10;
        q_in_r_sel = 2'b10;
        q_g_r_sel = 2'b01;
        q_out_w_sel = 2'b10;
        d_ready_sel = 1'b0;
        mac_sel = 3'b0;
        in_matrix_sel = 3'b100;
        count_sel = 2'b10;
        new_sel = 2'b1;
        write_out_sel = 2'b10;
        write_en_sel = 2'b10;

        next_state = s8;
      end

      s8 : begin                        //matrix multiplication on A
        qm_sel = 2'b10;
        q_in_r_sel = 2'b10;
        q_g_r_sel = 2'b01;
        q_out_w_sel = 2'b10;
        d_ready_sel = 1'b0;
        mac_sel = 3'b1;
        in_matrix_sel = 3'b0;
        count_sel = 2'b01;
        new_sel = 2'b1;
        write_out_sel = 2'b10;
        write_en_sel = 2'b10;

        next_state = s9;
      end 

      s9 : begin                        //matrix multiplication on B
        qm_sel = 2'b10;
        q_in_r_sel = 2'b10;
        q_g_r_sel = 2'b01;
        q_out_w_sel = 2'b10;
        d_ready_sel = 1'b0;
        mac_sel = 3'b10;
        in_matrix_sel = 3'b0;
        count_sel = 2'b10;
        new_sel = 2'b1;
        write_out_sel = 2'b10;
        write_en_sel = 2'b10;

        next_state = s10;
      end

      s10 : begin                       //matrix multiplication on C
        qm_sel = 2'b10;
        q_in_r_sel = 2'b10;
        q_g_r_sel = 2'b01;
        q_out_w_sel = 2'b10;
        d_ready_sel = 1'b0;
        mac_sel = 3'b11;
        in_matrix_sel = 3'b0;
        count_sel = 2'b10;
        new_sel = 2'b1;
        write_out_sel = 2'b10;
        write_en_sel = 2'b10;

        next_state = s11;
      end

      s11 : begin                       //matrix multiplication on D
        qm_sel = 2'b10;
        q_in_r_sel = 2'b10;
        q_g_r_sel = 2'b10;
        q_out_w_sel = 2'b10;
        d_ready_sel = 1'b0;
        mac_sel = 3'b100;
        in_matrix_sel = 3'b0;
        count_sel = 2'b10;
        new_sel = 2'b1;
        write_out_sel = 2'b10;
        write_en_sel = 2'b10;

        next_state = s12;
      end

      s12 : begin                       //set new matrix value to designated input matrix value
        qm_sel = 2'b10;
        q_in_r_sel = 2'b10;
        q_g_r_sel = 2'b01;
        q_out_w_sel = 2'b10;
        d_ready_sel = 1'b0;
        mac_sel = 3'b0;
        in_matrix_sel = 3'b0;
        count_sel = 2'b10;
        new_sel = 2'b10;
        write_out_sel = 2'b10;
        write_en_sel = 2'b10;

        if(counter == 3'b00) begin
          next_state = s13;
          q_g_r_sel = 2'b10;
          qm_sel = 2'b11;
        end
        else
          next_state = s8;
      end

      s13 : begin                       //check for another operator matrix
        qm_sel = 2'b10;
        q_in_r_sel = 2'b10;
        q_g_r_sel = 2'b10;
        q_out_w_sel = 2'b10;
        d_ready_sel = 1'b0;
        mac_sel = 3'b0;
        in_matrix_sel = 3'b101;
        count_sel = 2'b00;
        new_sel = 2'b10;
        write_out_sel = 2'b10;
        write_en_sel = 2'b10;

        if(m_reg == 64'b0) 
          next_state = s14;
        else begin
          next_state = s8;
          q_g_r_sel = 2'b01;
        end

      end

      s14 : begin                       //begin write to q_output_sram
        qm_sel = 2'b10;
        q_in_r_sel = 2'b10;
        q_g_r_sel = 2'b10;
        q_out_w_sel = 2'b00;
        d_ready_sel = 1'b0;
        mac_sel = 3'b0;
        in_matrix_sel = 3'b0;
        count_sel = 2'b01;
        new_sel = 2'b10;
        write_out_sel = 2'b01;
        write_en_sel = 2'b1;

        if(counter < 3'b100)
          q_out_w_sel = 2'b01;
        
        if(counter == 3'b1) 
          next_state = s15;
        else
          next_state = s14;
      end

      s15 : begin                       //finish write to q_output_sram
        qm_sel = 2'b10;
        q_in_r_sel = 2'b10;
        q_g_r_sel = 2'b10;
        q_out_w_sel = 2'b10;
        d_ready_sel = 1'b0;
        mac_sel = 3'b0;
        in_matrix_sel = 3'b0;
        count_sel = 2'b10;
        new_sel = 2'b10;
        write_out_sel = 2'b10;
        write_en_sel = 2'b1;

        next_state = s0;
      end

      default : begin
        qm_sel = 2'b10;
        q_in_r_sel = 2'b10;
        q_g_r_sel = 2'b10;
        q_out_w_sel = 2'b10;
        d_ready_sel = 1'b1;
        mac_sel = 3'b0;
        in_matrix_sel = 3'b111;
        count_sel = 2'b10;
        new_sel = 2'b10;
        write_out_sel = 2'b0;
        write_en_sel = 2'b0;

        next_state = s0;
      end
    endcase
  end


//---------------------------------------------------------------------------
//DATAPATH
//---------------------------------------------------------------------------

  //Q_STATE_INPUT
  //read address register
  always@(posedge clk) begin
    if(q_in_r_sel == 2'b00)
      q_state_input_sram_read_address_r <= 32'b0;
    else if(q_in_r_sel == 2'b01)
      q_state_input_sram_read_address_r <= q_state_input_sram_read_address_r + 32'b1;
    else 
      q_state_input_sram_read_address_r <= q_state_input_sram_read_address_r;
  end

  //Q_GATES
  //read address register
  always@(posedge clk) begin
    if(q_g_r_sel == 2'b00)
      q_gates_sram_read_address_r <= 32'b0;
    else if(q_g_r_sel == 2'b01)
      q_gates_sram_read_address_r <= q_gates_sram_read_address_r + 32'b1;
    else 
      q_gates_sram_read_address_r <= q_gates_sram_read_address_r;
  end

  //Q_STATE_OUTPUT
  //write address register
  always@(posedge clk) begin
    if(q_out_w_sel == 2'b00)
      q_state_output_sram_write_address_r <= 32'b0;
    else if(q_out_w_sel == 2'b01)
      q_state_output_sram_write_address_r <= q_state_output_sram_write_address_r + 32'b1;
    else
      q_state_output_sram_write_address_r <= q_state_output_sram_write_address_r;
  end

  //write data register
  always@(posedge clk) begin
    if (write_out_sel == 2'b0)
      q_state_output_sram_write_data_r <= 0;
    else if(write_out_sel == 2'b01) begin
      if(counter == 3'b100)
        q_state_output_sram_write_data_r[127:64] <= reg_a;
      else if(counter == 3'b11)
        q_state_output_sram_write_data_r[127:64] <= reg_b;
      else if(counter == 3'b10)
        q_state_output_sram_write_data_r[127:64] <= reg_c;
      else if(counter == 3'b1)
        q_state_output_sram_write_data_r[127:64] <= reg_d;
    end
    else if (write_out_sel == 2'b10)
      q_state_output_sram_write_data_r <= q_state_output_sram_write_data_r;
  end

  //write enable register
  always@(posedge clk) begin
    if(write_en_sel == 2'b0)
      q_state_output_sram_write_enable_r <= 1'b0;
    else if(write_en_sel == 2'b1)
      q_state_output_sram_write_enable_r <= 1'b1;
    else if(write_en_sel == 2'b10)
      q_state_output_sram_write_enable_r <= q_state_output_sram_write_enable_r;
  end

  //MISC REGISTERS
  //dut_ready register
  always@(posedge clk) begin
    if(d_ready_sel == 1'b0)
      dut_ready_r <= 1'b0;
    else
      dut_ready_r <= 1'b1;
  end

  //counter register
  always@(posedge clk) begin
    if(count_sel == 2'b00)
      counter <= 3'b100;
    else if(count_sel == 2'b01)
      counter <= counter - 3'b1;
    else if(count_sel == 2'b10)
      counter <= counter;
  end
  
  //qubits and op matrix register
  always@(posedge clk) begin
    if(qm_sel == 2'b00) begin
      q_reg <= 64'b0;
      m_reg <= 64'b0;
    end
    else if(qm_sel == 2'b01) begin
      q_reg <= q_state_input_sram_read_data[127:64];
      m_reg <= q_state_input_sram_read_data[63:0];
    end
    else if (qm_sel == 2'b10) begin
      q_reg <= q_reg;
      m_reg <= m_reg;
    end
    else if(qm_sel == 2'b11) begin
      q_reg <= q_reg;
      m_reg <= m_reg - 1;
    end
  end

  //input matrix registers
  always@(posedge clk) begin
    if(in_matrix_sel == 3'b0) begin
      reg_a <= reg_a;
      reg_b <= reg_b;
      reg_c <= reg_c;
      reg_d <= reg_d;
    end
    else if(in_matrix_sel == 3'b1) begin
      reg_a <= q_state_input_sram_read_data[127:64];
      reg_b <= reg_b;
      reg_c <= reg_c;
      reg_d <= reg_d;
    end
    else if(in_matrix_sel == 3'b10) begin
      reg_a <= reg_a;
      reg_b <= q_state_input_sram_read_data[127:64];
      reg_c <= reg_c;
      reg_d <= reg_d;
    end
    else if(in_matrix_sel == 3'b11) begin
      reg_a <= reg_a;
      reg_b <= reg_b;
      reg_c <= q_state_input_sram_read_data[127:64];
      reg_d <= reg_d;
    end
    else if(in_matrix_sel == 3'b100) begin
      reg_a <= reg_a;
      reg_b <= reg_b;
      reg_c <= reg_c;
      reg_d <= q_state_input_sram_read_data[127:64];
    end
    else if(in_matrix_sel == 3'b101) begin
      reg_a <= new_a;
      reg_b <= new_b;
      reg_c <= new_c;
      reg_d <= new_d;
    end
    else begin
      reg_a <= 0;
      reg_b <= 0;
      reg_c <= 0;
      reg_d <= 0;
    end

  end

  //dw_fp_mac registers
  always@(posedge clk) begin
    if(mac_sel == 3'b0) begin
      inst_a <= 0;
      inst_b <= 0;
      inst_c <= 0;
      inst_rnd <= 0;
    end
    else if(mac_sel == 3'b1) begin
      inst_a <= q_gates_sram_read_data[127:64];
      inst_b <= reg_a;
      inst_c <= z_inst;                  //sets to 0
      inst_rnd <= 0;

    end
    else if(mac_sel == 3'b10) begin
      inst_a <= q_gates_sram_read_data[127:64];
      inst_b <= reg_b;
      inst_c <= z_inst;
      inst_rnd <= 0;
    end

    else if(mac_sel == 3'b11) begin
      inst_a <= q_gates_sram_read_data[127:64];
      inst_b <= reg_c;
      inst_c <= z_inst;
      inst_rnd <= 0;
    end

    else if(mac_sel == 3'b100) begin
      inst_a <= q_gates_sram_read_data[127:64];
      inst_b <= reg_d;
      inst_c <= z_inst;
      inst_rnd <= 0;
    end
  end

  //iutput matrix registers
  always@(posedge clk) begin
    if(new_sel == 2'b0) begin
      new_a <= 0;
      new_b <= 0;
      new_c <= 0;
      new_d <= 0;
    end
    else if(new_sel == 2'b1) begin
      new_a <= new_a;
      new_b <= new_b;
      new_c <= new_c;
      new_d <= new_d;
    end
    else if(new_sel == 2'b10) begin 
      if(counter == 3'b11) begin
        new_a <= z_inst;
        new_b <= new_b;
        new_c <= new_c;
        new_d <= new_d;
      end
      else if(counter == 3'b10) begin
        new_a <= new_a;
        new_b <= z_inst;
        new_c <= new_c;
        new_d <= new_d;
      end
      else if(counter == 3'b1) begin
        new_a <= new_a;
        new_b <= new_b;
        new_c <= z_inst;
        new_d <= new_d;
      end
      else if(counter == 3'b0) begin
        new_a <= new_a;
        new_b <= new_b;
        new_c <= new_c;
        new_d <= z_inst;
      end
    end
  end


  //assign statements
  assign dut_ready = dut_ready_r;

  assign q_state_input_sram_read_address = q_state_input_sram_read_address_r;
  assign q_state_input_sram_write_address = 0;
  assign q_state_input_sram_write_data = 0;
  assign q_state_input_sram_write_enable = 0;

  assign q_state_output_sram_write_address = q_state_output_sram_write_address_r;
  assign q_state_output_sram_write_data = q_state_output_sram_write_data_r;
  assign q_state_output_sram_write_enable = q_state_output_sram_write_enable_r;
 
  assign q_gates_sram_read_address = q_gates_sram_read_address_r;
  assign q_gates_sram_write_address = 0;
  assign q_gates_sram_write_data = 0;
  assign q_gates_sram_write_enable = 0;



  // This is test stub for passing input/outputs to a DP_fp_mac, there many
  // more DW macros that you can choose to use
  DW_fp_mac_inst FP_MAC1 ( 
    inst_a,
    inst_b,
    inst_c,
    inst_rnd,
    z_inst,
    status_inst
  );

endmodule


module DW_fp_mac_inst #(
  parameter inst_sig_width = 52,
  parameter inst_exp_width = 11,
  parameter inst_ieee_compliance = 1 // These need to be fixed to decrease error //CHANGED TO 1
) ( 
  input wire [inst_sig_width+inst_exp_width : 0] inst_a,
  input wire [inst_sig_width+inst_exp_width : 0] inst_b,
  input wire [inst_sig_width+inst_exp_width : 0] inst_c,
  input wire [2 : 0] inst_rnd,
  output wire [inst_sig_width+inst_exp_width : 0] z_inst,
  output wire [7 : 0] status_inst
);

  // Instance of DW_fp_mac
  DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 (
    .a(inst_a),
    .b(inst_b),
    .c(inst_c),
    .rnd(inst_rnd),
    .z(z_inst),
    .status(status_inst) 
  );

endmodule

