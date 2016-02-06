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
//                           camctl.v: BCAM Controller                            //
//                                                                                //
//   Author: Ameer M.S. Abdelhadi (ameer@ece.ubc.ca; ameer.abdelhadi@gmail.com)   //
//   BRAM-based II-TCAM ; The University of British Columbia (UBC) ;  Dec. 2015   //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

// Controller /  Mealy FSM
module camctl
 #( parameter  PWRT = 1  ) // pipelined writes?
  ( input      clk       , // clock                              
    input      rst       , // global registers reset             
    input      wEn       , // global CAM write enable            
    input      cPattLast , // last pattern of pattern counter    
    output reg wEn_iVld  , // write enable / indicator valid RAM 
    output reg wEn_indx  , // write enable / indicator index RAM 
    output reg wEn_indc  , // write enable / full indicators MLABs
    output reg wEn_setram, // write enable / setram              
    output reg rst_cIdx  , // async reset  index counter/rrbcam  
    output reg wEn_cIdx  , // write enable index counter/rrbcam  
    output reg rst_cPatt , // async reset  / pattern counter     
    output reg wEn_cPatt , // write enable / pattern counter     
    output reg wBusy     );  // write busy                         

       
  // state declaration
  reg [2:0] curS, nxtS;
  localparam IDLE = 3'b000; // idle state
  localparam MEMW = 3'b001; // setram write
  localparam MEMR = 3'b011; // setram read
  localparam PREC = 3'b010; // pre-count
  localparam CNT1 = 3'b110; // pattern count (& tram write)
  localparam CNT2 = 3'b111; // pattern count (& tram write)

  // synchronous process
  always @(posedge clk, posedge rst)
    if (rst) curS <= IDLE;
    else     curS <= nxtS;

  // combinatorial process
  always @(*) begin
    // initial outputs
    wEn_iVld   = 1'b0; 
    wEn_indx   = 1'b0;
    wEn_indc   = 1'b0;
    wEn_setram = 1'b0;
    wEn_cIdx   = 1'b0;
    wEn_cPatt  = 1'b0;
    wBusy      = 1'b0;
    rst_cIdx   = 1'b1;
    rst_cPatt  = 1'b1;
    case (curS)
      IDLE: begin
              nxtS       = wEn ? MEMW : IDLE;
              wEn_setram = wEn ;
            end
      MEMW: begin
              nxtS       = MEMR;
              wEn_setram = 1'b0;
              wBusy      = 1'b1;
            end
      MEMR: begin
              nxtS       = PWRT ? PREC : CNT2;
              wBusy      = 1'b1;
            end
      PREC: begin
              nxtS       = CNT1;
              wBusy      = 1'b1;
              wEn_cPatt  = 1'b1;
              rst_cPatt  = 1'b0;
            end
      CNT1: begin
              nxtS       = CNT2;
              wBusy      = 1'b1;
              rst_cIdx   = 1'b0;
              rst_cPatt  = 1'b0;
            end
      CNT2: begin
              nxtS       = cPattLast ? IDLE : (PWRT ? CNT1 : CNT2);
              wEn_iVld   = 1'b1;
              wEn_indx   = 1'b1;
              wEn_indc   = 1'b1;
              wEn_cIdx   = 1'b1;
              wEn_cPatt  = 1'b1;
              wBusy      = 1'b1;
              rst_cIdx   = 1'b0;
              rst_cPatt  = 1'b0;
            end
    endcase
  end

endmodule

