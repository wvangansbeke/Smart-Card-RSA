`timescale 1ns / 1ps
`define RESET_TIME 25
`define CLK_PERIOD 10
`define CLK_HALF 5

module tb_montgomery_wrapper#
(
    parameter integer RSA_BITS = 1024
)
(
    );
    
    reg [RSA_BITS-1:0] bram_din;
    reg bram_din_valid;
    wire [RSA_BITS-1:0] bram_dout;
    wire bram_dout_valid;
    reg bram_dout_read;
    reg [31:0] port1_din;
    reg [31:0] port2_dout;    
    reg port1_valid;    
    wire port1_read;   
    wire port2_valid;    
    reg port2_read;
    reg clk;
    reg resetn;
    reg result_ok;
    
    montgomery_wrapper dut(
        .clk(clk),
        .resetn(resetn),
        .bram_din(bram_din),
        .bram_din_valid(bram_din_valid),
        .bram_dout(bram_dout),
        .bram_dout_valid(bram_dout_valid),
        .bram_dout_read(bram_dout_read),
        .port1_din(port1_din),
        .port1_valid(port1_valid),
        .port1_read(port1_read),
        .port2_valid(port2_valid),
        .port2_read(port2_read)
        );
        
    //Generate a clock
    initial begin
        clk = 0;
        forever #`CLK_HALF clk = ~clk;
    end
    
    //Reset
    initial begin
        resetn = 0;
        #`RESET_TIME resetn = 1;
    end
    
    task task_bram_read;
    begin
        $display("Read BRAM: %x",bram_dout);
    end
    endtask
    
    task task_bram_write;
    input [1023:0] data;
    begin
        bram_din_valid <= 1;
        bram_din <= data;
        $display("Write BRAM: %x",data);
        #`CLK_PERIOD;
        bram_din_valid <= 0;
    end
    endtask

    task task_port1_write;
    input [31:0] data;
    begin
        $display("P1=%x",data);
        port1_din=data;
        port1_valid=1;
        port2_dout=0;
        $display("P2=%x",port2_dout);
        #`CLK_PERIOD;
        wait (port1_read==1);        
        port1_valid=0;
        #`CLK_PERIOD;
    end
    endtask
    
    task task_port2_read;
    begin
        port2_read=0;
        wait (port2_valid==1);
        port2_dout=1;
        $display("P2=%x",port2_dout);
        port2_read=1;
        #`CLK_PERIOD;
        #`CLK_PERIOD;
        port2_read=0;
    end
    endtask
    
    initial begin
        forever
        begin
            bram_dout_read=0;
            wait (bram_dout_valid==1);
            //$display("New data available on BRAM: %x",bram_dout);
            bram_dout_read=1;
            #`CLK_PERIOD;
            #`CLK_PERIOD;
        end
    end
    
    initial begin
            bram_din_valid=0;
            port1_valid=0;
            port1_din=0;
            bram_din=0;
            port2_read=0;
    end
    
    initial begin
        #`RESET_TIME
        #1;

        /* The montgomery_wrapper uses port1_write, port2_read, bram_write, and bram_read
        
        /**********************START example command 1*********************/  
        /**************************Example 1*****************************/
        task_port1_write(32'h0); //Perform CMD_READ_A
        task_bram_write(1024'h1);
        task_port2_read(); //Wait for port2_valid to go high.
        
        task_port1_write(32'h3); //Perform CMD_READ_B
        task_bram_write(1024'h2);
        task_port2_read(); //Wait for port2_valid to go high
        
        task_port1_write(32'h4); //Perform CMD_READ_M
        task_bram_write(1024'h3);
        task_port2_read(); //Wait for port2_valid to go high
        
        task_port1_write(32'h1); //Perform CMD_COMPUTE
        task_port2_read(); //Wait for port2_valid to go high.
        
        task_port1_write(32'h2); //Perform CMD_WRITE
        task_port2_read(); //Wait for port2_valid to go high.
        
        result_ok = (bram_dout==1024'h2);
        task_bram_read();
                
        /**************************Example 2*****************************/
        //32'h0 is command that is recognised by montgomery_wrapper. It expects for data to be received from BRAM        
        task_port1_write(32'h0); //Perform CMD_READ_A
        task_bram_write(1024'h1BA);
        task_port2_read(); //Wait for port2_valid to go high.
        
        task_port1_write(32'h3); //Perform CMD_READ_B
        task_bram_write(1024'h91B);
        task_port2_read(); //Wait for port2_valid to go high
        
        task_port1_write(32'h4); //Perform CMD_READ_M
        task_bram_write(1024'hD1D3B4D60ED3982C36A53DD9CFB0450E6887926D199AF8FEE7990185F907210129AB96B24F2E543827028A894DA058EC2DAAE084358E7C2456BA1EB0CF1AE468093C99331D501EA97F89EBB5E1709725DC771F4293ADE44605453C47716A5C3B8E88E8CF2ADE1186BE08BC1E2AB9A7C832DFF4023B9E66F8A677BCE5E67A6F31);
        task_port2_read(); //Wait for port2_valid to go high
        
        task_port1_write(32'h1); //Perform CMD_COMPUTE
        task_port2_read(); //Wait for port2_valid to go high.
        
        task_port1_write(32'h2); //Perform CMD_WRITE
        task_port2_read(); //Wait for port2_valid to go high.
        
        result_ok = (bram_dout==1024'h1C2F4B9109D2397120E291FF465B5C3FFC078DD3DA339DE1A7099FB1FEE2AD7CB3D202291D543E6500C0C2520BC87631723DFF839EFD87A0EFB9603417A14185CB6DBCEAC307D13912051AC9BE7884D0A5F92B1A609298F430B556AFE6D157490CCA5C4ABFB77AFD8C98A5B1F13CAAD7C9DD4C95071A62BDDEF8C811E6F7ADA7);
        task_bram_read();
        
        /**********************End example command 1*********************/        
    end
endmodule
