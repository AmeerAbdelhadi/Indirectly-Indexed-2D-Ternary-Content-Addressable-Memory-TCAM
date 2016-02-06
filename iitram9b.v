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
//       iitram9b.v: Indirectly-indexed transposed-RAM for 9-bits patterns        //
//                                                                                //
//   Author: Ameer M.S. Abdelhadi (ameer@ece.ubc.ca; ameer.abdelhadi@gmail.com)   //
//   BRAM-based II-TCAM ; The University of British Columbia (UBC) ;  Dec. 2015   //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module iitram9b
 #( parameter               DEP  = 4  ,  // depth (k-entries, power of 2)
    parameter               REGM = 1  )  // register MLAB outputs?
  ( input                   clk       ,  // clock
    input                   rst       ,  // global registers reset
    input                   wEn_iVld  ,  // write enable / indicator valid
    input                   wEn_indx  ,  // write enable / indicator index
    input                   wEn_indc  ,  // write enable / full indicators (MLABs)
    input  [8           :0] mPatt     ,  // match pattern
    input  [8           :0] wPatt     ,  // write pattern
    input  [`log2(DEP)+4:0] wAddr_indx,  // write address / index  
    input  [4           :0] wAddr_indc,  // write address / indicator (in index range)
    input  [4           :0] wIndx     ,  // write index
    input                   wIVld     ,  // write indicator validity 
    input  [31          :0] wIndc     ,  // write indicator (full)
    output [DEP*1024-1  :0] mIndc     ); // match indicators

  wire [DEP-1:0] wEn;
  wire [`log2(DEP)+5:0] wAddr_indx_zp = {1'b0,wAddr_indx}; // wAddr_indx with additional zero padding
  localparam DEPt = (DEP==1)?2:DEP;

  genvar gi;
  generate
    for (gi=0 ; gi<DEP ; gi=gi+1) begin: STG
      assign wEn[gi] = wAddr_indx_zp[(`log2(DEPt)+4):5]==gi;
      // instantiate iitram9bx1k
      iitram9bx1k #( .REGM      (REGM                  ))  // register MLAB outputs?
      iitram9bx1ki ( .clk       (clk                   ),  // clock                                      / input
                     .rst       (rst                   ),  // global registers reset                     / input
                     .wEn_iVld  (wEn_iVld && wEn[gi]   ),  // write enable / indicator valid             / input
                     .wEn_indx  (wEn_indx && wEn[gi]   ),  // write enable / indicator index             / input
                     .wEn_indc  (wEn_indc && wEn[gi]   ),  // write enable / full indicators (MLABs)     / input
                     .mPatt     (mPatt                 ),  // match pattern                              / input  [8   :0]
                     .wPatt     (wPatt                 ),  // write pattern                              / input  [8   :0]
                     .wAddr_indx(wAddr_indx[4:0]       ),  // write address / index                      / input  [4   :0]
                     .wAddr_indc(wAddr_indc            ),  // write address / indicator (in index range) / input  [4   :0]
                     .wIndx     (wIndx                 ),  // write index                                / input  [4   :0]
                     .wIVld     (wIVld                 ),  // write indicator validity                   / input 
                     .wIndc     (wIndc                 ),  // write indicator (full)                     / input  [31  :0]
                     .mIndc     (mIndc[1024*gi +: 1024])); // match indicators                           / output [1023:0]
    end
  endgenerate

endmodule
