`timescale 1ns / 1ps

module montgomery_wrapper #
(
    parameter integer RSA_BITS = 1024
)
(
    // The clock
    input clk,
    // Active low reset
    input resetn,
    
    // data_* is used to communicate 1024-bit chunks of data with the ARM
    // A BRAM interface receives data from data_out and writes it into BRAM.
    // The BRAM interface can also receive data from DMA, 
    //   and then write it to BRAM.

    /// bram_din receives data from ARM
    
        // Data is read in 1024-bit chunks from DMA.
        input [RSA_BITS-1:0] bram_din,
        // Indicates that "bram_din" is valid and can be processed by the FSM    
        input bram_din_valid,
    
    /// data_out writes results to ARM
    
        // The result of a computation is stored in data_out. 
        // Only write to "data_out" if you want to store the result
        // of a computation in memory that can be accessed by the ARM 
        output [RSA_BITS-1:0] bram_dout,
        // Indicates that there is a valid data in "bram_dout" 
        // that can be written out to memory
        output bram_dout_valid,
        // After asserting "bram_dout_valid", 
        // wait for the BRAM interface to read it,
        // so wait for "bram_dout_read" to become high before continuing 
        input bram_dout_read,
    
    /// P1 is to receive commands from the ARM
    
        // The data received from port1
        input [31:0] port1_din,
        // Indicates that new data (command) is available on port1
        input port1_valid,
        // Assert "port1_data_read" when the data (command) 
        //    from "port1_data" has been read .
        // This allows new data to arrive on port1
        output port1_read,
    
    /// P2 is to assert "Done" signal to ARM 
    
        // Indicates on port2 that the operation is complete/done 
        output port2_valid, 
        // You should wait until your "port2_valid" signal is read
        // so wait for "port2_read" to become high
        input port2_read,
        output [3:0] leds
    );

    localparam STATE_BITS = 4;    
    localparam STATE_COMPUTE = 4'b0001;
    localparam STATE_WRITE_DATA_OUT = 4'b0010;
    localparam STATE_WRITE_PORT2 = 4'b0011;
    localparam STATE_READ_DATA_A = 4'b0100;
    localparam STATE_READ_DATA_B = 4'b0101;
    localparam STATE_READ_DATA_M = 4'b0110;
    localparam STATE_WRITE_DATA = 4'b0111;
    localparam STATE_WAIT_FOR_CMD = 4'b1000;   
    reg [STATE_BITS-1:0] r_state;
    reg [STATE_BITS-1:0] next_state;
    reg [RSA_BITS-1:0] in_a, in_b, in_m;
    reg start;
    wire [RSA_BITS-1:0] result;
    wire done;
    
    localparam CMD_READ_A=32'h0;
    localparam CMD_READ_B=32'h3;
    localparam CMD_READ_M=32'h4;
    localparam CMD_COMPUTE=32'h1;    
    localparam CMD_WRITE=32'h2;

    montgomery montgomery_instance
                       (.clk(clk),
                        .resetn(resetn),
                        .in_a(in_a),
                        .in_b(in_b),
                        .in_m(in_m),
                        .start(start),
                        .result(result),
                        .done(done)
                        );

always @(*)
    begin
        if (resetn==1'b0)
            next_state <= STATE_WAIT_FOR_CMD;
        else
        begin
            case (r_state)
                STATE_WAIT_FOR_CMD:
                    begin
                        if (port1_valid==1'b1) 
                        begin
                            //Decode the command received on Port1
                            case (port1_din)
                                CMD_READ_A:
                                    next_state <= STATE_READ_DATA_A;
                                CMD_READ_B:
                                    next_state <= STATE_READ_DATA_B;
                                CMD_READ_M:
                                    next_state <= STATE_READ_DATA_M;
                                CMD_COMPUTE:                            
                                    next_state <= STATE_COMPUTE;                                
                                CMD_WRITE: 
                                    next_state <= STATE_WRITE_DATA;
                                default:
                                    next_state <= r_state;
                            endcase;
                        end
                        else
                            next_state <= r_state;
                    end
                
                STATE_READ_DATA_A:
                    //Read the bram_din and store in in_a
                    next_state <= (bram_din_valid==1'b1) ? STATE_WRITE_PORT2 : r_state;
                
                STATE_READ_DATA_B:
                    //Read the bram_din and store in in_b
                    next_state <= (bram_din_valid==1'b1) ? STATE_WRITE_PORT2 : r_state;
                                    
                STATE_READ_DATA_M:
                    //Read the bram_din and store in in_m
                    next_state <= (bram_din_valid==1'b1) ? STATE_WRITE_PORT2 : r_state;
                                                                            
                STATE_COMPUTE: 
                    //Perform a computation on r_tmp
                    begin
                    if (done == 1)
                        next_state <= STATE_WRITE_PORT2;
                    else
                        next_state <= STATE_COMPUTE;
                    end
                
                STATE_WRITE_DATA:
                    //Write r_tmp to bram_dout
                    next_state <= (bram_dout_read==1'b1) ? STATE_WRITE_PORT2 : r_state;
                
                STATE_WRITE_PORT2:
                    //Write a 'done' to Port2
                    next_state <= (port2_read==1'b1) ? STATE_WAIT_FOR_CMD : r_state;
                default:
                    next_state <= r_state;
            endcase
        end
        if (next_state == STATE_COMPUTE) 
            begin
            if (done == 1)
                begin
                start <= 0;
                end
            else
                begin
                start <= 1;
                end
            end
        else
            begin
            start <= 0;
            end
    end

    always @(posedge(clk))
        if (resetn==1'b0)
            r_state <= STATE_WAIT_FOR_CMD;
        else
            r_state <= next_state;
       
    reg [RSA_BITS-1:0] r_tmp;
    always @(posedge(clk))
        if (resetn==1'b0)
        begin
            r_tmp <= {RSA_BITS{1'b0}};
        end
        else
        begin
            case (r_state)
                STATE_READ_DATA_A:
                    if ((bram_din_valid==1'b1))
                        in_a <= bram_din;
                    else
                        in_a <= in_a;
                STATE_READ_DATA_B:
                    if ((bram_din_valid==1'b1))
                        in_b <= bram_din;
                    else
                        begin
                        in_b <= in_b;
                        end 
                STATE_READ_DATA_M:
                    if ((bram_din_valid==1'b1))
                        in_m <= bram_din;
                    else
                        in_m <= in_m;
                STATE_COMPUTE:
                    r_tmp <= result;
                default:
                    r_tmp <= r_tmp;
            endcase;
        end
    
    //Outputs
    reg r_bram_dout_valid;
    reg r_port2_valid;
    reg r_port1_read;
    always @(posedge(clk))
    begin
        r_bram_dout_valid = (r_state==STATE_WRITE_DATA);
        r_port2_valid <= (r_state==STATE_WRITE_PORT2);
        r_port1_read <= ((port1_valid==1'b1) & (r_state==STATE_WAIT_FOR_CMD));
    end
       
    assign bram_dout_valid = r_bram_dout_valid; 
    assign bram_dout = r_tmp;   
    assign port1_read = r_port1_read;
    assign port2_valid = r_port2_valid; 

	  //Debugging signals
		assign leds = 4'b0010;    // the four leds are used as debug signals. Here they are used to check the state transition
endmodule