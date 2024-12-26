;
; Bit banged UART echo
; Baudrate 19200 and 8 data bits
; Single start and stop bits
; No parity bit
;

#define __SFR_OFFSET 0
#define TX PB0
#define RX PB2

#include <avr/io.h>

;-----------------------------------------------------------------------------------

.global main
main:
  rcall uart_init
main_loop:                                ; Main program loop
  brtc main_loop                          ; Check T bit
  mov r24, r2                             ; Echo received char
  rcall uart_tx
  clt                                     ; Clear T bit
  rjmp main_loop

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

uart_tx:                                  ; TX bit bang: input in r24
  cli
  cbi PORTB, TX                           ; Start bit
  ldi r16, 0x0                            ; Counter
  ldi r25, 0xB
  rcall delay
tx_loop:
  mov r18, r24 
  andi r18, 0x1
  cpi r18, 0x1
  brne set_zero
  sbi PORTB, TX                           ; Transmit 1
  ldi r25, 0x9
  rcall delay
  rjmp end_tx_loop
set_zero:
  cbi PORTB, TX                           ; Transmit 0
  ldi r25, 0xA
  rcall delay
end_tx_loop:
  lsr r24                                 ; Shift to get next bit in position
  inc r16
  cpi r16, 0x8                            ; Loop 8 times
  brne tx_loop
  sbi PORTB, TX                           ; Single stop bit 
  sei
  ret

;-----------------------------------------------------------------------------------

.global INT0_vect                         ; RX bit bang: output r2 and T flag set
INT0_vect:
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
; (r25 + 1) * (1 + 1 + 2) - 1 + 4
delay:
  cpi r25, 0x0  ; 1
  dec r25       ; 1
  brne delay    ; 1 / 2
  ret           ; 4

;-----------------------------------------------------------------------------------

.end

