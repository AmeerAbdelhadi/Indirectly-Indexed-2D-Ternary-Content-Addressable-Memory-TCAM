////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2015 ; The University of British Columbia ; All rights reserved. //
//                                                                                //
// Redistribution  and  use  in  source   and  binary  forms,   with  or  without //
// modification,  are permitted  provided that  the following conditions are met: //
//   * Redistributions   of  source   code  must  retain   the   above  copyright //
//     notice,  this   list   of   conditions   and   the  following  disclaimer. //
//   * Redistributions  in  binary  form  must  reproduce  the  above   copyright //
//     notice, this  list  of  conditions  and the  following  disclaimer in  the //
//     documentation and/or  other  materials  provided  with  the  distribution. //
//   * Neither the name of the University of British Columbia (UBC) nor the names //
//     of   its   contributors  may  be  used  to  endorse  or   promote products //
//     derived from  this  software without  specific  prior  written permission. //
//                                                                                //
// THIS  SOFTWARE IS  PROVIDED  BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" //
// AND  ANY EXPRESS  OR IMPLIED WARRANTIES,  INCLUDING,  BUT NOT LIMITED TO,  THE //
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE //
// DISCLAIMED.  IN NO  EVENT SHALL University of British Columbia (UBC) BE LIABLE //
// FOR ANY DIRECT,  INDIRECT,  INCIDENTAL,  SPECIAL,  EXEMPLARY, OR CONSEQUENTIAL //
// DAMAGES  (INCLUDING,  BUT NOT LIMITED TO,  PROCUREMENT OF  SUBSTITUTE GOODS OR //
// SERVICES;  LOSS OF USE,  DATA,  OR PROFITS;  OR BUSINESS INTERRUPTION) HOWEVER //
// CAUSED AND ON ANY THEORY OF LIABILITY,  WHETHER IN CONTRACT, STRICT LIABILITY, //
// OR TORT  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE //
// OF  THIS SOFTWARE,  EVEN  IF  ADVISED  OF  THE  POSSIBILITY  OF  SUCH  DAMAGE. //
////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////
// lpm_out: Recursive Longest-Prefix-Macth (LPM) encoder; Automatically generated//
//                                                                                //
//   Author: Ameer M.S. Abdelhadi (ameer@ece.ubc.ca; ameer.abdelhadi@gmail.com)   //
//   BRAM-based II-TCAM ; The University of British Columbia (UBC) ;  Dec. 2015   //
////////////////////////////////////////////////////////////////////////////////////

// lpm2_out: 2-bit  Longest-Prefix-Macth (LPM) sub-module; Automatically generated
module lpm2_out(input clk, input rst, input [2-1:0] oht, input [4*2-1:0] prf, output [1-1:0] bin, output [4-1:0] pro, output vld);
  wire [4:0] p0 = { !oht[0] ,  prf[  4-1:0] }; // unpacked input prefix
  wire [4:0] p1 = { !oht[1] ,  prf[2*4-1:4] }; // unpacked input prefix
  assign    bin = (p1<p0) ? 1'b1 : 1'b0      ; // LSP  of the minimum prefix index
  assign    pro = bin ? p1[4-1:0] : p0[4-1:0]; // lower valid minimum
  assign    vld = |oht                       ; // valid bits
endmodule

// lpm4_out: 4-bit  Longest-Prefix-Macth (LPM) sub-module; Automatically generated
module lpm4_out(input clk, input rst, input [4-1:0] oht, input [4*4-1:0] prf, output [2-1:0] bin, output [4-1:0] pro, output vld);
  // recursive calls for four narrower (half the inout width) LPM encoders
  wire [2-2:0] binI[1:0]; wire [1:0] vldI; wire [4-1:0] proI [1:0];
  lpm2_out lpm2_out_in0(clk,rst,oht[4/2-1:0    ],prf[4/2*4-1:0    ],binI[0],proI[0],vldI[0]);
  lpm2_out lpm2_out_in1(clk,rst,oht[4  -1:  4/2],prf[4  *4-1:4/2*4],binI[1],proI[1],vldI[1]);
  // register input LPM encoders outputs if pipelining is required; otherwise assign only
  wire [2-2:0] binII[1:0]; wire [4-1:0] proII[1:0]; wire [   1:0] vldII;
  reg [2-2:0] binIR[1:0]; reg [1:0] vldIR; reg [4-1:0] proIR[1:0];
  always @(posedge clk, posedge rst)
    if (rst) {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {(2*(2+4)){1'b0}};
    else     {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {binI[ 1],binI[ 0],proI[ 1],proI[ 0],vldI };
  assign     {binII[1],binII[0],proII[1],proII[0],vldII} =  {binIR[1],binIR[0],proIR[1],proIR[0],vldIR};
  // output lpm2 to generate indices from valid bits
  lpm2_out lpm2_out_out0(clk,rst,vldII,{proII[1],proII[0]},bin[2-1:2-1],pro,vld);
  assign bin[2-2:0] = bin[2-1:2-1] ? binII[1] : binII[0];
endmodule

// lpm8_out: 8-bit  Longest-Prefix-Macth (LPM) sub-module; Automatically generated
module lpm8_out(input clk, input rst, input [8-1:0] oht, input [4*8-1:0] prf, output [3-1:0] bin, output [4-1:0] pro, output vld);
  // recursive calls for four narrower (half the inout width) LPM encoders
  wire [3-2:0] binI[1:0]; wire [1:0] vldI; wire [4-1:0] proI [1:0];
  lpm4_out lpm4_out_in0(clk,rst,oht[8/2-1:0    ],prf[8/2*4-1:0    ],binI[0],proI[0],vldI[0]);
  lpm4_out lpm4_out_in1(clk,rst,oht[8  -1:  8/2],prf[8  *4-1:8/2*4],binI[1],proI[1],vldI[1]);
  // register input LPM encoders outputs if pipelining is required; otherwise assign only
  wire [3-2:0] binII[1:0]; wire [4-1:0] proII[1:0]; wire [   1:0] vldII;
  reg [3-2:0] binIR[1:0]; reg [1:0] vldIR; reg [4-1:0] proIR[1:0];
  always @(posedge clk, posedge rst)
    if (rst) {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {(2*(3+4)){1'b0}};
    else     {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {binI[ 1],binI[ 0],proI[ 1],proI[ 0],vldI };
  assign     {binII[1],binII[0],proII[1],proII[0],vldII} =  {binIR[1],binIR[0],proIR[1],proIR[0],vldIR};
  // output lpm2 to generate indices from valid bits
  lpm2_out lpm2_out_out0(clk,rst,vldII,{proII[1],proII[0]},bin[3-1:3-1],pro,vld);
  assign bin[3-2:0] = bin[3-1:3-1] ? binII[1] : binII[0];
endmodule

// lpm16_out: 16-bit  Longest-Prefix-Macth (LPM) sub-module; Automatically generated
module lpm16_out(input clk, input rst, input [16-1:0] oht, input [4*16-1:0] prf, output [4-1:0] bin, output [4-1:0] pro, output vld);
  // recursive calls for four narrower (half the inout width) LPM encoders
  wire [4-2:0] binI[1:0]; wire [1:0] vldI; wire [4-1:0] proI [1:0];
  lpm8_out lpm8_out_in0(clk,rst,oht[16/2-1:0    ],prf[16/2*4-1:0    ],binI[0],proI[0],vldI[0]);
  lpm8_out lpm8_out_in1(clk,rst,oht[16  -1:  16/2],prf[16  *4-1:16/2*4],binI[1],proI[1],vldI[1]);
  // register input LPM encoders outputs if pipelining is required; otherwise assign only
  wire [4-2:0] binII[1:0]; wire [4-1:0] proII[1:0]; wire [   1:0] vldII;
  reg [4-2:0] binIR[1:0]; reg [1:0] vldIR; reg [4-1:0] proIR[1:0];
  always @(posedge clk, posedge rst)
    if (rst) {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {(2*(4+4)){1'b0}};
    else     {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {binI[ 1],binI[ 0],proI[ 1],proI[ 0],vldI };
  assign     {binII[1],binII[0],proII[1],proII[0],vldII} =  {binIR[1],binIR[0],proIR[1],proIR[0],vldIR};
  // output lpm2 to generate indices from valid bits
  lpm2_out lpm2_out_out0(clk,rst,vldII,{proII[1],proII[0]},bin[4-1:4-1],pro,vld);
  assign bin[4-2:0] = bin[4-1:4-1] ? binII[1] : binII[0];
endmodule

// lpm32_out: 32-bit  Longest-Prefix-Macth (LPM) sub-module; Automatically generated
module lpm32_out(input clk, input rst, input [32-1:0] oht, input [4*32-1:0] prf, output [5-1:0] bin, output [4-1:0] pro, output vld);
  // recursive calls for four narrower (half the inout width) LPM encoders
  wire [5-2:0] binI[1:0]; wire [1:0] vldI; wire [4-1:0] proI [1:0];
  lpm16_out lpm16_out_in0(clk,rst,oht[32/2-1:0    ],prf[32/2*4-1:0    ],binI[0],proI[0],vldI[0]);
  lpm16_out lpm16_out_in1(clk,rst,oht[32  -1:  32/2],prf[32  *4-1:32/2*4],binI[1],proI[1],vldI[1]);
  // register input LPM encoders outputs if pipelining is required; otherwise assign only
  wire [5-2:0] binII[1:0]; wire [4-1:0] proII[1:0]; wire [   1:0] vldII;
  reg [5-2:0] binIR[1:0]; reg [1:0] vldIR; reg [4-1:0] proIR[1:0];
  always @(posedge clk, posedge rst)
    if (rst) {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {(2*(5+4)){1'b0}};
    else     {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {binI[ 1],binI[ 0],proI[ 1],proI[ 0],vldI };
  assign     {binII[1],binII[0],proII[1],proII[0],vldII} =  {binIR[1],binIR[0],proIR[1],proIR[0],vldIR};
  // output lpm2 to generate indices from valid bits
  lpm2_out lpm2_out_out0(clk,rst,vldII,{proII[1],proII[0]},bin[5-1:5-1],pro,vld);
  assign bin[5-2:0] = bin[5-1:5-1] ? binII[1] : binII[0];
endmodule

// lpm64_out: 64-bit  Longest-Prefix-Macth (LPM) sub-module; Automatically generated
module lpm64_out(input clk, input rst, input [64-1:0] oht, input [4*64-1:0] prf, output [6-1:0] bin, output [4-1:0] pro, output vld);
  // recursive calls for four narrower (half the inout width) LPM encoders
  wire [6-2:0] binI[1:0]; wire [1:0] vldI; wire [4-1:0] proI [1:0];
  lpm32_out lpm32_out_in0(clk,rst,oht[64/2-1:0    ],prf[64/2*4-1:0    ],binI[0],proI[0],vldI[0]);
  lpm32_out lpm32_out_in1(clk,rst,oht[64  -1:  64/2],prf[64  *4-1:64/2*4],binI[1],proI[1],vldI[1]);
  // register input LPM encoders outputs if pipelining is required; otherwise assign only
  wire [6-2:0] binII[1:0]; wire [4-1:0] proII[1:0]; wire [   1:0] vldII;
  reg [6-2:0] binIR[1:0]; reg [1:0] vldIR; reg [4-1:0] proIR[1:0];
  always @(posedge clk, posedge rst)
    if (rst) {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {(2*(6+4)){1'b0}};
    else     {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {binI[ 1],binI[ 0],proI[ 1],proI[ 0],vldI };
  assign     {binII[1],binII[0],proII[1],proII[0],vldII} =  {binIR[1],binIR[0],proIR[1],proIR[0],vldIR};
  // output lpm2 to generate indices from valid bits
  lpm2_out lpm2_out_out0(clk,rst,vldII,{proII[1],proII[0]},bin[6-1:6-1],pro,vld);
  assign bin[6-2:0] = bin[6-1:6-1] ? binII[1] : binII[0];
endmodule

// lpm128_out: 128-bit  Longest-Prefix-Macth (LPM) sub-module; Automatically generated
module lpm128_out(input clk, input rst, input [128-1:0] oht, input [4*128-1:0] prf, output [7-1:0] bin, output [4-1:0] pro, output vld);
  // recursive calls for four narrower (half the inout width) LPM encoders
  wire [7-2:0] binI[1:0]; wire [1:0] vldI; wire [4-1:0] proI [1:0];
  lpm64_out lpm64_out_in0(clk,rst,oht[128/2-1:0    ],prf[128/2*4-1:0    ],binI[0],proI[0],vldI[0]);
  lpm64_out lpm64_out_in1(clk,rst,oht[128  -1:  128/2],prf[128  *4-1:128/2*4],binI[1],proI[1],vldI[1]);
  // register input LPM encoders outputs if pipelining is required; otherwise assign only
  wire [7-2:0] binII[1:0]; wire [4-1:0] proII[1:0]; wire [   1:0] vldII;
  reg [7-2:0] binIR[1:0]; reg [1:0] vldIR; reg [4-1:0] proIR[1:0];
  always @(posedge clk, posedge rst)
    if (rst) {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {(2*(7+4)){1'b0}};
    else     {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {binI[ 1],binI[ 0],proI[ 1],proI[ 0],vldI };
  assign     {binII[1],binII[0],proII[1],proII[0],vldII} =  {binIR[1],binIR[0],proIR[1],proIR[0],vldIR};
  // output lpm2 to generate indices from valid bits
  lpm2_out lpm2_out_out0(clk,rst,vldII,{proII[1],proII[0]},bin[7-1:7-1],pro,vld);
  assign bin[7-2:0] = bin[7-1:7-1] ? binII[1] : binII[0];
endmodule

// lpm256_out: 256-bit  Longest-Prefix-Macth (LPM) sub-module; Automatically generated
module lpm256_out(input clk, input rst, input [256-1:0] oht, input [4*256-1:0] prf, output [8-1:0] bin, output [4-1:0] pro, output vld);
  // recursive calls for four narrower (half the inout width) LPM encoders
  wire [8-2:0] binI[1:0]; wire [1:0] vldI; wire [4-1:0] proI [1:0];
  lpm128_out lpm128_out_in0(clk,rst,oht[256/2-1:0    ],prf[256/2*4-1:0    ],binI[0],proI[0],vldI[0]);
  lpm128_out lpm128_out_in1(clk,rst,oht[256  -1:  256/2],prf[256  *4-1:256/2*4],binI[1],proI[1],vldI[1]);
  // register input LPM encoders outputs if pipelining is required; otherwise assign only
  wire [8-2:0] binII[1:0]; wire [4-1:0] proII[1:0]; wire [   1:0] vldII;
  reg [8-2:0] binIR[1:0]; reg [1:0] vldIR; reg [4-1:0] proIR[1:0];
  always @(posedge clk, posedge rst)
    if (rst) {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {(2*(8+4)){1'b0}};
    else     {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {binI[ 1],binI[ 0],proI[ 1],proI[ 0],vldI };
  assign     {binII[1],binII[0],proII[1],proII[0],vldII} =  {binIR[1],binIR[0],proIR[1],proIR[0],vldIR};
  // output lpm2 to generate indices from valid bits
  lpm2_out lpm2_out_out0(clk,rst,vldII,{proII[1],proII[0]},bin[8-1:8-1],pro,vld);
  assign bin[8-2:0] = bin[8-1:8-1] ? binII[1] : binII[0];
endmodule

// lpm512_out: 512-bit  Longest-Prefix-Macth (LPM) sub-module; Automatically generated
module lpm512_out(input clk, input rst, input [512-1:0] oht, input [4*512-1:0] prf, output [9-1:0] bin, output [4-1:0] pro, output vld);
  // recursive calls for four narrower (half the inout width) LPM encoders
  wire [9-2:0] binI[1:0]; wire [1:0] vldI; wire [4-1:0] proI [1:0];
  lpm256_out lpm256_out_in0(clk,rst,oht[512/2-1:0    ],prf[512/2*4-1:0    ],binI[0],proI[0],vldI[0]);
  lpm256_out lpm256_out_in1(clk,rst,oht[512  -1:  512/2],prf[512  *4-1:512/2*4],binI[1],proI[1],vldI[1]);
  // register input LPM encoders outputs if pipelining is required; otherwise assign only
  wire [9-2:0] binII[1:0]; wire [4-1:0] proII[1:0]; wire [   1:0] vldII;
  reg [9-2:0] binIR[1:0]; reg [1:0] vldIR; reg [4-1:0] proIR[1:0];
  always @(posedge clk, posedge rst)
    if (rst) {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {(2*(9+4)){1'b0}};
    else     {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {binI[ 1],binI[ 0],proI[ 1],proI[ 0],vldI };
  assign     {binII[1],binII[0],proII[1],proII[0],vldII} =  {binIR[1],binIR[0],proIR[1],proIR[0],vldIR};
  // output lpm2 to generate indices from valid bits
  lpm2_out lpm2_out_out0(clk,rst,vldII,{proII[1],proII[0]},bin[9-1:9-1],pro,vld);
  assign bin[9-2:0] = bin[9-1:9-1] ? binII[1] : binII[0];
endmodule

// lpm1024_out: 1024-bit  Longest-Prefix-Macth (LPM) sub-module; Automatically generated
module lpm1024_out(input clk, input rst, input [1024-1:0] oht, input [4*1024-1:0] prf, output [10-1:0] bin, output [4-1:0] pro, output vld);
  // recursive calls for four narrower (half the inout width) LPM encoders
  wire [10-2:0] binI[1:0]; wire [1:0] vldI; wire [4-1:0] proI [1:0];
  lpm512_out lpm512_out_in0(clk,rst,oht[1024/2-1:0    ],prf[1024/2*4-1:0    ],binI[0],proI[0],vldI[0]);
  lpm512_out lpm512_out_in1(clk,rst,oht[1024  -1:  1024/2],prf[1024  *4-1:1024/2*4],binI[1],proI[1],vldI[1]);
  // register input LPM encoders outputs if pipelining is required; otherwise assign only
  wire [10-2:0] binII[1:0]; wire [4-1:0] proII[1:0]; wire [   1:0] vldII;
  reg [10-2:0] binIR[1:0]; reg [1:0] vldIR; reg [4-1:0] proIR[1:0];
  always @(posedge clk, posedge rst)
    if (rst) {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {(2*(10+4)){1'b0}};
    else     {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {binI[ 1],binI[ 0],proI[ 1],proI[ 0],vldI };
  assign     {binII[1],binII[0],proII[1],proII[0],vldII} =  {binIR[1],binIR[0],proIR[1],proIR[0],vldIR};
  // output lpm2 to generate indices from valid bits
  lpm2_out lpm2_out_out0(clk,rst,vldII,{proII[1],proII[0]},bin[10-1:10-1],pro,vld);
  assign bin[10-2:0] = bin[10-1:10-1] ? binII[1] : binII[0];
endmodule

// lpm2048_out: 2048-bit  Longest-Prefix-Macth (LPM) sub-module; Automatically generated
module lpm2048_out(input clk, input rst, input [2048-1:0] oht, input [4*2048-1:0] prf, output [11-1:0] bin, output [4-1:0] pro, output vld);
  // recursive calls for four narrower (half the inout width) LPM encoders
  wire [11-2:0] binI[1:0]; wire [1:0] vldI; wire [4-1:0] proI [1:0];
  lpm1024_out lpm1024_out_in0(clk,rst,oht[2048/2-1:0    ],prf[2048/2*4-1:0    ],binI[0],proI[0],vldI[0]);
  lpm1024_out lpm1024_out_in1(clk,rst,oht[2048  -1:  2048/2],prf[2048  *4-1:2048/2*4],binI[1],proI[1],vldI[1]);
  // register input LPM encoders outputs if pipelining is required; otherwise assign only
  wire [11-2:0] binII[1:0]; wire [4-1:0] proII[1:0]; wire [   1:0] vldII;
  reg [11-2:0] binIR[1:0]; reg [1:0] vldIR; reg [4-1:0] proIR[1:0];
  always @(posedge clk, posedge rst)
    if (rst) {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {(2*(11+4)){1'b0}};
    else     {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {binI[ 1],binI[ 0],proI[ 1],proI[ 0],vldI };
  assign     {binII[1],binII[0],proII[1],proII[0],vldII} =  {binIR[1],binIR[0],proIR[1],proIR[0],vldIR};
  // output lpm2 to generate indices from valid bits
  lpm2_out lpm2_out_out0(clk,rst,vldII,{proII[1],proII[0]},bin[11-1:11-1],pro,vld);
  assign bin[11-2:0] = bin[11-1:11-1] ? binII[1] : binII[0];
endmodule

// lpm4096_out: 4096-bit  Longest-Prefix-Macth (LPM) sub-module; Automatically generated
module lpm4096_out(input clk, input rst, input [4096-1:0] oht, input [4*4096-1:0] prf, output [12-1:0] bin, output [4-1:0] pro, output vld);
  // recursive calls for four narrower (half the inout width) LPM encoders
  wire [12-2:0] binI[1:0]; wire [1:0] vldI; wire [4-1:0] proI [1:0];
  lpm2048_out lpm2048_out_in0(clk,rst,oht[4096/2-1:0    ],prf[4096/2*4-1:0    ],binI[0],proI[0],vldI[0]);
  lpm2048_out lpm2048_out_in1(clk,rst,oht[4096  -1:  4096/2],prf[4096  *4-1:4096/2*4],binI[1],proI[1],vldI[1]);
  // register input LPM encoders outputs if pipelining is required; otherwise assign only
  wire [12-2:0] binII[1:0]; wire [4-1:0] proII[1:0]; wire [   1:0] vldII;
  reg [12-2:0] binIR[1:0]; reg [1:0] vldIR; reg [4-1:0] proIR[1:0];
  always @(posedge clk, posedge rst)
    if (rst) {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {(2*(12+4)){1'b0}};
    else     {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {binI[ 1],binI[ 0],proI[ 1],proI[ 0],vldI };
  assign     {binII[1],binII[0],proII[1],proII[0],vldII} =  {binIR[1],binIR[0],proIR[1],proIR[0],vldIR};
  // output lpm2 to generate indices from valid bits
  lpm2_out lpm2_out_out0(clk,rst,vldII,{proII[1],proII[0]},bin[12-1:12-1],pro,vld);
  assign bin[12-2:0] = bin[12-1:12-1] ? binII[1] : binII[0];
endmodule

// lpm8192_out: 8192-bit  Longest-Prefix-Macth (LPM) sub-module; Automatically generated
module lpm8192_out(input clk, input rst, input [8192-1:0] oht, input [4*8192-1:0] prf, output [13-1:0] bin, output [4-1:0] pro, output vld);
  // recursive calls for four narrower (half the inout width) LPM encoders
  wire [13-2:0] binI[1:0]; wire [1:0] vldI; wire [4-1:0] proI [1:0];
  lpm4096_out lpm4096_out_in0(clk,rst,oht[8192/2-1:0    ],prf[8192/2*4-1:0    ],binI[0],proI[0],vldI[0]);
  lpm4096_out lpm4096_out_in1(clk,rst,oht[8192  -1:  8192/2],prf[8192  *4-1:8192/2*4],binI[1],proI[1],vldI[1]);
  // register input LPM encoders outputs if pipelining is required; otherwise assign only
  wire [13-2:0] binII[1:0]; wire [4-1:0] proII[1:0]; wire [   1:0] vldII;
  reg [13-2:0] binIR[1:0]; reg [1:0] vldIR; reg [4-1:0] proIR[1:0];
  always @(posedge clk, posedge rst)
    if (rst) {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {(2*(13+4)){1'b0}};
    else     {binIR[1],binIR[0],proIR[1],proIR[0],vldIR} <= {binI[ 1],binI[ 0],proI[ 1],proI[ 0],vldI };
  assign     {binII[1],binII[0],proII[1],proII[0],vldII} =  {binIR[1],binIR[0],proIR[1],proIR[0],vldIR};
  // output lpm2 to generate indices from valid bits
  lpm2_out lpm2_out_out0(clk,rst,vldII,{proII[1],proII[0]},bin[13-1:13-1],pro,vld);
  assign bin[13-2:0] = bin[13-1:13-1] ? binII[1] : binII[0];
endmodule

// lpm_out.v: LPM encoder top module file; Automatically generated
module lpm_out(input clk, input rst, input [8192-1:0] oht, input [4*8192-1:0] prf,output [13-1:0] bin, output vld);
  wire [8192-1:0] ohtR = oht; wire [4*8192-1:0] prfR = prf;
  wire [13-1:0] binII; wire vldI;
  // instantiate peiority encoder
  lpm8192_out lpm8192_out_0(clk,rst,ohtR,prfR,binII,,vldI);
  assign {bin,vld} = {binII ,vldI };
endmodule
