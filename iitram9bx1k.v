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
// iitram9bx1k.v:Indirectly-indexed transposed-RAM for 9-bits patterns / 1K depth //
//                                                                                //
//   Author: Ameer M.S. Abdelhadi (ameer@ece.ubc.ca; ameer.abdelhadi@gmail.com)   //
//   BRAM-based II-TCAM ; The University of British Columbia (UBC) ;  Dec. 2015   //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module iitram9bx1k
 #( parameter       REGM = 1  )  // register MLAB outputs?
  ( input           clk       ,  // clock
    input           rst       ,  // global registers reset
    input           wEn_iVld  ,  // write enable / indicator valid
    input           wEn_indx  ,  // write enable / indicator index
    input           wEn_indc  ,  // write enable / full indicators (MLABs)
    input  [8   :0] mPatt     ,  // match pattern
    input  [8   :0] wPatt     ,  // write pattern
    input  [4   :0] wAddr_indx,  // write address / index
    input  [4   :0] wAddr_indc,  // write address / indicator (in index range) 
    input  [4   :0] wIndx     ,  // write index
    input           wIVld     ,  // write indicator validity
    input  [31  :0] wIndc     ,  // write indicator (full)
    output [1023:0] mIndc     ); // match indicators

      // instantiate M20K
     wire [31:0] iVld;
      mwm20k #( .WWID  (1                      ),  // write width
                .RWID  (32                     ),  // read width
                .WDEP  (16384                  ),  // write lines depth
                .OREG  (1                      ),  // read output reg
                .INIT  (1                      ))  // initialize to zeros
      ivldram ( .clk   (clk                    ),  // clock         // input
                .rst   (rst                    ),  // global reset  // input
                .wEnb  (wEn_iVld               ),  // write enable  // input
                .wAddr ({wPatt,wAddr_indx[4:0]}),  // write address // input  [`log2(WDEP)-1            :0]
                .wData (wIVld                  ),  // write data    // input  [WWID-1                   :0]
                .rAddr (mPatt                  ),  // read address  // input  [`log2(WDEP/(RWID/WWID))-1:0]
                .rData (iVld                   )); // read data     // output [RWID-1                   :0]

  wire [39:0] indx [3:0];
  wire [1023:0] indc;
  genvar gi,gj;
  generate
    for (gi=0 ; gi<4 ; gi=gi+1) begin: STG
      // instantiate M20K
      mwm20k #( .WWID  (5                                ),  // write width
                .RWID  (40                               ),  // read width
                .WDEP  (4096                             ),  // write lines depth
                .OREG  (0                                ),  // read output reg
                .INIT  (1                                ))  // initialize to zeros
      indxram ( .clk   (clk                              ),  // clock         // input
                .rst   (rst                              ),  // global reset  // input
                .wEnb  (wEn_indx && (wAddr_indx[4:3]==gi)),  // write enable  // input
                .wAddr ({wPatt,wAddr_indx[2:0]}          ),  // write address // input  [`log2(WDEP)-1            :0]
                .wData (wIndx                            ),  // write data    // input  [WWID-1                   :0]
                .rAddr (mPatt                            ),  // read address  // input  [`log2(WDEP/(RWID/WWID))-1:0]
                .rData (indx[gi]                         )); // read data     // output [RWID-1                   :0]
      for (gj=0 ; gj<8 ; gj=gj+1) begin: STG
        // instantiate MLAB
        dpmlab #( .DWID  (32                                                        ),  // data width
                  .DDEP  (32                                                        ),  // data depth
                  .MRDW  ("DONT_CARE"                                               ),  // mixed ports read during write mode ("NEW_DATA", "OLD_DATA", or "DONT_CARE")
                  .RREG  (REGM ? "ALL" : "ADDR"                                     ),  // read port registe: "ADDR" for address, "ROUT", for read output, "ALL" for both.
                  .INIT  (1                                                         ))  // initialize to zeros
        indcram ( .clk   (clk                                                       ),  // clock  // input
                  .rst   (rst                                                       ),  // global reset  // input
                  .wEnb  (wEn_indc && (wAddr_indx[4:3]==gi) && (wAddr_indx[2:0]==gj)),  // write enable  // input
                  .wAddr (wAddr_indc                                                ),  // write address  // input [`log2(DEP)-1:0]
                  .wData (wIndc                                                     ),  // write data  // input [WID-1       :0]
                  .rAddr (indx[gi][gj*5 +: 5]                                       ),  // read address // input [`log2(DEP)-1:0]
                  .rData (indc[(gi*256+gj*32) +: 32]                                )); // read data  // output [WID-1       :0]
        assign mIndc[(gi*256+gj*32) +: 32] = indc[(gi*256+gj*32) +: 32] & {32{iVld[8*gi+gj]}};
      end
    end
  endgenerate

endmodule
