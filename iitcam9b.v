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
//       iitcam9b.v: Indirectly-Indexed TCAM (II-TCAM) 9-bits Pattern Stage       //
//                                                                                //
//   Author: Ameer M.S. Abdelhadi (ameer@ece.ubc.ca; ameer.abdelhadi@gmail.com)   //
//   BRAM-based II-TCAM ; The University of British Columbia (UBC) ;  Dec. 2015   //
////////////////////////////////////////////////////////////////////////////////////


`include "utils.vh"

module iitcam9b
 #( parameter                CDEP = 4 , // depth (k-entries, power of 2)
    parameter                PWRT = 1 , // pipelined writes?
    parameter                REGM = 1 ) // register MLAB outputs?
  ( input                    clk      , // clock
    input                    rst      , // global registers reset
    input                    wEn      , // write enable
    input  [`log2(CDEP)+9:0] wAddr    , // write address
    input  [8            :0] wPatt    , // write pattern
    input  [8            :0] wMask    , // write pattern mask
    input  [8            :0] mPatt    , // match pattern
    input  [8            :0] cPatt    , // pattern counter
    // control signals
    input  wEn_iVld  , // write enable / indicator valid RAM
    input  wEn_indx  , // write enable / indicator index RAM
    input  wEn_indc  , // write enable / full indicators MLABs
    input  wEn_setram, // write enable / setram
    input  rst_cIdx  , // async reset  index counter/rrbcam
    input  wEn_cIdx  , // write enable index counter/rrbcam
    //
    output [CDEP*1024-1:0]   mIndc    ); // match indicators

///////////////////////////////////////////////////////////////////////////////

  // local parameters
  localparam AWID= `log2(CDEP); // AWID (k-enrties); add 10 for full address

  // internal signals
  wire [31:0] setIndc;
  wire match_setIndc;
  wire [4:0] mAddr_setIndc;
  wire pattIndc = | setIndc;
  reg [4:0] cIdx; // index counter

  reg [31:0] setIndcR;
  always @(posedge clk, posedge rst)
    if (rst) setIndcR <= 32'h00000000;
    else     setIndcR <= setIndc;

  reg pattIndcR;
  always @(posedge clk, posedge rst)
    if (rst) pattIndcR <= 1'b0;
    else     pattIndcR <= pattIndc;

  reg [8:0] cPattR;
  always @(posedge clk, posedge rst)
    if (rst) cPattR <= 9'b000000000;
    else     cPattR <= cPatt;

  reg [8:0] cPattRR;
  always @(posedge clk, posedge rst)
    if (rst) cPattRR <= 9'b000000000;
    else     cPattRR <= cPattR;

///////////////////////////////////////////////////////////////////////////////

  // instantiate transposed-RAM
  iitram9b #( .DEP       (CDEP                                 ),  // depth (k-entries, power of 2)
              .REGM      (REGM                                 ))  // register MLAB outputs?
  iitram9bi ( .clk       (clk                                  ),  // clock                                      / input
              .rst       (rst                                  ),  // global registers reset                     / input
              .wEn_iVld  (wEn_iVld                             ),  // write enable / indicator valid RAM         / input
              .wEn_indx  (wEn_indx && (PWRT?pattIndcR:pattIndc)),  // write enable / indicator index RAM         / input
              .wEn_indc  (wEn_indc && (PWRT?pattIndcR:pattIndc)),  // write enable / full indicators MLABs       / input
              .mPatt     (mPatt                                ),  // match pattern                              / input  [8       :0]
              .wPatt     (PWRT ? cPattRR : cPattR              ),  // write pattern                              / input  [8       :0]
              .wAddr_indx(wAddr[AWID+9:5]                      ),  // write address / index                      / input  [AWID+4  :0]
              .wAddr_indc(match_setIndc ? mAddr_setIndc : cIdx ),  // write address / indicator (in index range) / input  [4       :0]
              .wIndx     (match_setIndc ? mAddr_setIndc : cIdx ),  // write index                                / input  [4       :0]
              .wIVld     (PWRT ? pattIndcR : pattIndc          ),  // write indicator validity                   / input
              .wIndc     (PWRT ? setIndcR  : setIndc           ),  // write indicator (full)                     / input  [31      :0]
              .mIndc     (mIndc                                )); // match indicators                           / output [DEP*1k-1:0]

///////////////////////////////////////////////////////////////////////////////

    // instantiate sets RAM
  setram #( .CDEP   (CDEP      ),  // CAM depth (k-entries)
            .REGO   (1         ))  // registered output?
  setrami ( .clk    (clk       ),  // clock                     / input
            .rst    (rst       ),  // global registers reset    / input
            .wEn    (wEn_setram),  // write enable              / input
            .wPatt  (wPatt     ),  // write pattern             / input  [8     :0]
            .wMask  (wMask     ),  // write mask                / input  [8     :0]
            .cPatt  (cPatt     ),  // counted pattern (0 to 511)/ input  [8     :0]
            .addr   (wAddr     ),  // read/write address        / input  [AWID+9:0]
            .setIndc(setIndc   )); // set indicators            / output [31    :0]

///////////////////////////////////////////////////////////////////////////////

  wire wEn_cIdxI = wEn_cIdx & !match_setIndc & (PWRT ? pattIndcR : pattIndc);

  // index counter
  wire rst_cIdxI = rst | rst_cIdx;
  always @(posedge clk, posedge rst_cIdxI)
    if (rst_cIdxI)      cIdx <= 5'b00000     ;
    else if (wEn_cIdxI) cIdx <= 5'b00001+cIdx;

  // instantiate writing indicators register-based bcam 
  bcam_reg #( .CDEP (32                   ),  // CAM depth
              .PWID (32                   ),  // pattern width
              .REGO (PWRT                 ))  // register output
  indcbcam  ( .clk  (clk                  ),  // clock               / input
              .rst  (rst_cIdxI            ),  // global reset        / input
              .wEn  (wEn_cIdxI            ),  // write enable        / input
              .wAddr(cIdx                 ),  // write address       / input  [AWID-1:0]
              .wPatt(PWRT?setIndcR:setIndc),  // write pattern       / input  [PWID-1:0]
              .mPatt(setIndc              ),  // match pattern       / input  [PWID-1:0]
              .match(match_setIndc        ),  // match (valid mAddr) / output
              .mAddr(mAddr_setIndc        )); // match address       / output [AWID-1:0]
      
endmodule
