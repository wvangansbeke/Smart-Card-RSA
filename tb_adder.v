
`timescale 1ns / 1ps

/*
Goals:
1. Use this testbench (tb) to verify the correctness of your adder
    You can start the simulation by pressing the buttons on the left-hand: Simulation | Run Simulation
2. Implement a multi-precision adder in adder.v
3. Update the design with a two's-compliment subtractor (activate it with the 'subtract' wire)
3. Make an implementation of your design (Implementation | Run Implementation).
4. Determine the maximum clock frequency of the design (Efficient designs have a clock of around 100MHz)
5. Calculate the total execution time of one add operation
*/

`timescale 1ns / 1ps

`define RESET_TIME 25
`define CLK_PERIOD 10
`define CLK_HALF 5

module tb_adder();

  reg clk;
  reg en;
  reg shift;
  reg [1024:0] in_a;
  reg [1024:0] in_b;
  reg start;
  reg subtract;
  reg result_ok;
  reg resetn;
  wire [1025:0] result;
  wire done;

  adder dut
       (.clk(clk),
        .resetn(resetn),
        .shift(shift),
        .in_a(in_a),
        .in_b(in_b),
        .start(start),
        .subtract(subtract),
        .result(result),
        .done(done)
        );

initial begin
    clk = 0;
    forever #`CLK_HALF clk = ~clk;
end

initial begin
    in_a <= 0;
    in_b <= 0;
    subtract <= 0;
    start <= 0;
end

initial begin
    resetn = 0;
    #`RESET_TIME
    resetn = 1;
end

task perform_add;
input [1024:0] a;
input [1024:0] b;
begin
    in_a <= a;
    in_b <= b;
    start <= 1'd1;
    subtract <= 1'd0;
    shift <= 1'd0;
    #`CLK_PERIOD;
    start <= 1'd0;
    shift <= 1'd1;
    wait (done==1);
    #`CLK_PERIOD;
end
endtask

task perform_sub;
input [1024:0] a;
input [1024:0] b;
begin
    in_a <= a;
    in_b <= b;
    start <= 1'd1;
    subtract <= 1'd1;
    shift <= 1'd0;
    #`CLK_PERIOD;
    start <= 1'd0;
    shift <= 1'd1;
    wait (done==1);
    #`CLK_PERIOD;
end
endtask

initial begin
    #`RESET_TIME

    /*************TEST ADDITION*************/
    //Check if 1+1=2
    #`CLK_PERIOD;
    perform_add(1025'h1, 1025'h1);
    wait (done==1);
    result_ok = (result==1026'h2);

    //Test addition with large test vectors. You can generate your own with the magma online calculator
    perform_add(1025'hC58D1976598E58BCF80CE58223DCC6C9D6347A9F7432237557D9D2553F2F0A361103824D74A004740D3A62F6306A901B666B92A279AFBFD099FBFC948A43313BAA5518CB3B98A60D379DEE9C1853D0B25A3A405E282A45E4C0E20B2B336F50A8A189DEBE27B0942C25CC3275BABDF0C70736095D523CAA4D5B709C1804E46B9F,1025'h95681C8BB48038CA739F151EA7D872AE4AB52A9CB231B4D80D4B66401D0B8CC5573108FDE32538A7763FDDD990E5142ADC9825CC425A6806676791EA8BBD40D723495708DF4163882FBD51B00C489AD936CE33EC6EBE11DF4E55047FDDAA14A4B86CB1FF0585A194099C38D2EC232F735D0242132A5E361498F776116F8A8F08);
    wait (done==1);
    #1 result_ok = (result==1026'h0x15AF536020E0E91876BABFAA0CBB5397820E9A53C2663D84D652538955C3A96FB68348B4B57C53D1B837A40CFC14FA4464303B86EBC0A27D701638E7F16007212CD9E6FD41ADA0995675B404C249C6B8B9108744A96E857C40F370FAB1119654D59F690BD2D3635C02F686B48A6E1203A64384B707C9AE061F4681229746EFAA7);


    /*************TEST SUBTRACTION*************/
    //Check if 1-1=0
    #`CLK_PERIOD;
    #`CLK_PERIOD;
    #`CLK_PERIOD;
    perform_sub(1025'h1, 1025'h1);
    wait (done==1);
    result_ok = (result==1026'h0);

    //Test subtraction with large test vectors. You can generate your own with the magma online calculator
    perform_sub(1025'hBE34653930050B12F0863E7CB994546AE84CEA9369D6F9256B5D7B629B9910C1FBC6BE94E625EF9D58E18EDB797CB2F773843A64E6D91B03D77D6159093A9374FD605D416F1723F1021D43356674D1B90E429E93FD2BA155063B0DD091B6209A3431D7E57C9E01F8BD7B2E30B7DA4A9A990EF2DCA1DF1754F93F392B1D7E3BDD,1025'h9C9DFAF0491E464E2F3B80834DC17243FB513DE7415078EB03E6AB2EAAF85F2D04FECA778C072DCC6D7B481123BF61F973DBDFE32FF81F7FBB79370B37D67BE28C1A4B07B1C68DF11F88A27F43116AF293A483E5E0F8042B5CDB064D96035F8073788C5D7CD7FBCA854EDAB5E8BE731C67F3FFAE1F95ACB840162B208B4FC45B);
    wait (done==1);
    result_ok = (result==1026'h21966A48E6E6C4C4C14ABDF96BD2E226ECFBACAC2886803A6776D033F0A0B194F6C7F41D5A1EC1D0EB6646CA55BD50FDFFA85A81B6E0FB841C042A4DD164179271461239BD5095FFE294A0B6236366C67A9E1AAE1C339D29A9600782FBB2C119C0B94B87FFC6062E382C537ACF1BD77E311AF32E82496A9CB9290E0A922E7782);

    end

endmodule

