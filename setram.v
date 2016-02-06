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
// setram.v: Set RAM; Stores patterns and prefixes sets; Generates set indicators //
//                                                                                //
//   Author: Ameer M.S. Abdelhadi (ameer@ece.ubc.ca; ameer.abdelhadi@gmail.com)   //
//   BRAM-based II-TCAM ; The University of British Columbia (UBC) ;  Dec. 2015   //
////////////////////////////////////////////////////////////////////////////////////


// sets RAM

`include "utils.vh"

module setram
 #( parameter                CDEP = 4 ,  // CAM depth (k-entries, power of 2)
    parameter                REGO = 0 )  // pipelined?
  ( input                    clk      ,  // clock
    input                    rst      ,  // global registers reset
    input                    wEn     ,  // write enable
    input  [8            :0] wPatt    ,  // write pattern
    input  [8            :0] wMask    ,  // write mask
    input  [8            :0] cPatt    ,  // counted pattern (0 to 511)
    input  [`log2(CDEP)+9:0] addr     ,  // read/write address
    output [31           :0] setIndc  ); // read pattern set indicators

  wire [1            :0] addrLL = addr[1            :0];
  wire [2            :0] addrLH = addr[4            :2];
  wire [4            :0] addrL  = addr[4            :0];
  wire [`log2(CDEP)+4:0] addrH  = addr[`log2(CDEP)+9:5];

  wire [31    :0] rPattV;
  wire [32*9-1:0] rPatt ;
  wire [31    :0] rMaskV;
  wire [32*9-1:0] rMask ;
  wire [31    :0] setIndcI;
  
  genvar gi;
  generate
    for (gi=0 ; gi<8 ; gi=gi+1) begin: STG
      // instantiate M20K
      mwm20k #( .WWID  (10                                    ),  // write width
                .RWID  (40                                    ),  // read width
                .WDEP  (CDEP*1024/8                           ),  // write lines depth
                .OREG  (1                                     ),  // read output reg
                .INIT  (1                                     ))  // initialize to zeros
      setrami ( .clk   (clk                                   ),  // clock         // input
                .rst   (rst                                   ),  // global reset  // input
                .wEnb  ( wEn && (gi==addrLH)                  ),  // write enable  // input : choose block
                .wAddr ({addrH,addrLL}                        ),  // write address // input  [`log2(WDEP)-1            :0]
                .wData ({1'b1,wPatt}                          ),  // write data    // input  [WWID-1                   :0]
                .rAddr (addrH                                 ),  // read address  // input  [`log2(WDEP/(RWID/WWID))-1:0]
                .rData ({rPattV[gi*4+3],rPatt[ gi*36+27 +: 9],
                         rPattV[gi*4+2],rPatt[ gi*36+18 +: 9],
                         rPattV[gi*4+1],rPatt[ gi*36+9  +: 9],
                         rPattV[gi*4  ],rPatt[ gi*36    +: 9]})); // read data     // output [RWID-1                   :0]
      // instantiate M20K
      mwm20k #( .WWID  (10                                    ),  // write width
                .RWID  (40                                    ),  // read width
                .WDEP  (CDEP*1024/8                           ),  // write lines depth
                .OREG  (1                                     ),  // read output reg
                .INIT  (1                                     ))  // initialize to zeros
      mskrami ( .clk   (clk                                   ),  // clock         // input
                .rst   (rst                                   ),  // global reset  // input
                .wEnb  ( wEn && (gi==addrLH)                  ),  // write enable  // input : choose block
                .wAddr ({addrH,addrLL}                        ),  // write address // input  [`log2(WDEP)-1            :0]
                .wData ({1'b1,wMask}                          ),  // write data    // input  [WWID-1                   :0]
                .rAddr (addrH                                 ),  // read address  // input  [`log2(WDEP/(RWID/WWID))-1:0]
                .rData ({rMaskV[gi*4+3],rMask[ gi*36+27 +: 9],
                         rMaskV[gi*4+2],rMask[ gi*36+18 +: 9],
                         rMaskV[gi*4+1],rMask[ gi*36+9  +: 9],
                         rMaskV[gi*4  ],rMask[ gi*36    +: 9]})); // read data     // output [RWID-1                   :0]

      assign setIndcI[gi*4+3] = ((rMask[ gi*36+27 +: 9] & rPatt[ gi*36+27 +: 9]) == (rMask[ gi*36+27 +: 9] & cPatt)) && rPattV[gi*4+3];
      assign setIndcI[gi*4+2] = ((rMask[ gi*36+18 +: 9] & rPatt[ gi*36+18 +: 9]) == (rMask[ gi*36+18 +: 9] & cPatt)) && rPattV[gi*4+2];
      assign setIndcI[gi*4+1] = ((rMask[ gi*36+9  +: 9] & rPatt[ gi*36+9  +: 9]) == (rMask[ gi*36+9  +: 9] & cPatt)) && rPattV[gi*4+1];
      assign setIndcI[gi*4  ] = ((rMask[ gi*36    +: 9] & rPatt[ gi*36    +: 9]) == (rMask[ gi*36    +: 9] & cPatt)) && rPattV[gi*4  ];
    end
  endgenerate

  // register for pipelining
  reg  [31:0] setIndcR;
  always @(posedge clk, posedge rst)
    if (rst) setIndcR <= 32'b0     ;
    else     setIndcR <= setIndcI;

  // pipeline if required
  assign setIndc = REGO ? setIndcR : setIndcI;


endmodule
