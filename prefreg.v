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
//                          prefreg.v: prefixes register                          //
//                                                                                //
//   Author: Ameer M.S. Abdelhadi (ameer@ece.ubc.ca; ameer.abdelhadi@gmail.com)   //
//   BRAM-based II-TCAM ; The University of British Columbia (UBC) ;  Dec. 2015   //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module prefreg
 #( parameter                PRFW = 5,  // prefix width (log2(pattern width))
    parameter                PRFN = 8) // number of prefixes (equals to CAM depth)
  ( input                    clk     ,  // clock
    input                    rst     ,  // asyncronous reset
    input                    wEn     ,  // write enable
    input  [`log2(PRFN)-1:0] prfa    ,  // prefix address
    input  [PRFW       -1:0] prfd    ,  // prefix register data input
    output reg [PRFW*PRFN  -1:0] prfq    ); // prefix register output

  // create PRFN registers of PRFW bits width, enabled based on prefix address prfa
  integer ai; // address index
  always @(posedge clk, posedge rst)
    for (ai=0; ai<PRFN; ai=ai+1)
      if (rst)                  prfq[ai*PRFW +: PRFW] <= {PRFW{1'b0}};
      else if (wEn&&(prfa==ai)) prfq[ai*PRFW +: PRFW] <= prfd        ;
    
endmodule