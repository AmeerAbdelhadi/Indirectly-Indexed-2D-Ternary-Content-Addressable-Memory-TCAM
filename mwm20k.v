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
//                    mwm20k.v: Altera's M20K mixed width RAM                     //
//                                                                                //
//   Author: Ameer M.S. Abdelhadi (ameer@ece.ubc.ca; ameer.abdelhadi@gmail.com)   //
//   BRAM-based II-TCAM ; The University of British Columbia (UBC) ;  Dec. 2015   //
///////////////////////////////////////////////////////////////////////////////////

// M20K Block Mixed-Width Configurations (Simple Dual-Port RAM Mode)
//  --------------------------------------------------------------------------------
// |     Write | 16384 | 8192 | 4096 | 4096 | 2048 | 2048 | 1024 | 1024 | 512 | 512 |
// | Read      | X 1   | X 2  | X 4  | X 5  | X 8  | X 10 | X 16 | X 20 | X32 | X40 |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// |16384 X 1  |  Yes  | Yes  | Yes  |      | Yes  |      | Yes  |      | Yes |     |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// | 8192 X 2  |  Yes  | Yes  | Yes  |      | Yes  |      | Yes  |      | Yes |     |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// | 4096 X 4  |  Yes  | Yes  | Yes  |      | Yes  |      | Yes  |      | Yes |     |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// | 4096 X 5  |       |      |      | Yes  |      | Yes  |      | Yes  |     | Yes |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// | 2048 X 8  | Yes   | Yes  | Yes  |      | Yes  |      | Yes  |      | Yes |     |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// | 2048 X 10 |       |      |      | Yes  |      | Yes  |      | Yes  |     | Yes |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// | 1024 X 16 | Yes   | Yes  | Yes  |      | Yes  |      | Yes  |      | Yes |     |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// | 1024 X 20 |       |      |      | Yes  |      | Yes  |      | Yes  |     | Yes |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// |  512 X 32 | Yes   | Yes  | Yes  |      | Yes  |      | Yes  |      | Yes |     |
//  -----------|-------|------|------|------|------|------|------|------|-----|-----|
// |  512 X 40 |       |      |      | Yes  |      | Yes  |      | Yes  |     | Yes |
//  --------------------------------------------------------------------------------

`include "utils.vh"

module mwm20k
 #( parameter                            WWID  = 5   ,  // write width
    parameter                            RWID  = 40  ,  // read width
    parameter                            WDEP  = 4096, // write lines depth
    parameter                            OREG  = 0   , // read output reg
    parameter                            INIT  = 1   )  // initialize to zeros
  ( input                                clk         ,  // clock
    input                                rst         ,  // global registers reset
    input                                wEnb        ,  // write enable
    input  [`log2(WDEP)-1            :0] wAddr       ,  // write address
    input  [WWID-1                   :0] wData       ,  // write data
    input  [`log2(WDEP/(RWID/WWID))-1:0] rAddr       ,  // read address
    output [RWID-1                   :0] rData       ); // read data

  localparam RDEP  = WDEP/(RWID/WWID); // read lines depth
  localparam WAWID = `log2(WDEP)     ; // write address width
  localparam RAWID = `log2(RDEP)     ; // read  address width
  
  // Altera's M20K mixed width RAM instantiation
  altsyncram #( .address_aclr_b                     ("CLEAR0"           ),
                .address_reg_b                      ("CLOCK0"           ),
                .clock_enable_input_a               ("BYPASS"           ),
                .clock_enable_input_b               ("BYPASS"           ),
                .clock_enable_output_b              ("BYPASS"           ),
                .intended_device_family             ("Stratix V"        ),
                .lpm_type                           ("altsyncram"       ),
                .numwords_a                         (WDEP               ),
                .numwords_b                         (RDEP               ),
                .operation_mode                     ("DUAL_PORT"        ),
                .outdata_aclr_b                     ("CLEAR0"           ),
                .outdata_reg_b                      (OREG?"CLOCK0":"UNREGISTERED"),
                .power_up_uninitialized             (INIT?"FALSE":"TRUE"),
                .ram_block_type                     ("M20K"             ),
                .read_during_write_mode_mixed_ports ("OLD_DATA"         ),
                .widthad_a                          (WAWID              ),
                .widthad_b                          (RAWID              ),
                .width_a                            (WWID               ),
                .width_b                            (RWID               ),
                .width_byteena_a                    (1                  ))
  altsyncm20k ( .aclr0                              (rst                ),
                .address_a                          (wAddr              ),
                .clock0                             (clk                ),
                .data_a                             (wData              ),
                .wren_a                             (wEnb               ),
                .address_b                          (rAddr              ),
                .q_b                                (rData              ),
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
                .data_b                             ({RWID{1'b1}}       ),
                .eccstatus                          (                   ),
                .q_a                                (                   ),
                .rden_a                             (1'b1               ),
                .rden_b                             (1'b1               ),
                .wren_b                             (1'b0               ));

endmodule

