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
//        pem_bhv.v: Behavioural description of priority enconder (PE) match      //
//                                                                                //
//   Author: Ameer M.S. Abdelhadi (ameer@ece.ubc.ca; ameer.abdelhadi@gmail.com)   //
//   BRAM-based II-TCAM ; The University of British Columbia (UBC) ;  Dec. 2015   //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module pem_bhv
 #( parameter                   OHW = 512 )  // encoder one-hot input width
  ( input                       clk       , // clock for pipelined priority encoder
    input                       rst       , // registers reset for pipelined priority encoder
    input      [      OHW -1:0] oht       ,  // one-hot input  / [      OHW -1:0]
    output reg [`log2(OHW)-1:0] bin       ,  // first '1' index/ [`log2(OHW)-1:0]
    output reg                  vld       ); // binary is valid if one was found

// behavioural description of priority enconder;
// faster in simulation than the LZD/onehot2bin priority encoder

  // first approach; using while loop for for non fixed loop length
  // synthesized well with Altera's QuartusII but loop iterations can't exceed 250.
//reg [`log2(OHW)-1:0] binI;
//reg                  valI ;
  always @(*) begin
    bin = {`log2(OHW){1'b0}};
    vld = oht[bin]         ;
    while ((!vld) && (bin!=(OHW-1))) begin
      bin = bin + 1 ;
      vld = oht[bin];
    end
  end
//assign bin = binI;
//assign vld = vldI;

// second approach; using for loop fixed loop length
// logic inflated if synthesised with Altera's QuartusII
//integer i;
//always @(*) begin
//  valid  =              1'b0  ;
//  binary = {`log2(ONEHOTW){1'b0}};
//  for (i=0;i<ONEHOTW;i=i+1) begin
//    valid = valid | onehot[i];
//    if (!valid) binary = binary + 1;
//  end
//end

endmodule
