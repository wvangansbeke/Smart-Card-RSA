`timescale 1ns / 1ps
`define RESET_TIME 25
`define CLK_PERIOD 10
`define CLK_HALF 5

module tb_montgomery(   
    );
    
    reg clk,resetn;
    reg [1023:0] in_a, in_b, in_m;
    reg start;
    wire [1023:0] result;
    reg result_ok;
    wire done;
    
    //Instantiating montgomery module
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
    
    //Test data
    initial begin
        #`RESET_TIME
        
        //First test vector:
        in_a<=1024'h1;
        in_b<=1024'h2;
        in_m<=1024'h3;
        start<=1;
        #`CLK_PERIOD;
        start<=0;
        wait (done==1);
        result_ok = (result==1024'h2);
        $display("result=%x",result);
        #`CLK_PERIOD;
        
        //Second test vector:
        //The test vector that was given in mtgo1024.c on Toledo
        in_a<=1024'h5730CB43EA31061FA94573DE359FC9F14D1CD2FD2243923B9956B646C7199264AA7ADD2C235E3F38E00841A846F45878643D37C0CDF0A30EC5814C21A969C55D5FF4051C8230BFE749021863F321809997411A4D5A704A426F2CC3C0669C8BD5B5990CB0F0EBE0C51CF9D15B672E0BD210BDC42A071AE6D2EC51400290E83B18;
        in_b<=1024'h5730CB43EA31061FA94573DE359FC9F14D1CD2FD2243923B9956B646C7199264AA7ADD2C235E3F38E00841A846F45878643D37C0CDF0A30EC5814C21A969C55D5FF4051C8230BFE749021863F321809997411A4D5A704A426F2CC3C0669C8BD5B5990CB0F0EBE0C51CF9D15B672E0BD210BDC42A071AE6D2EC51400290E83B18;
        in_m<=1024'h5CEFC1C526A44E4F196A2E86809DC0EC882447E5568CCE0C19FFBA87FD975064E76ACC86B576CF6D5BABC44FB8C0B891BECCE05E9A3CE8AEA487EE14643DCC483C46D7E0DAB02388FA8B6B92F346F55638ECAC8B975B79668CBDBB09A82DD132D9D635D68360E64A6F4AFBA0B3F79F6658C227FA5E067888759258C224BBF1F3;
        start<=1;
        #`CLK_PERIOD;
        start<=0;
        wait (done==1);
        result_ok = (result==1024'h0x1C2F4B9109D2397120E291FF465B5C3FFC078DD3DA339DE1A7099FB1FEE2AD7CB3D202291D543E6500C0C2520BC87631723DFF839EFD87A0EFB9603417A14185CB6DBCEAC307D13912051AC9BE7884D0A5F92B1A609298F430B556AFE6D157490CCA5C4ABFB77AFD8C98A5B1F13CAAD7C9DD4C95071A62BDDEF8C811E6F7ADA7);
        $display("result=%x",result);
        #`CLK_PERIOD;
    end
           
endmodule
