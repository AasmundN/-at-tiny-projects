;
; Bit banged UART 
; Baudrate 19200 and 8 data bits
; Single start and stop bits
; No parity bit
;

#define __SFR_OFFSET 0
#define TX PB0

#include <avr/io.h>

;-----------------------------------------------------------------------------------

.global main
main:
  rcall uart_init
main_loop:                                ; Main program loop
  ldi r24, 'a'
  rcall uart_tx
  ldi r25, 0xff
  rcall delay
  rjmp main_loop

;-----------------------------------------------------------------------------------

uart_init:
  sbi DDRB, TX                            ; TX pin
  sbi PORTB, TX                           ; Drive line high
  ret

;-----------------------------------------------------------------------------------

uart_tx:                                  ; Bit bang UART transmition
  cbi PORTB, TX                           ; Start bit
  ldi r16, 0x0
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
  ret

;-----------------------------------------------------------------------------------

delay:                                    ; loop length in r25
  cpi r25, 0x0
  dec r25
  brne delay
  ret 

;-----------------------------------------------------------------------------------

.end

