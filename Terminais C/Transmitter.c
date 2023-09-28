#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <ctype.h>
#include <termios.h>

struct DataPack{
    unsigned char instruction;
    unsigned char address;
};

int serialPortConfig(int);
int sendData(int, unsigned char *);

int main() {
    int fd;
    int option_type, sent;
    
    char instr_type[50];

    struct DataPack pack;

    pack.address = 0x00; // Sensor

        fd = open("/dev/ttyS0", O_RDWR | O_NDELAY | O_NOCTTY);
        if (fd < 0) {
                perror("Error opening serial port");
                return -1;
        }

        struct termios options; /* Serial ports setting */

        options.c_cflag = B9600 | CS8 | CLOCAL | CREAD;
        options.c_iflag = IGNPAR;
        options.c_oflag = 0;
        options.c_lflag = 0;

        tcflush(fd, TCIFLUSH);
        tcsetattr(fd, TCSANOW, &options);


    while (1){
    	
    	if (option_type == 4 || option_type == 5){
    		printf("Solicitando sensoriamento continuo...\n\n\n");
    	}
        printf("\t\t _________________________________________________ \n");
        printf("\t\t|                                                 |\n");
        printf("\t\t|                Escolha uma opcao:               |\n");
        printf("\t\t| ----------------------------------------------- |\n");
        printf("\t\t| [1] Status do sensor                            |\n");
        printf("\t\t| [2] Sensoriamento de temperatura atual          |\n");
        printf("\t\t| [3] Sensoriamento de umidade atual              |\n");
        printf("\t\t| [4] Sensoriamento continuo de temperatura       |\n");
        printf("\t\t| [5] Sensoriamento continuo de umidade           |\n");
        printf("\t\t| [6] Parar sensoriamento continuo de temperatura |\n");
        printf("\t\t| [7] Parar sensoriamento continuo de umidade     |\n");
        printf("\t\t| _______________________________________________ |\n");

        scanf("%i", &option_type);
	
        sent = 0;
        switch (option_type){

            case 1:
                pack.instruction = 0x00;
                strcpy(instr_type, "status do sensor");
                break;

            case 2:
                pack.instruction = 0x01;
                strcpy(instr_type, "temperatura");
                break;

            case 3:
                pack.instruction = 0x02;
                strcpy(instr_type, "umidade");
                break;

            case 4:
                pack.instruction = 0x03;
                strcpy(instr_type, "temperatura continua");
                
                break;

            case 5:
                pack.instruction = 0x04;
                strcpy(instr_type, "umidade continua");
                break;

            case 6:
                pack.instruction = 0x05;
                strcpy(instr_type, "parada de temperatura continua");
                break;

            case 7:
                pack.instruction = 0x06;
                strcpy(instr_type, "parada de umidade continua");
                break;

            default:
                printf("Opcao invalida!\nPor padrao sera solicitado o status do sensor!\n\n");
                pack.instruction = 0x00;
                strcpy(instr_type, "status do sensor");
                break;
        }

	// printf("Instrucao solicitada: 0x%02X\n", pack.instruction);
	sent = write(fd, &pack, sizeof(pack));
        // sent = sendData(fd, (unsigned char *)&pack);

        int i;
        
        for (i=6; i>0; i--){
            system("clear");
            printf("Solicitando %s.\n", instr_type);
            printf("Aguarde %d segundos...\n", i);
            sleep(1);
        }


        if (sent == -1){
            printf("O dado nao foi enviado corretamente!\nEnvie novamente!\n");

        } else{
            printf("Dado solicitado!\n");
        }
        
        system("clear");
    }

        close(fd);
        return 0;
}

int serialPortConfig(int fd){
        struct termios options; /* Serial ports setting */

        options.c_cflag = B9600 | CS8 | CLOCAL | CREAD;
        options.c_iflag = IGNPAR;
        options.c_oflag = 0;
        options.c_lflag = 0;

        tcflush(fd, TCIFLUSH);
        if (tcsetattr(fd, TCSANOW, &options) != 0){
                return -1;
        }
        return 0;
}
