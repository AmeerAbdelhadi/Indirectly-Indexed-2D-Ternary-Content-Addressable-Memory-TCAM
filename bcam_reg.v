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
//           rrbcam.v: register-based BCAM with no pattern duplication            //
//                     (two addresses cannot hold the same pattern)               //
//                                                                                //
//   Author: Ameer M.S. Abdelhadi (ameer@ece.ubc.ca; ameer.abdelhadi@gmail.com)   //
//   BRAM-based II-TCAM ; The University of British Columbia (UBC) ;  Dec. 2015   //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module bcam_reg
 #( parameter                CDEP = 32,  // CAM depth
    parameter                PWID = 32,  // pattern width
    parameter                REGO = 1 )  // register output
  ( input                    clk      ,  // clock
    input                    rst      ,  // global registers reset
    input                    wEn      ,  // write enable
    input  [      PWID -1:0] wPatt    ,  // write pattern
    input  [`log2(CDEP)-1:0] wAddr    ,  // write address
    input  [      PWID -1:0] mPatt    ,  // patern to match
    output                   match    ,  // match indicator
    output [`log2(CDEP)-1:0] mAddr    ); // match address

  // local parameters
  localparam AWID = `log2(CDEP);

  // local variables
  reg [CDEP-1:0] vld           ; // valid pattern for each address
  reg [CDEP-1:0] indc          ; // match indicators for each address
  reg [PWID-1:0] pat [0:CDEP-1]; // CDEP patterns, each PWID bits width
  integer ai                   ; // address index
  
  // register pattern and set valid bit for written pattern
  always @(posedge clk, posedge rst)
    for (ai=0; ai<CDEP; ai=ai+1)
      if (rst)                   {vld[ai],pat[ai]} <= {1'b0,{PWID{1'b0}}};
      else if (wEn&&(wAddr==ai)) {vld[ai],pat[ai]} <= {1'b1,wPatt       };  

  // computer match indicators
  always @(*)
    for (ai=0; ai<CDEP; ai=ai+1)
      indc[ai] = vld[ai] && (mPatt == pat[ai]);

  wire matchI; // match / internal
  assign matchI = | indc;

  // one-hot to binary encoding
  // two addresses cannot hold the same pattern
  reg [AWID-1:0] mAddrI; // match address / internal
  always @(*) begin
    mAddrI = {AWID{1'b0}};
    for (ai=0; ai<CDEP; ai=ai+1)
      mAddrI = mAddrI | ({AWID{indc[ai]}} & ai[AWID-1:0]) ;
  end

  // register outputs
  reg [AWID-1:0] mAddrR; // match address / registered
  reg            matchR; // match         / registered
  always @(posedge clk, posedge rst)
    if (rst) {matchR,mAddrR} <= {1'b0  ,{AWID{1'b0}}};
    else     {matchR,mAddrR} <= {matchI,mAddrI      };
  
  // select registered or not registered outputs
  assign mAddr = REGO ? mAddrR : mAddrI;
  assign match = REGO ? matchR : matchI;


endmodule
