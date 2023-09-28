#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>

int getResponseType(unsigned char, unsigned char);
void printType(int);

int main(int argc, unsigned char argv[]) {
	int fd, len, response, data, data_float;
	unsigned char text[255];
	struct termios options; /* Serial ports setting */

	fd = open("/dev/ttyS0", O_RDWR | O_NDELAY | O_NOCTTY);
	if (fd < 0) {
		perror("Error opening serial port");
		return -1;
	}

	/* Read current serial port settings */
	// tcgetattr(fd, &options);
	
	/* Set up serial port */
	options.c_cflag = B9600 | CS8 | CLOCAL | CREAD;
	options.c_iflag = IGNPAR;
	options.c_oflag = 0;
	options.c_lflag = 0;
	
	/* Apply the settings */
	tcflush(fd, TCIFLUSH);
	tcsetattr(fd, TCSANOW, &options);
	
	while (1){
		// Lê da porta serial
		memset(text, 0, 255);
		len = read(fd, text, 255);
		// printf("Received %d bytes\n", len);
		
		sleep(2);

		response = getResponseType(text[0], text[1]);
		
		printType(response);
		

		if (response == 3 || response == 4){
			data = text[2];
			data_float = text[3];
			
			if (data == 0){
		  		response = getResponseType(text[0], text[1]);
  				printf("Erro\n");
			} else{
				if (response == 3){
					printf("%d.%d%%\n\n", data, data_float);
				} else if (response == 4) {
					printf("%d.0 ºC\n\n", data);
				}
			} 
			

		}
		
		
		
	}

	close(fd);
	return 0;
}


int getResponseType(unsigned char response1, unsigned char response2){
	if (response1 == 0x00 && response2 == 0x00){
		return 0;

	} else if (response1 == 0x1F && response2 == 0x1F){
		return 1;

	} else if (response1 == 0x07 && response2 == 0x07){
		return 2;

	} else if (response1 == 0x08 && response2 == 0x08){
		return 3;

	} else if (response1 == 0x09 && response2 == 0x09){
		return 4;

	} else if (response1 == 0x0A && response2 == 0x0A){
		return 5;

	} else if (response1 == 0x0B && response2 == 0x0B){
		return 6;

	} else {
		return -1;
	}
}

void printType(int response){
	if (response == 1){
		printf("Sensor com problema!\n");

	} else if (response == 2){
		printf("Sensor funcionando!\n");

	} else if (response == 3){
		printf("Medida da umidade: \n");

	} else if (response == 4){
		printf("Medida da temperatura: \n");

	} else if (response == 5){
		printf("Parando sensoriamento continuo de temperatura...\n");

	} else if (response == 6){
		printf("Parando sensoriamento continuo de umidade...\n");

	} else if (response == -1) {
		printf("Dados inconsistentes!");
	}
}
