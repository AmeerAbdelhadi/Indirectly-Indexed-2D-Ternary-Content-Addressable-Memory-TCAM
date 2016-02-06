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
//                 dpmlab.v: Altera's MLAB (LUTRAM) dual-port RAM                 //
//                                                                                //
//   Author: Ameer M.S. Abdelhadi (ameer@ece.ubc.ca; ameer.abdelhadi@gmail.com)   //
//   BRAM-based II-TCAM ; The University of British Columbia (UBC) ;  Dec. 2015   //
////////////////////////////////////////////////////////////////////////////////////


`include "utils.vh"

module dpmlab
 #( parameter                DWID  = 20        ,  // data width
    parameter                DDEP  = 32        ,  // data depth
    parameter                MRDW  = "OLD_DATA",  // mixed ports read during write mode ("NEW_DATA", "OLD_DATA", or "DONT_CARE")
    parameter                RREG  = "ALL"     ,  // read port registe: "ADDR" for address, "ROUT", for read output, "ALL" for both.
    parameter                INIT  = 1         )  // initialize to zeros
  ( input                    clk               ,  // clock
    input                    rst               ,  // global registers reset
    input                    wEnb              ,  // write enable
    input  [`log2(DDEP)-1:0] wAddr             ,  // write address
    input  [DWID-1       :0] wData             ,  // write data
    input  [`log2(DDEP)-1:0] rAddr             ,  // read address
    output [DWID-1       :0] rData             ); // read data

  localparam AWID = `log2(DDEP)     ; // write address width
  
  // Altera's dual-port MLAB instantiation
  altsyncram #( .address_aclr_b                     ("CLEAR0"             ),
                .address_reg_b                      ((RREG=="ADDR"|RREG=="ALL")?"CLOCK0":"UNREGISTERED"),
                .clock_enable_input_a               ("BYPASS"           ),
                .clock_enable_input_b               ("BYPASS"           ),
                .clock_enable_output_b              ("BYPASS"           ),
                .intended_device_family             ("Stratix V"        ),
                .lpm_type                           ("altsyncram"       ),
                .numwords_a                         (DDEP               ),
                .numwords_b                         (DDEP               ),
                .operation_mode                     ("DUAL_PORT"        ),
                .outdata_aclr_b                     ("CLEAR0"             ),
                .outdata_reg_b                      ((RREG=="ROUT"|RREG=="ALL")?"CLOCK0":"UNREGISTERED"),
                .power_up_uninitialized             (INIT?"FALSE":"TRUE"),
                .ram_block_type                     ("MLAB"             ),
                .read_during_write_mode_mixed_ports (MRDW               ),
                .widthad_a                          (AWID               ),
                .widthad_b                          (AWID               ),
                .width_a                            (DWID               ),
                .width_b                            (DWID               ),
                .width_byteena_a                    (1                  ))
  altsyncmlab ( .address_a                          (wAddr              ),
                .clock0                             (clk                ),
                .data_a                             (wData              ),
                .wren_a                             (wEnb               ),
                .address_b                          (rAddr              ),
                .q_b                                (rData              ),
                .aclr0                              (rst                ),
                .aclr1                              (1'b0               ),
                .addressstall_a                     (1'b0               ),
                .addressstall_b                     (1'b0               ),
                .byteena_a                          (1'b1               ),
                .byteena_b                          (1'b1               ),
                .clock1                             (1'b1               ),
                .clocken0                           (1'b1               ),
                .clocken1                           (1'b1               ),
                .clocken2                           (1'b1               ),
                .clocken3                           (1'b1               ),
                .data_b                             ({DWID{1'b1}}       ),
                .eccstatus                          (                   ),
                .q_a                                (                   ),
                .rden_a                             (1'b1               ),
                .rden_b                             (1'b1               ),
                .wren_b                             (1'b0               ));

endmodule

