`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.05.2026 15:39:46
// Design Name: 
// Module Name: alu_param
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module alu_param #(parameter width = 8, c = 4) (clk, rst, inp_valid, mode, cmd, ce, opa, opb, cin, err, res, oflow, cout, g, l, e);

input clk, rst, mode, ce, cin;
input [1:0] inp_valid;
input [c-1:0] cmd;
input [width-1:0] opa, opb;

output reg err, oflow, cout, g, l, e;
output reg [2*width:0] res;

reg [1:0] count1, count2;
reg [width-1:0] temp1, temp2;
reg [2*width:0] temp_res;
reg [2*width:0] temp_sum;


reg        s1_err, s1_oflow, s1_cout, s1_g, s1_l, s1_e;
reg [2*width:0] s1_res;
reg        s1_mul; 

localparam shift_width = $clog2(width);
wire [shift_width-1:0] rot_amt;
assign rot_amt = opb[shift_width-1:0];


always @(posedge clk or posedge rst) begin
    if (rst) begin
        s1_err   <= 1'b0;
        s1_res   <= {(2*width+1){1'b0}};
        s1_oflow <= 1'b0;
        s1_cout  <= 1'b0;
        s1_g     <= 1'b0;
        s1_l     <= 1'b0;
        s1_e     <= 1'b0;
        s1_mul   <= 1'b0;
    end
    else if (ce) begin
        s1_err   <= 1'b0;
        s1_res   <= {(2*width+1){1'b0}};
        s1_oflow <= 1'b0;
        s1_cout  <= 1'b0;
        s1_g     <= 1'b0;
        s1_l     <= 1'b0;
        s1_e     <= 1'b0;
        s1_mul   <= 1'b0;

        if (mode) begin
            case (cmd)
                0: begin
                    if (inp_valid == 2'b11) begin
                        temp_sum  = {1'b0, opa} + {1'b0, opb};
                        s1_res   <= temp_sum;
                        s1_cout  <= temp_sum[width];
                    end
                    else s1_err <= 1'b1;
                end

                1: begin
                    if (inp_valid == 2'b11)
                        s1_res <= opa - opb;
                    else s1_err <= 1'b1;
                end

                2: begin
                    if (inp_valid == 2'b11) begin
                        temp_sum  = {1'b0, opa} + {1'b0, opb} + cin;
                        s1_res   <= temp_sum;
                        s1_cout  <= temp_sum[width];
                    end
                    else s1_err <= 1'b1;
                end

                3: begin
                    if (inp_valid == 2'b11)
                        s1_res <= opa - opb - cin;
                    else s1_err <= 1'b1;
                end

                4: begin
                    if (inp_valid == 2'b01)
                        s1_res <= opa + 1'b1;
                    else s1_err <= 1'b1;
                end

                5: begin
                    if (inp_valid == 2'b01)
                        s1_res <= opa - 1'b1;
                    else s1_err <= 1'b1;
                end

                6: begin
                    if (inp_valid == 2'b10)
                        s1_res <= opb + 1'b1;
                    else s1_err <= 1'b1;
                end

                7: begin
                    if (inp_valid == 2'b10)
                        s1_res <= opb - 1'b1;
                    else s1_err <= 1'b1;
                end

                8: begin
                    if (inp_valid == 2'b11) begin
                        if      (opa > opb)  begin s1_g <= 1'b1; s1_l <= 1'b0; s1_e <= 1'b0; end
                        else if (opa < opb)  begin s1_g <= 1'b0; s1_l <= 1'b1; s1_e <= 1'b0; end
                        else                 begin s1_g <= 1'b0; s1_l <= 1'b0; s1_e <= 1'b1; end
                    end
                    else s1_err <= 1'b1;
                end


                9: begin
                    s1_mul <= 1'b1;
                    if (inp_valid == 2'b11) begin
                        if (count1 == 0) begin
                            temp1    = opa + 1'b1;
                            temp2    = opb + 1'b1;
                            temp_res = temp1 * temp2;
                        end
                        else if (count1 == 2'd2) begin
                            s1_res   <= temp_res;
                            temp1     = opa + 1'b1;
                            temp2     = opb + 1'b1;
                            temp_res  = temp1 * temp2;
                        end
                    end
                    else s1_err <= 1'b1;
                end

                10: begin
                    s1_mul <= 1'b1;
                    if (inp_valid == 2'b11) begin
                        if (count2 == 0) begin
                            temp1    = opa << 1'b1;
                            temp_res = temp1 * opb;
                        end
                        else if (count2 == 2'd2) begin
                            s1_res   <= temp_res;
                            temp1     = opa << 1'b1;
                            temp_res  = temp1 * opb;
                        end
                    end
                    else s1_err <= 1'b1;
                end

                11: begin
                    if (inp_valid == 2'b11) begin
                        temp_sum  = $signed(opa) + $signed(opb);
                        s1_res   <= temp_sum;
                        s1_oflow <= (opa[width-1] & opb[width-1] & ~temp_sum[width-1]) |
                                    (~opa[width-1] & ~opb[width-1] & temp_sum[width-1]);
                        s1_cout  <= temp_sum[width];
                        if      ($signed(opa) > $signed(opb))  begin s1_g <= 1'b1; s1_l <= 1'b0; s1_e <= 1'b0; end
                        else if ($signed(opa) < $signed(opb))  begin s1_g <= 1'b0; s1_l <= 1'b1; s1_e <= 1'b0; end
                        if      ($signed(opa) == $signed(opb)) begin s1_g <= 1'b0; s1_l <= 1'b0; s1_e <= 1'b1; end
                    end
                    else s1_err <= 1'b1;
                end

                12: begin
                    if (inp_valid == 2'b11) begin
                        temp_sum  = $signed(opa) - $signed(opb);
                        s1_res   <= temp_sum;
                        s1_oflow <= (opa[width-1] ^ opb[width-1]) & (opa[width-1] ^ temp_sum[width-1]);
                        s1_cout  <= temp_sum[width];
                        if      ($signed(opa) > $signed(opb))  begin s1_g <= 1'b1; s1_l <= 1'b0; s1_e <= 1'b0; end
                        else if ($signed(opa) < $signed(opb))  begin s1_g <= 1'b0; s1_l <= 1'b1; s1_e <= 1'b0; end
                        if      ($signed(opa) == $signed(opb)) begin s1_g <= 1'b0; s1_l <= 1'b0; s1_e <= 1'b1; end
                    end
                    else s1_err <= 1'b1;
                end

                default: begin
                    s1_err   <= 1'b0;
                    s1_res   <= {(2*width+1){1'b0}};
                    s1_oflow <= 1'b0;
                    s1_cout  <= 1'b0;
                    s1_g     <= 1'b0;
                    s1_l     <= 1'b0;
                    s1_e     <= 1'b0;
                end
            endcase
        end

        else if (!mode) begin
            case (cmd)
                0:  begin if (inp_valid == 2'b11) s1_res <=  (opa & opb); else s1_err <= 1'b1; end
                1:  begin if (inp_valid == 2'b11) s1_res <= ~(opa & opb); else s1_err <= 1'b1; end
                2:  begin if (inp_valid == 2'b11) s1_res <=  (opa | opb); else s1_err <= 1'b1; end
                3:  begin if (inp_valid == 2'b11) s1_res <= ~(opa | opb); else s1_err <= 1'b1; end
                4:  begin if (inp_valid == 2'b11) s1_res <=  (opa ^ opb); else s1_err <= 1'b1; end
                5:  begin if (inp_valid == 2'b11) s1_res <= ~(opa ^ opb); else s1_err <= 1'b1; end
                6:  begin if (inp_valid == 2'b01) s1_res <= ~opa;          else s1_err <= 1'b1; end
                7:  begin if (inp_valid == 2'b10) s1_res <= ~opb;          else s1_err <= 1'b1; end
                8:  begin if (inp_valid == 2'b01) s1_res <= opa >> 1'b1;   else s1_err <= 1'b1; end
                9:  begin if (inp_valid == 2'b01) s1_res <= opa << 1'b1;   else s1_err <= 1'b1; end
                10: begin if (inp_valid == 2'b10) s1_res <= opb >> 1'b1;   else s1_err <= 1'b1; end
                11: begin if (inp_valid == 2'b10) s1_res <= opb << 1'b1;   else s1_err <= 1'b1; end

                12: begin
                    if (inp_valid == 2'b11) begin
                        s1_err <= |opb[width-1:width/2];
                        if (rot_amt == 0)
                            s1_res <= {{width+1{1'b0}}, opa};
                        else
                            s1_res <= {{width+1{1'b0}}, ((opa << rot_amt) | (opa >> (width - rot_amt)))};
                    end
                    else begin
                        s1_err <= 1'b1;
                        s1_res <= {(2*width+1){1'b0}};
                    end
                end

                13: begin
                    if (inp_valid == 2'b11) begin
                        s1_err <= |opb[width-1:width/2];
                        if (rot_amt == 0)
                            s1_res <= {{width+1{1'b0}}, opa};
                        else
                            s1_res <= {{width+1{1'b0}}, ((opa >> rot_amt) | (opa << (width - rot_amt)))};
                    end
                    else begin
                        s1_err <= 1'b1;
                        s1_res <= {(2*width+1){1'b0}};
                    end
                end

                default: s1_err <= 1'b1;
            endcase
        end
    end
end


always @(posedge clk or posedge rst) begin
    if (rst) begin
        err   <= 1'b0;
        res   <= {(2*width+1){1'b0}};
        oflow <= 1'b0;
        cout  <= 1'b0;
        g     <= 1'b0;
        l     <= 1'b0;
        e     <= 1'b0;
    end
    else begin
        if (s1_mul) begin
            res   <= s1_res;
            err   <= s1_err;
            oflow <= s1_oflow;
            cout  <= s1_cout;
            g     <= s1_g;
            l     <= s1_l;
            e     <= s1_e;
        end
        else begin
            res   <= s1_res;
            err   <= s1_err;
            oflow <= s1_oflow;
            cout  <= s1_cout;
            g     <= s1_g;
            l     <= s1_l;
            e     <= s1_e;
        end
    end
end


always @(posedge clk or posedge rst) begin
    if (rst) begin
        count1 <= 0;
        count2 <= 0;
    end
    else begin
        if (mode) begin
            case (cmd)
                9: begin
                    if (count1 == 2'd2) count1 <= 1;
                    else                count1 <= count1 + 1'b1;
                end
                10: begin
                    if (count2 == 2'd2) count2 <= 1;
                    else                count2 <= count2 + 1'b1;
                end
                default: begin
                    count1 <= 0;
                    count2 <= 0;
                end
            endcase
        end
        else begin
            count1 <= 0;
            count2 <= 0;
        end
    end
end

endmodule
