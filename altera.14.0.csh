#!/usr/bin/env tcsh

####################################################################################
## Copyright (c) 2015 ; The University of British Columbia ; All rights reserved. ##
##                                                                                ##
## Redistribution  and  use  in  source   and  binary  forms,   with  or  without ##
## modification,  are permitted  provided that  the following conditions are met: ##
##   * Redistributions   of  source   code  must  retain   the   above  copyright ##
##     notice,  this   list   of   conditions   and   the  following  disclaimer. ##
##   * Redistributions  in  binary  form  must  reproduce  the  above   copyright ##
##     notice, this  list  of  conditions  and the  following  disclaimer in  the ##
##     documentation and/or  other  materials  provided  with  the  distribution. ##
##   * Neither the name of the University of British Columbia (UBC) nor the names ##
##     of   its   contributors  may  be  used  to  endorse  or   promote products ##
##     derived from  this  software without  specific  prior  written permission. ##
##                                                                                ##
## THIS  SOFTWARE IS  PROVIDED  BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" ##
## AND  ANY EXPRESS  OR IMPLIED WARRANTIES,  INCLUDING,  BUT NOT LIMITED TO,  THE ##
## IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE ##
## DISCLAIMED.  IN NO  EVENT SHALL University of British Columbia (UBC) BE LIABLE ##
## FOR ANY DIRECT,  INDIRECT,  INCIDENTAL,  SPECIAL,  EXEMPLARY, OR CONSEQUENTIAL ##
## DAMAGES  (INCLUDING,  BUT NOT LIMITED TO,  PROCUREMENT OF  SUBSTITUTE GOODS OR ##
## SERVICES;  LOSS OF USE,  DATA,  OR PROFITS;  OR BUSINESS INTERRUPTION) HOWEVER ##
## CAUSED AND ON ANY THEORY OF LIABILITY,  WHETHER IN CONTRACT, STRICT LIABILITY, ##
## OR TORT  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE ##
## OF  THIS SOFTWARE,  EVEN  IF  ADVISED  OF  THE  POSSIBILITY  OF  SUCH  DAMAGE. ##
####################################################################################

####################################################################################
##             Setup environment variables and Altera's 14.0 CAD tools            ##
##                                                                                ##
##   Author: Ameer M.S. Abdelhadi (ameer@ece.ubc.ca; ameer.abdelhadi@gmail.com)   ##
##   BRAM-based II-TCAM ; The University of British Columbia (UBC) ;  Dec. 2015   ##
####################################################################################

# change these parameters to your own flow if necessary

set LICsrv1 = mflex1.ece.ubc.ca       # local license server
set LICprt1 = 27001                   # port at local licence server 
set LICsrv2 = altera-rlm.ece.ubc.ca   # local license server
set LICprt2 = 27001                   # port at local licence server 

setenv ALTROOT /CMC/tools/altera/14.0 # Altera's CAD tools root

####################### Do not Change script after this line #######################

setenv LM_LICENSE_FILE ${LICprt2}@${LICsrv2}:${LICprt1}@${LICsrv1}

setenv PATH ${ALTROOT}/quartus/bin:${ALTROOT}/modelsim_ae/bin:${ALTROOT}/nios2eds/bin:${ALTROOT}/hld/bin:${PATH}
