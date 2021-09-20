
//`timescale 1ns/1ns

module spi_slv #(
    parameter DATA_WIDTH = 8                    //Max = 255               
)(
    input       wire                clk      ,
    input       wire                srst     ,
    input       wire                spi_le   ,   //isp
    input       wire                spi_clk  ,   //icb
    input       wire                spi_da   ,   //iwo
    output      wire                spi_da_o ,
    input       wire[DATA_WIDTH-1:0]din      ,   //-- {Parallel data}
    output      reg[DATA_WIDTH-1:0] dout     ,   //-- {Parallel data}
    output      reg                 dout_en  ,   //-- dout enable,rcved DATA_WIDTH bits.
    output      wire                spi_en       //-- spi enable
);

//=============================================================================
//* include
//=============================================================================
`include "time_map.vh" 
`include "clogb2.vh"

  //------------------------------------//
 //             parameter              //
//------------------------------------//   
parameter   PTCT_TIME  = TIME_150uS;   
//[when recived END flag of uart,count xxuS,then stop recive.]
parameter   PTCT_TIMES_WIDTH = clogb2(PTCT_TIME+1);

parameter   DLY_TIME  = TIME_50uS;   
//[when recived END flag of uart,count xxuS,then stop recive.]
parameter   DLY_TIMES_WIDTH = clogb2(DLY_TIME+1);
//---------------------------------//
//---------------------------------//
reg       dout_full;
reg [2:0] dout_full_r;
//-----------sync_clk-------------
reg[3:0] spi_clk_r = 4'b1111;
always @(posedge clk)begin
    if(srst)
        spi_clk_r   <= 4'b1111;
    else
        spi_clk_r   <= {spi_clk_r[2:0],spi_clk};
end

reg spi_clk_pose = 1'b0;
always @(posedge clk)begin
    if (spi_clk_r == 4'b0011)
        spi_clk_pose    <= 1'b1;
    else
        spi_clk_pose    <= 1'b0;
end

reg spi_clk_neg = 1'b0;
always @(posedge clk)begin
    if(srst)
        spi_clk_neg 	<= 1'b0;
    else if (spi_clk_r == 4'b1100)
        spi_clk_neg 	<= 1'b1;
    else
        spi_clk_neg 	<= 1'b0;
end
//--------------------------time_ptct-----------------------------
reg[PTCT_TIMES_WIDTH-1:0]   time_cnt  =  PTCT_TIME ;
always @(posedge clk)begin
    if(srst)
        time_cnt   <= PTCT_TIME;
    else if (spi_clk_pose)
        time_cnt   <= {PTCT_TIMES_WIDTH{1'b0}};
    else if (time_cnt == PTCT_TIME)
        time_cnt   <= PTCT_TIME;
    else
        time_cnt   <= time_cnt + 1'b1;
end

//--------------------------time_ptct-----------------------------
reg[DLY_TIMES_WIDTH-1:0]   dly_time_cnt  =  DLY_TIME ;
always @(posedge clk)begin
    if(srst)
        dly_time_cnt   <= DLY_TIME;
    else if (dout_full)
        dly_time_cnt   <= {DLY_TIMES_WIDTH{1'b0}};
    else if (dly_time_cnt == DLY_TIME)
        dly_time_cnt   <= DLY_TIME;
    else
        dly_time_cnt   <= dly_time_cnt + 1'b1;
end

//-----------sync_da--------------
reg[1:0] spi_da_r = 2'b00;
always @(posedge clk)begin
    spi_da_r    <= {spi_da_r[0],spi_da};
end

//-------------read---------------
reg[7:0] clk_cnt = 8'h0;
always @(posedge clk)begin
   if(dout_full == 1'b1)
       clk_cnt  <= 8'h0;
   else if(time_cnt == PTCT_TIME-1)
       clk_cnt  <= 8'h0;
   else if((spi_clk_pose))begin
       clk_cnt  <= clk_cnt + 1'h1;
   end
end

reg[DATA_WIDTH-1:0] shifter = {DATA_WIDTH{1'b0}};
always @(posedge clk)begin
    if(dout_full_r[2])
        shifter     <= {DATA_WIDTH{1'b0}};
    else if((spi_clk_pose))
        shifter     <= {shifter[DATA_WIDTH-2:0],spi_da_r[1]};
end

//-------------write---------------
//@first negedge shift,so +1
reg[DATA_WIDTH:0] shifter_o = {(DATA_WIDTH+1){1'b0}};
always @(posedge clk)begin
    if(dly_time_cnt == DLY_TIME - 1)
        shifter_o 	<= {1'b0,din};
    else if(spi_clk_neg)
        shifter_o 	<= {shifter_o[DATA_WIDTH-1:0],1'b0};
end
assign spi_da_o = shifter_o[DATA_WIDTH];

//------------dout----------------
always @(posedge clk)begin
   if(srst)
       dout_full    <= 1'b0;
   else if(clk_cnt == DATA_WIDTH)
       dout_full    <= 1'b1;
   else
       dout_full    <= 1'b0;
end


always @(posedge clk)begin
    dout_full_r     <= {dout_full_r[1:0],dout_full};
end

always @(posedge clk)begin
    if (dout_full_r[2])
        dout_en     <= 1'b1;
    else
        dout_en     <= 1'b0;
end

always @(posedge clk)begin
    if(dout_full_r == 3'b001)begin
        dout    <= shifter;
    end
end

assign spi_en = 0;



endmodule