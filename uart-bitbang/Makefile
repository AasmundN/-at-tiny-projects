.DEFAULT_GOAL := upload

build: 
	avr-gcc -mmcu=attiny15 uart.S -o uart.out
	avr-objcopy -O binary uart.out uart.bin

upload: build
	isp write uart.bin
