`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.05.2026 10:46:57
// Design Name: 
// Module Name: alu_reference_model
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


module alu_reference_model #(parameter width = 8, c = 4) (
    input                  mode,
    input [1:0]            inp_valid,
    input [c-1:0]          cmd,
    input [width-1:0]      opa, opb,
    input                  cin,
 
    output reg             err, oflow, cout, g, l, e,
    output reg [2*width:0] res
);
 
    localparam shift_width = $clog2(width);
    wire [shift_width-1:0] rot_amt;
    assign rot_amt = opb[shift_width-1:0];
 
    reg [2*width:0] temp_sum;
 
    always @(*) begin
        // Safe defaults
        res   = {(2*width+1){1'b0}};
        err   = 1'b0;
        oflow = 1'b0;
        cout  = 1'b0;
        g     = 1'b0;
        l     = 1'b0;
        e     = 1'b0;
 
        if (mode) begin
            case (cmd)
                // CMD 0: Unsigned ADD
                0: begin
                    if (inp_valid == 2'b11) begin
                        temp_sum = {1'b0, opa} + {1'b0, opb};
                        res  = temp_sum;
                        cout = temp_sum[width];
                    end else err = 1'b1;
                end
 
                // CMD 1: Unsigned SUB
                1: begin
                    if (inp_valid == 2'b11)
                        res = opa - opb;
                    else err = 1'b1;
                end
 
                // CMD 2: ADD with CIN
                2: begin
                    if (inp_valid == 2'b11) begin
                        temp_sum = {1'b0, opa} + {1'b0, opb} + cin;
                        res  = temp_sum;
                        cout = temp_sum[width];
                    end else err = 1'b1;
                end
 
                // CMD 3: SUB with CIN
                3: begin
                    if (inp_valid == 2'b11)
                        res = opa - opb - cin;
                    else err = 1'b1;
                end
 
                // CMD 4: INC OPA
                4: begin
                    if (inp_valid == 2'b01 || inp_valid == 2'b11 )
                        res = opa + 1'b1;
                    else err = 1'b1;
                end
 
                // CMD 5: DEC OPA
                5: begin
                    if (inp_valid == 2'b01 || inp_valid == 2'b11)
                        res = opa - 1'b1;
                    else err = 1'b1;
                end
 
                // CMD 6: INC OPB
                6: begin
                    if (inp_valid == 2'b10 || inp_valid == 2'b11)
                        res = opb + 1'b1;
                    else err = 1'b1;
                end
 
                // CMD 7: DEC OPB
                7: begin
                    if (inp_valid == 2'b10 || inp_valid == 2'b11)
                        res = opb - 1'b1;
                    else err = 1'b1;
                end
 
                // CMD 8: Unsigned CMP
                8: begin
                    if (inp_valid == 2'b11) begin
                        if      (opa > opb) begin g = 1'b1; l = 1'b0; e = 1'b0; end
                        else if (opa < opb) begin g = 1'b0; l = 1'b1; e = 1'b0; end
                        else                begin g = 1'b0; l = 1'b0; e = 1'b1; end
                    end else err = 1'b1;
                end
 
                // CMD 9: (OPA+1) * (OPB+1) - multi-cycle, ref gives direct result
                9: begin
                    if (inp_valid == 2'b11)
                        res = (opa + 1'b1) * (opb + 1'b1);
                    else err = 1'b1;
                end
 
                // CMD 10: (OPA<<1) * OPB - multi-cycle, ref gives direct result
                10: begin
                    if (inp_valid == 2'b11)
                        res = (opa << 1'b1) * opb;
                    else err = 1'b1;
                end
 
                // CMD 11: Signed ADD + CMP
                11: begin
                    if (inp_valid == 2'b11) begin
                        temp_sum = $signed(opa) + $signed(opb);
                        res   = temp_sum;
                        oflow = (opa[width-1] & opb[width-1] & ~temp_sum[width-1]) |
                                (~opa[width-1] & ~opb[width-1] & temp_sum[width-1]);
                        cout  = temp_sum[width];
                        if      ($signed(opa) > $signed(opb))  begin g = 1'b1; l = 1'b0; e = 1'b0; end
                        else if ($signed(opa) < $signed(opb))  begin g = 1'b0; l = 1'b1; e = 1'b0; end
                        if      ($signed(opa) == $signed(opb)) begin g = 1'b0; l = 1'b0; e = 1'b1; end
                    end else err = 1'b1;
                end
 
                // CMD 12: Signed SUB + CMP
                12: begin
                    if (inp_valid == 2'b11) begin
                        temp_sum = $signed(opa) - $signed(opb);
                        res   = temp_sum;
                        oflow = (opa[width-1] ^ opb[width-1]) & (opa[width-1] ^ temp_sum[width-1]);
                        cout  = temp_sum[width];
                        if      ($signed(opa) > $signed(opb))  begin g = 1'b1; l = 1'b0; e = 1'b0; end
                        else if ($signed(opa) < $signed(opb))  begin g = 1'b0; l = 1'b1; e = 1'b0; end
                        if      ($signed(opa) == $signed(opb)) begin g = 1'b0; l = 1'b0; e = 1'b1; end
                    end else err = 1'b1;
                end
 
                default: begin /* no error on default, matches DUT */ end
            endcase
        end
 
        else begin // Logical mode
            case (cmd)
                0:  begin if (inp_valid == 2'b11) res =  (opa & opb); else err = 1'b1; end
                1:  begin if (inp_valid == 2'b11) res = ~(opa & opb); else err = 1'b1; end
                2:  begin if (inp_valid == 2'b11) res =  (opa | opb); else err = 1'b1; end
                3:  begin if (inp_valid == 2'b11) res = ~(opa | opb); else err = 1'b1; end
                4:  begin if (inp_valid == 2'b11) res =  (opa ^ opb); else err = 1'b1; end
                5:  begin if (inp_valid == 2'b11) res = ~(opa ^ opb); else err = 1'b1; end
                6:  begin if (inp_valid == 2'b01) res = ~opa;         else err = 1'b1; end
                7:  begin if (inp_valid == 2'b10) res = ~opb;         else err = 1'b1; end
                8:  begin if (inp_valid == 2'b01) res = opa >> 1'b1;  else err = 1'b1; end
                9:  begin if (inp_valid == 2'b01) res = opa << 1'b1;  else err = 1'b1; end
                10: begin if (inp_valid == 2'b10) res = opb >> 1'b1;  else err = 1'b1; end
                11: begin if (inp_valid == 2'b10) res = opb << 1'b1;  else err = 1'b1; end
 
                // CMD 12: ROL OPA by OPB[2:0]
                12: begin
                    if (inp_valid == 2'b11) begin
                        err = |opb[width-1:width/2];
                        if (rot_amt == 0)
                            res = {{width+1{1'b0}}, opa};
                        else
                            res = {{width+1{1'b0}}, ((opa << rot_amt) | (opa >> (width - rot_amt)))};
                    end else begin
                        err = 1'b1;
                        res = {(2*width+1){1'b0}};
                    end
                end
 
                // CMD 13: ROR OPA by OPB[2:0]
                13: begin
                    if (inp_valid == 2'b11) begin
                        err = |opb[width-1:width/2];
                        if (rot_amt == 0)
                            res = {{width+1{1'b0}}, opa};
                        else
                            res = {{width+1{1'b0}}, ((opa >> rot_amt) | (opa << (width - rot_amt)))};
                    end else begin
                        err = 1'b1;
                        res = {(2*width+1){1'b0}};
                    end
                end
 
                default: err = 1'b1;
            endcase
        end
    end
 
endmodule
