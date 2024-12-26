;
; Simple bootloader using bit bang UART
;
; Baudrate 19200 and 8 data bits
; Single start and stop bits
; No parity bit
;
; Memory address layout:
; 000 - 008 : reset and interrupt vectors
; 009 - 127 : bootloader
; 128 - 511 : main program memory
;
; UART programming protocol:
; Reset the device while pulling BOOT low to enter boot mode
; Then send the following bytes to the UART RX pin 
; 1   : program size low byte
; 2   : program size high byte (only lsb is considered)
; 3-> : program
; 
; The device will transmit 0xFF on the UART TX pin between 
; each received byte to indicate that it is ready to receive
; 
; The first 18 bytes of the program are assumed to contain the
; reset and interrupt vectors, as these require special handling
; 

#define __SFR_OFFSET 0
#define TX PB0
#define RX PB2
#define BOOT PB3
#define LED PB4
 
#include <avr/io.h>

;-----------------------------------------------------------------------------------

.global main
main:
  sbi PORTB, BOOT                         ; Attempt to pull BOOT high
  nop                                     ; Give time to stabalize
  sbic PINB, BOOT                         ; Read BOOT pin
  rjmp .-2                                ; Placeholder for jump to main program

;-----------------------------------------------------------------------------------

boot:
  sbi DDRB, LED
  sbi PORTB, LED                          ; Set user LED to indicate boot mode
  ; Set INT0_vect
  ; Init uart
  ; Wait for 
  rjmp boot

;-----------------------------------------------------------------------------------

uart_init:
  sbi DDRB, TX                            ; TX pin
  sbi PORTB, TX                           ; Drive line high
  ldi r16, (1 << ISC01)
  out MCUCR, r16                          ; INT0 falling edge
  ldi r16, (1 << INT0)
  out GIMSK, r16                          ; INT0 interrupt enable
  sei                                     ; Global interrupt enable
  ret

;-----------------------------------------------------------------------------------

INT0_vect:                                ; RX bit bang: output r2 and T flag set
  ldi r25, 0x5
  rcall delay
  sbic PINB, RX                           ; Read start bit
  reti
  ldi r16, 0x0                            ; Counter
rx_loop:
  ldi r25, 0xB
  rcall delay
  clc
  sbic PINB, RX
  sec
end_rx_loop:
  ror r2                                  ; Rotate output register
  inc r16
  cpi r16, 0x8                            ; Loop 8 times
  brne rx_loop
  ldi r25, 0xC
  rcall delay                             ; Wait on stop bit
  ldi r17, 0xff                           
  out GIFR, r17                           ; Clear interrupt flag
  set                                     ; Set T flag on success
  reti

;-----------------------------------------------------------------------------------

                                          ; loop length in r25 
delay:                                    ; (r25 + 1) * (1 + 1 + 2) - 1 + 4
  cpi r25, 0x0  ; 1
  dec r25       ; 1
  brne delay    ; 1 / 2
  ret           ; 4

;-----------------------------------------------------------------------------------

.global __vector_default                  ; default interrupt vectors
__vector_default:
  reti

;-----------------------------------------------------------------------------------

.end

