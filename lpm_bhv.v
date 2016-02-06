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
//      lpm_bhv.v:  Behavioural description of longest-prefix-match enconder      //
//                                                                                //
//   Author: Ameer M.S. Abdelhadi (ameer@ece.ubc.ca; ameer.abdelhadi@gmail.com)   //
//   BRAM-based II-TCAM ; The University of British Columbia (UBC) ;  Dec. 2015   //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module lpm_bhv
 #( parameter                   OHW  = 8,  // encoder one-hot input width
    parameter                   PRFW = 5)  // prefix width
  ( input                       clk     ,  // clock for pipelined lpm encoder
    input                       rst     ,  // registers reset for pipelined lpm encoder
    input      [      OHW -1:0] oht     ,  // one-hot input  / [      OHW -1:0]
    input      [ PRFW*OHW -1:0] prf     ,  // prefixes
    output reg [`log2(OHW)-1:0] bin     ,  // first '1' index/ [`log2(OHW)-1:0]
    output reg                  vld     ); // binary is valid if one was found

  localparam AWID = `log2(OHW);
  
  reg  [PRFW-1:0] prft; // prefix / temporal
  wire [PRFW-1:0] prfa [0:OHW-1]; // prefix array
  //`ARRINIT;

  integer ai,aj;
  always @(*) begin
  // unpack 1D prf into 2D array prfa
  //`ARR1D2D(D1W,D2W,prf,prfa);
    ai  = {AWID{1'b0}};
    vld = oht[0]      ;
    // find first match    
    while ((!vld) && (ai!=(OHW-1))) begin
      ai  = ai + 1 ;
      vld = oht[ai];
    end
    bin = ai;
    prft = prf[ai*PRFW +: PRFW];
    // find a match with longer prefix
    for (aj=ai+1; aj<OHW; aj=aj+1) begin
      if ( oht[aj] && (prf[aj*PRFW +: PRFW]<prft)) begin
        vld  = 1'b1      ;
        bin  = aj        ;
        prft = prf[aj*PRFW +: PRFW];
      end
    end
  end


// behavioural description of priority enconder;
// faster in simulation than the LZD/onehot2bin priority encoder

  // first approach; using while loop for for non fixed loop length
  // synthesized well with Altera's QuartusII but loop iterations can't exceed 250.
//reg [`log2(OHW)-1:0] binI;
//reg                  valI ;

  
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
