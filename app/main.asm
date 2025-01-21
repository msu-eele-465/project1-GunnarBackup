; --COPYRIGHT--,BSD_EX
;  Copyright (c) 2016, Texas Instruments Incorporated
;  All rights reserved.
;
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions
;  are met:
;
;  *  Redistributions of source code must retain the above copyright
;     notice, this list of conditions and the following disclaimer.
;
;  *  Redistributions in binary form must reproduce the above copyright
;     notice, this list of conditions and the following disclaimer in the
;     documentation and/or other materials provided with the distribution.
;
;  *  Neither the name of Texas Instruments Incorporated nor the names of
;     its contributors may be used to endorse or promote products derived
;     from this software without specific prior written permission.
;
;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
;  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
;  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
;  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
;  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
;  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
;  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
;  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
;  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
; ******************************************************************************
;
;                        MSP430 CODE EXAMPLE DISCLAIMER
;
;  MSP430 code examples are self-contained low-level programs that typically
;  demonstrate a single peripheral function or device feature in a highly
;  concise manner. For this the code may rely on the device's power-on default
;  register values and settings such as the clock configuration and care must
;  be taken when combining code from several examples to avoid potential side
;  effects. Also see www.ti.com/grace for a GUI- and www.ti.com/msp430ware
;  for an API functional library-approach to peripheral configuration.
;
; --/COPYRIGHT--
;******************************************************************************
;  MSP430FR235x Demo - Toggle P1.0 using software
;
;  Description: Toggle P1.0 every 0.1s using software.
;  By default, FR235x select XT1 as FLL reference.
;  If XT1 is present, the PxSEL(XIN & XOUT) needs to configure.
;  If XT1 is absent, switch to select REFO as FLL reference automatically.
;  XT1 is considered to be absent in this example.
;  ACLK = default REFO ~32768Hz, MCLK = SMCLK = default DCODIV ~1MHz.
;
;           MSP430FR2355
;         ---------------
;     /|\|               |
;      | |               |
;      --|RST            |
;        |           P1.0|-->LED
;
;   Cash Hao
;   Texas Instruments Inc.
;   November 2016
;   Built with Code Composer Studio v6.2.0
;******************************************************************************
            .cdecls C,LIST,"msp430.h"  ; Include device header file
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
            .global __STACK_END
            .sect   .stack                  ; Make stack linker segment ?known?

            .text                           ; Assemble to Flash memory
            .retain                         ; Ensure current section gets linked
            .retainrefs

;---------Main Setup--------------------------------------------------

RESET       mov.w   #__STACK_END,SP         ; Initialize stack pointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT

SetupP1     bic.b   #BIT0,&P1OUT            ; Clear P1.0 output
            bis.b   #BIT0,&P1DIR            ; P1.0 output
            bic.b   #BIT6,&P6OUT            ; Clear P6.6 output
            bis.b   #BIT6,&P6DIR            ; P6.6 output
            bic.w   #LOCKLPM5,&PM5CTL0      ; Unlock I/O pins

;----------Setup Timer-----------------------------------------------

            bis.w   #TBCLR, &TB0CTL         ; Clear Timers/Dividers
            bis.w   #TBSSEL__SMCLK, &TB0CTL ; Use SMCLK
            bis.w   #MC__UP, &TB0CTL        ; Set UP counter
            bis.w   #CNTL_0, &TB0CTL        ; 16 bit count length
            bis.w   #ID__4, &TB0CTL         ; divide by 4
            bis.w   #TBIDEX__7, &TB0EX0     ; divide by 8

            mov.w   #37275d, &TB0CCR0       ; Set Value to 32150 (decimal)
            bis.w   #CCIE, &TB0CCTL0        ; Enable Interrupt
            bic.w   #CCIFG, &TB0CCTL0       ; Clear Flag

            nop
            bis.w   #GIE, SR                ; Enable Maskable Interrupt
            nop

;----------Main Loop-------------------------------------------------

Main:
            call    #FlashRED               ; flash the red LED
            
            jmp     Main                    ; loop main infinitely
            NOP
            
;------------------------------------------------------------------------------
;           Subroutines
;------------------------------------------------------------------------------

FlashRED:
            xor.b   #BIT0,&P1OUT            ; Toggle P1.0
            mov.w   #001FFh, R14             ; Set Outer Delay Loop
            call    #Delay
            ret

Delay:
OutDelNotZero:
            mov.w   #001FFh, R5             ; Set Inner Delay Loop
InDelNotZero:
            dec     R5                      ; Decrease Inner Delay
            cmp.w   #00000h, R5             ; Check if Inner Delay = 0
            jnz     InDelNotZero           ; Do not advance if delay != 0
            dec     R14                      ; Decrease Outer Loop
            cmp.w   #00000h, R14             ; Check if Outer Delay = 0
            jnz     OutDelNotZero          ; Do not advance if delay != 0

            ret

;------------------------------------------------------------------------------
;           Interrupt Service Routines
;------------------------------------------------------------------------------

ISR_TB0_CCR0:
            xor.b   #BIT6,&P6OUT            ; Toggle P6.6/Flash Green LED
            bic.w   #CCIFG, &TB0CCTL0
            reti

;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------

            .sect   RESET_VECTOR            ; MSP430 RESET Vector
            .short  RESET                   ;

            .sect   ".int43"
            .short  ISR_TB0_CCR0

            .end
