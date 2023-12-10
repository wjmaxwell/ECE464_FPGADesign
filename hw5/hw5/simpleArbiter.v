//Verilog file for a simple arbiter

module arbiter(clock, reset, R0, R1, G0, G1);

input clock;
input reset;
input R0, R1;
output G0, G1;

parameter [4:0] // synopsys enum states
    S0 = 5'b00001,
    S1 = 5'b00010,
    S2 = 5'b00100,
    S3 = 5'b01000,
    S4 = 5'b10000;

reg [4:0] /* synopsys enum states */ current_state, next_state;
/* synopsys state_vector current_state */
reg G0, G1;

/* sequential logic */
always@(posedge clock or negedge reset)
    if(!reset) current_state <= S0;
    else current_state <= next_state;

/* next state logic and output logic */
always@(current_state or R0 or R1)
    begin
        G0 = 0; G1 = 0;
        case(current_state) // synopsys full_case parallel_case
            S0: 
                begin
                if(R0 && R1) next_state = S3; 
                else if(R0) next_state = S1;
                else if(R1) next_state = S2; 
                else next_state = S0;
                end

            S1: 
                begin
                G0 = 1;
                if(R0 && R1) next_state = S3; 
                else if(R0) next_state = S1;
                else if(R1) next_state = S2; 
                else next_state = S0;
                end

            S2: 
                begin
                G1 = 1;
                if(R0 && R1) next_state = S3; 
                else if(R0) next_state = S1;
                else if(R1) next_state = S2; 
                else next_state = S0;
                end

            S3: 
                begin
                G0 = 1;
                next_state = S4;
                end

            S4: 
                begin 
                G1 = 1;
                if(R0 && R1) next_state = S3; 
                else if(R0) next_state = S1;
                else if(R1) next_state = S2; 
                else next_state = S0;
                end

            default: 
                begin
                next_state = S0;
                end

        endcase
    end

endmodule
