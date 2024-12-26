.DEFAULT_GOAL := upload

build: 
	avr-gcc -mmcu=attiny15 bootloader.S -o bootloader.out
	avr-objcopy -O binary bootloader.out bootloader.bin

upload: build
	isp write bootloader.bin
