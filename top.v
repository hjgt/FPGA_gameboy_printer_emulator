
//`timescale <time_units> / <precision>

module top
(
    input       wire        clk             ,
    input       wire        btn             ,
    /****************iwo*********************/
    input       wire        spi_clk         ,
    input       wire        spi_mosi        ,
    output      wire        spi_miso        ,        
    /***************signal*******************/
    output      wire        uat        
);
wire     clk_7p373m;
wire     clk_4p373m;

  clk_wiz_0 clk_wiz_0
   (
    // Clock out ports
    .clk_out1(clk_7p373m),     // output clk_out1
    .clk_out2(clk_4p373m),     // output clk_out2
   // Clock in ports
    .clk_in1(clk));      // input clk_in1

//-------------------------------iwo-----------------------------------------
wire[7:0]  rcv_data;
wire[7:0]  trans_data;
wire       int;

spi_slv #(
    .DATA_WIDTH     (8              ))
U0_spi_slv(
    .clk            (clk_7p373m     ),
    .srst           (1'b0           ),
    .spi_le         (1'b0           ),
    .spi_clk        (spi_clk        ),
    .spi_da         (spi_mosi       ),
    .spi_da_o       (spi_miso       ),
    .din            (trans_data     ),
    .dout           (rcv_data       ),
    .dout_en        (int            ),
    .spi_en         (               )
);

//-------------------------------rx_ram--------------------------------------
dbg_rx_ram U0_dbg_rx_ram
(
    .clk             (clk_7p373m      ),
    .srst            (1'b0            ),
    .rx_dout         (rcv_data        ),
    .uar_en          (int             ),
    .trans_data      (trans_data      )
);
//-------------------------------uat-----------------------------------------
wire        tx_ready;

reg[15:0]  int_dly = 0;
reg[ 7:0]  mix_data = 0;
always @(posedge clk_7p373m)begin
    int_dly <= {int_dly[14:0],int};
end
always @(posedge clk_7p373m)begin
    if (int_dly[10])begin
        mix_data <= (trans_data == 8'h0) ? rcv_data : trans_data;
    end
end



uat #(
    .SAMPLE_RATE     (64              ),//clk_rate/baud_rate
    .VERIFY_EN       (0               ),//1 = enable
    .VERIFY_MODE     (0               ))//0 = even , 1 = odd
U0_uat(                               
    .clk             (clk_7p373m      ),
    .srst            (1'b0            ),
    .tx_ptct_bit     (4'b1            ),
    .tx_din          (mix_data        ),
    .tx_cmd          (int_dly[15]     ),//trig'd when change level
    .tx_ready        (tx_ready        ),
    .txd             (uat             )
);



ila_0 ila_0 (
	.clk(clk), // input wire clk
	.probe0({spi_clk,spi_mosi,spi_miso}), // input wire [2:0] probe0
	.probe1(0) // input wire [2:0] probe0
);

endmodule

