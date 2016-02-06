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
//           iitcam.v: Indirectly-Indexed TCAM (II-TCAM) Top Hierarchy            //
//                                                                                //
//   Author: Ameer M.S. Abdelhadi (ameer@ece.ubc.ca; ameer.abdelhadi@gmail.com)   //
//   BRAM-based II-TCAM ; The University of British Columbia (UBC) ;  Dec. 2015   //
////////////////////////////////////////////////////////////////////////////////////

`include "utils.vh"

// include config file for synthesis mode
`ifndef SIM
`include "config.vh"
`endif

module iitcam
 #( parameter                  ARCH = `ARCH ,  // TCAM match architecture
    parameter                  CDEP = `CDEP ,  // CAM depth (k-entries, power of 2)
    parameter                  PWID = `PWID ,  // pattern width (9-bits multiply)
    parameter                  PWRT = `PWRT ,  // pipelined writes?
    parameter                  REGM = 0     ,  // register MLAB outputs?
    parameter                  REGI = `REGI ,  // register inputs?
    parameter                  REGO = `REGO )  // register outputs?
  ( input                      clk          ,  // clock
    input                      rst          ,  // global reset
    input                      wEn          ,  // write enable
    output                     wBusy        ,  // write busy / initiated writes are ignores
    input  [`log2(CDEP)+9  :0] wAddr        ,  // write address
    input  [PWID*9-1:0]        wPatt        ,  // write pattern
    input  [`log2(PWID*9)-1:0] wMask        ,  // pattern mask
    input  [PWID*9-1:0]        mPatt        ,  // match pattern
    output                     match        ,  // match
    output [`log2(CDEP)+9  :0] mAddr        ); // match indicators

  localparam MWID = `log2(PWID*9); // pattern mask width
  integer i;                       // general loop index

  // register inputs
  reg                    wEnR  ;
  reg  [`log2(CDEP)+9:0] wAddrR;
  reg  [PWID*9-1:0]      wPattR;
  reg  [PWID*9-1:0]      mPattR;
  reg  [MWID  -1:0]      wMaskR;
  wire                   wEnI  ;
  wire [`log2(CDEP)+9:0] wAddrI;
  wire [PWID*9-1:0]      wPattI;
  wire [PWID*9-1:0]      mPattI;
  wire [MWID  -1:0]      wMaskI;
  always @(posedge clk, posedge rst)
    if (rst) {wEnR,wAddrR,mPattR,wPattR,wMaskR} <= {(`log2(CDEP)+18*PWID+MWID+11){1'b0}};
    else     {wEnR,wAddrR,mPattR,wPattR,wMaskR} <= 
             {wEn ,wAddr ,mPatt ,wPatt ,wMask } ;

  assign     {wEnI,wAddrI,mPattI,wPattI,wMaskI} = REGI  ?
             {wEnR,wAddrR,mPattR,wPattR,wMaskR} : 
             {wEn ,wAddr ,mPatt ,wPatt ,wMask } ;

  // register outputs
  reg                    matchR;
  reg  [`log2(CDEP)+9:0] mAddrR;
  wire                   matchI;
  wire [`log2(CDEP)+9:0] mAddrI;
  always @(posedge clk, posedge rst)
    if (rst) {matchR,mAddrR} <= {(`log2(CDEP)+11){1'b0}};
    else     {matchR,mAddrR} <= 
             {matchI,mAddrI} ;

    assign   {match ,mAddr } = REGO ?
             {matchR,mAddrR} :
             {matchI,mAddrI} ;

  // wMask thermometer decoder
  reg [PWID*9-1:0] wMaskIOH;
  always @(*) begin
    for (i=0;i<PWID*9;i=i+1)
      wMaskIOH[i] = (wMaskI>i) ? 1'b0 : 1'b1;
  end
  
///////////////////////////////////////////////////////////////////////////////
 
  wire wEn_iVld, wEn_indx, wEn_indc, wEn_setram, wEn_cPatt, wEn_cIdx; // controls /enables
  wire rst_cPatt, rst_cIdx; // controls /resets
  
  wire rst_cPattI = rst | rst_cPatt; // pattern counter reset

  reg [8:0] cPatt; // pattern counter
  always @(posedge clk, posedge rst_cPattI)
    if (rst_cPattI)     cPatt <= 9'b000000000      ;
    else if (wEn_cPatt) cPatt <= 9'b000000001+cPatt;

  wire cPattLast = & cPatt; // last count reached
  
  reg cPattLastR;  // 1 stage register of cPattLast
  always @(posedge clk, posedge rst)
    if (rst) cPattLastR <= 1'b0     ;
    else     cPattLastR <= cPattLast;

  reg cPattLastRR; // 2 stage register of cPattLast
  always @(posedge clk, posedge rst)
    if (rst) cPattLastRR <= 1'b0      ;
    else     cPattLastRR <= cPattLastR;

  // CAM write controller / Mealy FSM
  camctl #( .PWRT      (PWRT                           ))  // pipelined writes?
  camctli ( .clk       (clk                            ),  // clock                                / input 
            .rst       (rst                            ),  // global registers reset               / input
            .wEn       (wEn                            ),  // global CAM write enable              / input
            .cPattLast (PWRT ? cPattLastRR : cPattLastR),  // last pattern of pattern counter      / input
            .wEn_iVld  (wEn_iVld                       ),  // write enable / indicator valid RAM   / output
            .wEn_indx  (wEn_indx                       ),  // write enable / indicator index RAM   / output
            .wEn_indc  (wEn_indc                       ),  // write enable / full indicators MLABs / output
            .wEn_setram(wEn_setram                     ),  // write enable / setram                / output
            .rst_cIdx  (rst_cIdx                       ),  // async reset  index counter/rrbcam    / output
            .wEn_cIdx  (wEn_cIdx                       ),  // write enable index counter/rrbcam    / output
            .rst_cPatt (rst_cPatt                      ),  // async reset  / pattern counter       / output
            .wEn_cPatt (wEn_cPatt                      ),  // write enable / pattern counter       / output
            .wBusy     (wBusy                          )); // write busy                           / output

///////////////////////////////////////////////////////////////////////////////

  // instantiate slices of ii2dcam9b for each 9-bits of pattern
  wire [CDEP*1024-1:0] mIndc_i [PWID-1:0];
  genvar gi;
  generate
    for (gi=0 ; gi<PWID ; gi=gi+1) begin: STG
      // instantiate ii2dcam9b
      iitcam9b #( .CDEP (CDEP               ), // depth (k-entries)
                  .PWRT (PWRT               ), // pipelined writes? 
                  .REGM (REGM               )) // register MLAB outputs?
      iitcam9bi ( .clk  (clk                ), // clock           / input
                  .rst  (rst                ), // global reset    / input
                  .wEn  (wEnI               ), // write enable    / input
                  .wAddr(wAddrI             ), // write address   / input [AWID+9:0]
                  .wPatt(wPattI  [gi*9 +: 9]), // write pattern   / input [8     :0]
                  .wMask(wMaskIOH[gi*9 +: 9]), // pattern mask    / input [8     :0]
                  .mPatt(mPattI  [gi*9 +: 9]), // match pattern   / input [8     :0]
                  .cPatt(cPatt              ), // pattern counter / input [8     :0]
                   // control signals
                  .wEn_iVld  (wEn_iVld  ), // write enable / indicator valid RAM   / input
                  .wEn_indx  (wEn_indx  ), // write enable / indicator index RAM   / input
                  .wEn_indc  (wEn_indc  ), // write enable / full indicators MLABs / input
                  .wEn_setram(wEn_setram), // write enable / setram                / input
                  .rst_cIdx  (rst_cIdx  ), // async reset  index counter/rrbcam    / input
                  .wEn_cIdx  (wEn_cIdx  ), // write enable index counter/rrbcam    / input
                  //
                  .mIndc(mIndc_i [gi]      )); // match indicators // output [DEP*1024-1:0]
    end
  endgenerate

  // cascading by AND'ing matches
  reg [CDEP*1024-1:0] mIndc; // match one-hot
  always @(*) begin
    mIndc = {(CDEP*1024){1'b1}};
    for (i=0; i<PWID; i=i+1)
      mIndc = mIndc & mIndc_i[i];
  end

  // generate enoders with specific implementation
  wire [MWID*CDEP*1024-1:0] prf;
  generate
    if (ARCH=="PEM") begin : PEM
      // binary match (priority encoded) with CDEPx1k width
      `ifdef SIM
        pem_bhv #( .OHW(CDEP*1024) ) // behavioural priority encoder
      `else
        pem_out // generated automatically structural priority encoder // ./pem out `expr $CURCAMD \* 1024` 
      `endif
        pem_inst ( .clk(clk   ),  // clock for pipelined priority encoder
                   .rst(rst   ),  // registers reset for pipelined priority encoder
                   .oht(mIndc ),  // one-hot match input / in : [      CDEP -1:0]
                   .bin(mAddrI),  // first match index   / out: [`log2(CDEP)-1:0]
                   .vld(matchI)); // match indicator     / out
    end
    else begin : LPM
      // Behavioral longest-prefix-match (LPM)
      prefreg #( .PRFW(MWID     ),  // prefix width (log2(pattern width))
                 .PRFN(CDEP*1024))  // number of prefixes (equals to CAM depth)
      prefregi ( .clk (clk      ),  // clock                      / input
                 .rst (rst      ),  // asyncronous reset          / input
                 .wEn (wEn      ),  // write enable               / input
                 .prfa(wAddr    ),  // prefix address             / input  [`log2(PRFN)-1:0]
                 .prfd(wMask    ),  // prefix register data input / input  [PRFW       -1:0]
                 .prfq(prf      )); // prefix register output     / output [PRFW*PRFN  -1:0]
//      `ifdef SIM
//        lpm_bhv #( .OHW (CDEP*1024), // encoder one-hot input width
//                   .PRFW(MWID     )) // prefix width
//      `else
        lpm_out // generated automatically structural longest-prefix-match (LPM) // ./lpm out `expr $CURCAMD \* 1024` `perl -e 'use POSIX; print ceil(log(9)/log(2))'`
//      `endif
        lpm_inst ( .clk(clk)      ,  // clock for pipelined LPM encoder           / input
                   .rst(rst)      ,  // registers reset for pipelined LPM encoder / input
                   .oht(mIndc)    ,  // one-hot input                    / input      [      OHW -1:0]
                   .prf(prf)      ,  // prefixes                         / input      [ PRFW*OHW -1:0]
                   .bin(mAddrI)   ,  // first '1' index                  / output [`log2(OHW)-1:0]
                   .vld(matchI)   ); // binary is valid if one was found / output                
    end
  endgenerate

endmodule
