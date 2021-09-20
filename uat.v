
//`timescale 1ns/1ns

module uat #(
   parameter   SAMPLE_RATE   = 16  ,//clk_rate/baud_rate
   parameter   VERIFY_EN     = 0   ,//1 = enable
   parameter   VERIFY_MODE   = 0    //0 = even,1=odd
)(
    input   wire        clk,
    input   wire        srst,
    input   wire[3:0]   tx_ptct_bit,
    input   wire[7:0]   tx_din,
    input   wire        tx_cmd,
    output  reg         tx_ready,
    output  wire        txd
);
//--------------------------------------
parameter   START   = 1'b0;
parameter   STOP    = 1'b1;
//----------------------------
parameter   IDLE    =   4'd0;
parameter   LOAD    =   4'd1;
parameter   SHIFT   =   4'd2;
parameter   PTCT    =   4'd3;
parameter   DFT     =   4'hx;
//--------------------------------------
wire[3:0]   valid_shift_num = 4'd9;
reg [3:0]   tx_state = IDLE;
reg [3:0]   shift_cnt = 4'd0;
reg         shift_en = 1'd0;
reg         baud_gen_en = 1'd0;
reg [9:0]   sample_cnt = 10'h0;
wire        baud_smpl;

always @(posedge clk)begin
   if((baud_gen_en == 1'b0)||(sample_cnt == (SAMPLE_RATE - 1)))
      sample_cnt <= 10'h0;
   else if(baud_gen_en == 1'b1)
      sample_cnt <= sample_cnt + 1'b1; 
end

assign baud_smpl = (sample_cnt == (SAMPLE_RATE - 1))? 1'b1 : 1'b0;

reg[2:0] tx_cmd_r = 3'b0;
always @(posedge clk)begin
    if(srst)
        tx_cmd_r   <= 3'b0;
    else
        tx_cmd_r   <= {tx_cmd_r[1:0],tx_cmd};
end

reg tx_cmd_flag = 1'b0;
always @(posedge clk)begin
    if (tx_cmd_r[2] ^ tx_cmd_r[1])
        tx_cmd_flag   <= 1'b1;
    else
        tx_cmd_flag   <= 1'b0;
end

reg[7:0] din_reg;
always @(posedge clk)begin
    if (tx_cmd_r[2] ^ tx_cmd_r[1])
        din_reg   <= tx_din;
end

always @(posedge clk) begin
        case(tx_state)
            IDLE:begin
                    if(tx_cmd_flag) 
                        tx_state    <= LOAD;
                end
            LOAD:begin
                    tx_state    <= SHIFT;
                end
            SHIFT:begin
                    if((baud_smpl == 1'b1) && (shift_cnt == valid_shift_num)) begin //����ʱ���shift_cnt
                        if(tx_ptct_bit == 4'd0) begin //�ж�ֹͣλ�Ƿ������
                                tx_state    <= IDLE; //������Ч��ת�����                        
                        end
                        else
                            tx_state    <= PTCT;     // ֹͣλδ�������                
                    end
                end
            PTCT:begin
                    if((baud_smpl == 1'b1) && (shift_cnt == tx_ptct_bit - 4'd1)) begin
                            tx_state    <= IDLE;
                    end                         
                end
            default:begin
                    tx_state    <= DFT;
                end
        endcase
end
//---------------
initial begin
   tx_ready = 1'b1;
end

always @(posedge clk) begin   
    if(srst == 1'b1)
        tx_ready        <= 1'b1;
    else if(tx_state == IDLE)
        tx_ready        <= 1'b1;
    else
        tx_ready        <= 1'b0;
end
//---------------����ʹ�� 
always @(posedge clk) begin  
    if(tx_state == LOAD)
        baud_gen_en    <= 1'b1;
    else if(tx_state == IDLE)
        baud_gen_en    <= 1'b0;
end

always @(posedge clk) begin  
    if(tx_state == LOAD)
        shift_en    <= 1'b1;
    else if((tx_state == SHIFT) && (baud_smpl == 1'b1) && (shift_cnt == valid_shift_num))
        shift_en    <= 1'b0;
end

always @(posedge clk) begin  //�Է��͵����ݽ��м���
    if(tx_state == LOAD)
        shift_cnt   <= 4'd0;
    else if((shift_en == 1'b1) && (baud_smpl == 1'b1)) begin //����ʱ���shift_cnt �����������ֹͣλ��Ϊ1 ��ôshift_cnt ��1 ֱ��������ֹͣλ ���ж��Ǽ������ǿ���
        if(shift_cnt == valid_shift_num)
            shift_cnt   <= 4'd0;
        else
            shift_cnt   <= shift_cnt + 1'b1;        
    end
    else if((tx_state == PTCT) && (baud_smpl == 1'b1))
        shift_cnt   <= shift_cnt + 1'b1;
end

reg[10:0]   shift_reg = 11'h7ff;
wire        verify_bit = (^din_reg[7:0]) ^ VERIFY_MODE;
always @(posedge clk) begin
    if(srst == 1'b1)
        shift_reg   <= 11'h7ff;
    else if((tx_state == LOAD)) begin  //��������
        if(VERIFY_EN == 1'b1) 
            shift_reg   <= {STOP,verify_bit,din_reg,START};
        else 
            shift_reg   <= {STOP,STOP,din_reg,START};
    end
    else if((shift_en == 1'b1) && (baud_smpl == 1'b1))      //��������
        shift_reg   <= shift_reg    >> 1;
end
assign  txd = shift_reg[0];


endmodule