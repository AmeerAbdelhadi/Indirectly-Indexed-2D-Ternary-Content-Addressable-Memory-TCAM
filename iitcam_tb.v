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
//            iitcam_tb.v: Indirectly-Indexed TCAM (II-TCAM) Testbench            //
//                                                                                //
//   Author: Ameer M.S. Abdelhadi (ameer@ece.ubc.ca; ameer.abdelhadi@gmail.com)   //
//   BRAM-based II-TCAM ; The University of British Columbia (UBC) ;  Dec. 2015   //
////////////////////////////////////////////////////////////////////////////////////

`timescale 1 ps/1 ps

`include "utils.vh"

// toggle a clock CLK TOGn times each with PHASE clock phase length
`define CLKTOG(CLK,TOGn,PHASE) repeat (TOGn) #PHASE CLK=!CLK

module iitcam_tb;

  localparam PHASE  = 10             ; // clock phase length
  localparam MWID   = `log2(`PWID*9) ; // pattern mask width
  localparam AWID   = `log2(`CDEP)+10; // address width
  localparam CYCREP = 10             ; // report every CYCBATCH if not verbosed

  reg pass      = 1'b1; // simulation passed
  reg ovrf      = 1'b0; // index overflow
  reg mIndc_cmp = 1'b1; // match indicator comparison
  reg match_cmp = 1'b1; // match comparison
  reg mAddr_cmp = 1'b1; // match address comparison  
  integer cycc  = 0   ; // cycle count
  integer rep_fd, ferr; // report file

  // interface signals
  reg                   clk   =  1'b0 ;
  reg                   rst   =  1'b1 ;
  reg                   wEn   =  1'b0 ;
  reg  [AWID      -1:0] wAddr = {(   AWID){1'b0}} ;
  reg  [9*`PWID   -1:0] wPatt = {(9*`PWID){1'b0}} ;
  reg  [9*`PWID   -1:0] mPatt = {(9*`PWID){1'b0}} ;
  reg  [MWID      -1:0] wMask = {(   MWID){1'b0}} ;
  wire               match_dut, match_bhv;
  wire [AWID      -1:0] mAddr_dut, mAddr_bhv;
  wire [1024*`CDEP-1:0] mIndc_bhv;
  wire wBusy;

  integer seed=`SEED;

  // generate clock
  always #PHASE clk=!clk;

  
  initial begin
    $write("curS=%b; wEn=%b; wEn_iVld=%b; wEn_indx=%b; wEn_indc=%b; wEn_setram=%b; wEn_cIdx=%b; wEn_cPatt=%b; rst_cIdx=%b; rst_cPatt=%b; wBusy=%b; cPatt=%b; cPattLast=%b; cIdx=%b; setIndc=%b; match_setIndc=%b; mAddr_setIndc=%b",
      iitcami.camctli.curS,
      iitcami.camctli.wEn,
      iitcami.wEn_iVld  ,
      iitcami.wEn_indx  ,
      iitcami.wEn_indc  ,
      iitcami.wEn_setram,
      iitcami.wEn_cIdx  ,
      iitcami.wEn_cPatt ,
      iitcami.rst_cIdx  ,
      iitcami.rst_cPatt ,
      iitcami.wBusy     ,
      iitcami.cPatt,
      iitcami.cPattLast,
      iitcami.STG[0].iitcam9bi.cIdx,
      iitcami.STG[0].iitcam9bi.setIndc,
      iitcami.STG[0].iitcam9bi.match_setIndc,
      iitcami.STG[0].iitcam9bi.mAddr_setIndc
    );
    rep_fd = $fopen("sim.res","r"); // try to open report file for read
    $ferror(rep_fd,ferr);       // detect error
    $fclose(rep_fd);
    rep_fd = $fopen("sim.res","a+"); // open report file for append
    if (ferr) begin     // if file is new (can't open for read); write header
      $fwrite(rep_fd," CAM match architecture | Pattern width (9-bits) | CAM depth (1k-entries) | Simulation random seed | Simulation cycle Count | Simulation test Result \n");     
      $fwrite(rep_fd,"========================|========================|========================|========================|========================|========================\n");
    end
    // print header
    $write("\n- Simulating TCAM with the following parameters:\n");
    $write("  * CAM match architecture: %0s\n"  ,`ARCH);
    $write("  * Pattern width (9-bits): %0d\n"  ,`PWID);
    $write("  * CAM depth (1k-entries): %0d\n"  ,`CDEP);
    $write("  * Simulation random seed: %0d\n"  ,`SEED);    
    $write("  * Simulation cycle Count: %0d\n\n",`CYCC);

    #(10*PHASE) rst = 1'b0; // exit reset
    #PHASE   
    //statdump(0);
    while (pass && (cycc<`CYCC)) begin
//    while ( (cycc<=`CYCC)) begin    
      wait(!wBusy);
      wEn = 1'b1; // enable writing
      `RNDVEC(wPatt,seed,  9*`PWID); // generate random write pattern
      `RNDUNI(wMask,seed,0,9*`PWID); // generate random pattern mask
      //`RNDVEC(wAddr,seed,     AWID); // generate random write address
        `RNDVEC(wAddr,seed,     AWID   ); // generate random write address
      wait(wBusy) ;
      wEn = 1'b0; // disable writing
      wait(!wBusy);
      #(20*PHASE)
      `RNDVEC(mPatt,seed,  9*`PWID); // generate random match pattern
      #(20*PHASE)      
      //pass = ((!match_dut) && (!match_bhv)) || (match_dut && match_bhv && (mAddr_dut == mAddr_bhv)); // compute equivalence
      ovrf = ((iitcami.STG[0].iitcam9bi.cIdx==5'b11111) && (iitcami.STG[0].iitcam9bi.wEn_cIdxI));
      mIndc_cmp = (mIndc_bhv == iitcami.mIndc); // match indicator comparison
      match_cmp = (match_dut == match_bhv     ); // match comparison
      mAddr_cmp = (mAddr_dut == mAddr_bhv     ); // match address comparison
      pass = mIndc_cmp && match_cmp && (mAddr_cmp || !match_dut || !match_bhv) && !ovrf;
      if (`VERBOSE || !pass) begin
        $write(">>> %07d: Write: wPatt=%h; wMask=%h; wAddr=%h --- Match: mPatt=%h; {match,mAddr}={ref:%b,%h}-{dut:%b,%h}; Overflow:%b - %s\n", // verbosed
                cycc,wPatt,wMask,wAddr,mPatt,match_bhv,mAddr_bhv,match_dut,mAddr_dut, ovrf, pass ? "PASS" : "FAIL");
        if (!pass) $write("mIndcB:%h\nmIndcD:%h\n",mIndc_bhv,iitcami.mIndc);
      end
      else if ((cycc+1)%CYCREP==0) $write("%07d-%07d: PASS\n",cycc-CYCREP+1,cycc); // report PASS/FAIL every 100 write/match operations
      //$write("%b=%b-%b-%b\n",iitcami.wMaskIOH,iitcami.STG[2].iitcam9bi.wMask,iitcami.STG[1].iitcam9bi.wMask,iitcami.STG[0].iitcam9bi.wMask);
      cycc=cycc+1;
    end
    //statdump(1);
    $fwrite(rep_fd," %-23s| %-23d| %-23d| %-23d| %-23d| %-23s\n",`ARCH,`PWID,`CDEP,`SEED,`CYCC,pass?"PASS":"FAIL");
    $write("\n*** Simulation %s after %0d cycles.\n\n",pass?"PASSED":"FAILED",cycc);
    $fclose(rep_fd);
    $finish;
  end

  // DUT: ii2dcam instantiation
  iitcam #( .ARCH (`ARCH    ),  // TCAM match architecture
            .CDEP (`CDEP    ),  // depth (k-entries, power of 2)
            .PWID (`PWID    ),  // pattern width (9-bits multiply)
            .PWRT (`PWRT    ),  // pipelined writes?
            .REGI (0        ),  // register inputs
            .REGO (0        ))  // register outputs
  iitcami ( .clk  (clk      ),  // clock               / input
            .rst  (rst      ),  // global reset        / input
            .wEn  (wEn      ),  // write enable        / input
            .wBusy(wBusy    ),  // write busy / initiated writes are ignores / output
            .wAddr(wAddr    ),  // write address       / input  [log2(CDEP)+9:0]
            .wPatt(wPatt    ),  // write pattern       / input  [PWID*9-1    :0]
            .wMask(wMask    ),  // pattern mask        / input [`log2(PWID*9)-1:0]
            .mPatt(mPatt    ),  // match pattern       / input  [PWID*9-1    :0]
            .match(match_dut),  // match (valid mAddr) / output
            .mAddr(mAddr_dut)); // match address       / output [log2(CDEP)+9:0]

  // generate and behavioral TCAM with specific implementation
  generate
    if (`ARCH=="PEM") begin
      // Behavioral priority-encoded-match (PEM) TCAM
      tcam_pem_bhv #( .CDEP (`CDEP*1024),  // CAM depth
                      .PWID (`PWID*9   ),  // CAM/pattern width
                      .INOM (1         ))  // binary          / Initial CAM with no match
      tcam_pem_inst ( .clk  (clk       ),  // clock           / input
                      .rst  (rst       ),  // global reset    / input
                      .wEn  (wEn       ),  // write enable    / input
                      .wAddr(wAddr     ),  // write address   / input [`log2(CDEP)  -1:0]
                      .wPatt(wPatt     ),  // write pattern   / input
                      .wMask(wMask     ),  // pattern mask    / input [`log2(PWID*9)-1:0]
                      .mPatt(mPatt     ),  // patern to match / input [      PWID   -1:0]
                      .match(match_bhv ),  // match indicator / output
                      .mIndc(mIndc_bhv ),  // match one-hot / for testing only
                      .mAddr(mAddr_bhv )); // matched address / output [`log2(CDEP) -1:0]
    end
    else begin
      // Behavioral longest-prefix-match (LPM) TCAM
      tcam_lpm_bhv #( .CDEP (`CDEP*1024),  // CAM depth
                      .PWID (`PWID*9   ),  // CAM/pattern width
                      .INOM (1         ))  // binary          / Initial CAM with no match
      tcam_lpm_inst ( .clk  (clk       ),  // clock           / input
                      .rst  (rst       ),  // global reset    / input
                      .wEn  (wEn       ),  // write enable    / input
                      .wAddr(wAddr     ),  // write address   / input [`log2(CDEP)  -1:0]
                      .wPatt(wPatt     ),  // write pattern   / input
                      .wMask(wMask     ),  // pattern mask    / input [`log2(PWID*9)-1:0]
                      .mPatt(mPatt     ),  // patern to match / input [      PWID   -1:0]
                      .match(match_bhv ),  // match indicator / output
                      .mIndc(mIndc_bhv ),  // match one-hot / for testing only                      
                      .mAddr(mAddr_bhv )); // matched address / output [`log2(CDEP) -1:0]
    end
  endgenerate
    
endmodule
