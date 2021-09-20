

//`timescale <time_units> / <precision>

module dbg_rx_ram
(
    input       wire        clk             ,
    input       wire        srst            ,
    /****************uart*******************/ 
    input       wire[7:0]   rx_dout         ,
    input       wire        uar_en          ,
    /***************signal******************/  
    output      reg[7:0]    trans_data
);

//=============================================================================
//* include
//=============================================================================
`include "time_map.vh" 
`include "clogb2.vh"

/*reg[7:0] rom[0:32768];

// Read headers & ROM from files
initial
begin
    $readmemh("rom.hex",rom, 0, 32768);
end*/
  //------------------------------------//
 //             parameter              //
//------------------------------------//   
parameter   PTCT_TIME  = TIME_2S;   
//[when recived END flag of uart,count xxuS,then stop recive.]
parameter   PTCT_TIMES_WIDTH = clogb2(PTCT_TIME+1);
//---------------------------------//

//--------------------------time_ptct-----------------------------
reg[PTCT_TIMES_WIDTH-1:0]   time_cnt  =  PTCT_TIME ;

always @(posedge clk)begin
    if(srst)
        time_cnt   <= PTCT_TIME;
    else if (uar_en)
        time_cnt   <= {PTCT_TIMES_WIDTH{1'b0}};
    else if (time_cnt == PTCT_TIME)
        time_cnt   <= PTCT_TIME;
    else
        time_cnt   <= time_cnt + 1'b1;
end

reg    time_out_flag = 1'b0;
always @(posedge clk)begin
    if(srst)
        time_out_flag   <= 1'b0;
    else if (time_cnt == PTCT_TIME-1)
        time_out_flag   <= 1'b1;
    else
        time_out_flag   <= 1'b0;
end

//--------------------------uar_en-----------------------------
reg[2:0] uar_en_r = 3'b0;
always @(posedge clk)begin
    if(srst)
        uar_en_r   <= 3'b0;
    else
        uar_en_r   <= {uar_en_r[2:0],uar_en};
end


reg uar_en_flag = 1'b0;
always @(posedge clk)begin
    if (uar_en_r == 3'b001)
        uar_en_flag   <= 1'b1;
    else
        uar_en_flag   <= 1'b0;
end

//--------------------------uar_cnt-----------------------------
reg[15:0]    uar_cnt = 8'd0 ;
always @(posedge clk)begin
    if(time_out_flag)
        uar_cnt   <= 16'd0;
    else if (uar_en_flag)
        uar_cnt   <= uar_cnt + 1'b1;
end

//--------------------------data-----------------------------
always @(posedge clk)begin
    case(uar_cnt)
    8,(18+640*1),(28+640*1),(38+640*2),(48+640*3),(58+640*3),(68+640*4),(78+640*5),(88+640*5),(98+640*6),(108+640*7),(118+640*7),(128+640*8),(138+640*9),(152+640*9),(162+640*9),(172+640*9),(182+640*9),(192+640*9),(202+640*9),(212+640*9):trans_data <= 8'h81;
	29+640*1,39+640*2,49+640*3,59+640*3,69+640*4,79+640*5,89+6405,99+640*6,109+640*7,119+640*7,129+640*8,139+640*9,153+640*9,163+640*9:trans_data <= 8'h08;
	173+640*9,183+640*9,193+640*9,203+640*9:trans_data <= 8'h06;
	213+640*9:trans_data <= 8'h04;
    default:trans_data <= 8'h0;
    endcase
end

/*
0  1  2  3  4  5  6  7  8  9
88 33 01 00 00 00 01 00 81 00
10                          18+640*1 
88 33 04 00 80 02 [640byte] xx xx 81 00
20                28+640*1 29+640*1 
88 33 0F 00 00 00 0F 00 81 08
30                          38+640*2 39+640*2                               
88 33 04 00 80 02 [640byte] xx xx 81 08
40                          48+640*3 49+640*3   
88 33 04 00 80 02 [640byte] xx xx 81 08
50                58+640*3 59+640*3 
88 33 0F 00 00 00 0F 00 81 08
60                          68+640*4 69+640*4   
88 33 04 00 80 02 [640byte] xx xx 81 08
70                          78+640*5 79+640*5   
88 33 04 00 80 02 [640byte] xx xx 81 08
80                88+640*5 89+640*5 
88 33 0F 00 00 00 0F 00 81 08
90                          98+640*6 99+640*6   
88 33 04 00 80 02 [640byte] xx xx 81 08
100                        108+640*7 109+640*7   
88 33 04 00 80 02 [640byte] xx xx 81 08
110              118+640*7 119+640*7 
88 33 0F 00 00 00 0F 00 81 08
120                        128+640*8 129+640*8   
88 33 04 00 80 02 [640byte] xx xx 81 08
130                        138+640*9 139+640*9 
88 33 04 00 80 02 [640byte] xx xx 81 08
140                          152+640*9 153+640*9 
88 33 02 00 04 00 01 13 E4 40 3E 01 81 08
154              162+640*9 163+640*9 
88 33 0F 00 00 00 0F 00 81 08
164              172+640*9 173+640*9 
88 33 0F 00 00 00 0F 00 81 06
174              182+640*9 183+640*9 
88 33 0F 00 00 00 0F 00 81 06
184              192+640*9 193+640*9 
88 33 0F 00 00 00 0F 00 81 06
194              202+640*9 203+640*9 
88 33 0F 00 00 00 0F 00 81 06
204              212+640*9 213+640*9 
88 33 0F 00 00 00 0F 00 81 04
*/



endmodule

