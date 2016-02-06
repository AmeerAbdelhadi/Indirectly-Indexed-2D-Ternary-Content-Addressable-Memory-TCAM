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
//   tcam_lpm_bhv.v:  Behavioral description of longest-prefix-match (PEM) TCAM   //
//                                                                                //
//   Author: Ameer M.S. Abdelhadi (ameer@ece.ubc.ca; ameer.abdelhadi@gmail.com)   //
//   BRAM-based II-TCAM ; The University of British Columbia (UBC) ;  Dec. 2015   //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

module tcam_lpm_bhv
 #( parameter                    CDEP = 512,  // CAM depth
    parameter                    PWID = 32 ,  // CAM/pattern width
    parameter                    INOM = 1  )  // binary / Initial CAM with no match (has priority over IFILE)
  ( input                        clk       ,  // clock
    input                        rst       ,  // global registers reset
    input                        wEn       ,  // write enable
    input      [`log2(CDEP)-1:0] wAddr     ,  // write address
    input      [      PWID -1:0] wPatt     ,  // write pattern
    input      [`log2(PWID)-1:0] wMask     ,  // pattern mask    
    input      [      PWID -1:0] mPatt     ,  // patern to match
    output reg                   match     ,  // match indicator
    output reg [      CDEP -1:0] mIndc     ,  // match one-hot / for testing only    
    output reg [`log2(CDEP)-1:0] mAddr     ); // matched address

  // local parameters
  localparam AWID = `log2(CDEP); // address width
  localparam MWID = `log2(PWID); // mask    width
  
  // assign memory arrays
  reg [PWID-1:0] patMem [0:CDEP-1]; // patterns memory
  reg [PWID-1:0] mskMem [0:CDEP-1]; // masks    memory

  // local registers
  reg [CDEP-1:0] vld  ; // valid bit
  reg [PWID-1:0] wMaskMax; // temporal maximum masks
  
  // initialize memory, with zeros if INOM or file if IFILE.
  integer i;
  initial
    if (INOM)
      for (i=0; i<CDEP; i=i+1)
        {vld[i],patMem[i],mskMem[i]} = {(2*PWID+1){1'b0}};

  // wMask thermometer decoder
  reg [PWID-1:0] wMaskThr;
  always @(*) begin
    for (i=0; i<PWID; i=i+1)
      wMaskThr[i] = (wMask>i) ? 1'b0 : 1'b1;
  end

  integer ai,aj;
  always @(posedge clk) begin
    // write to memory
    if (wEn)
      {vld[wAddr],patMem[wAddr],mskMem[wAddr]} = {1'b1,wPatt,wMaskThr};
    // search memory
    ai = 0;
    match = ((mskMem[0] & patMem[0])==(mskMem[0] & mPatt)) && vld[0];
    // find first match
    while ((!match) && (ai<(CDEP-1))) begin
      ai = ai+1;
      match = ((mskMem[ai] & patMem[ai])==(mskMem[ai] & mPatt)) && vld[ai];
    end
    mAddr    = ai        ;   
    wMaskMax = mskMem[ai];
    // find a match with longer prefix
    for (aj=ai+1; aj<CDEP; aj=aj+1) begin
      if (((mskMem[aj] & patMem[aj])==(mskMem[aj] & mPatt)) && vld[aj] && (mskMem[aj]>wMaskMax)) begin
        match    = 1'b1      ;
        mAddr    = aj        ;
        wMaskMax = mskMem[aj];
      end
    end
    // for testing only! generate all indicators	
    for (i=0; i<CDEP; i=i+1)
      mIndc[i] = ((mskMem[i] & patMem[i])==(mskMem[i] & mPatt)) && vld[i];	
  end

endmodule
