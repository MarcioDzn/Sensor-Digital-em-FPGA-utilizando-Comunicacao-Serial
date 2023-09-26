/*
* Módulo responsável por entregar ao transmitter os bytes de resposta em ordem
*/
module send_pc( 
	input clk,
  	input EN, // Enable advindo da máquina de estados principal (en_request)
	input [7:0] BYTE1, //Comando de resposta
  	input [7:0] BYTE2, // Dados solicitados (porção inteira)
  	input [7:0] BYTE3, // Dados solicitados (porção fracionária)
  	input BUSY_TX, // Sinal de ocupado advindo do transmitter
  	output reg EN_TX, //Sinal de habilitação do transmitter
  	output reg DONE, //Sinal de finalização de envio
  	output reg [7:0] RESPONSE_DATA //Dado a ser enviado
  	);
  
	reg [2:0] count; //Contador para identificação de byte
	
	initial begin
		count <= 3'b000;
		RESPONSE_DATA <= 8'b11111111;
		DONE <= 0;
		EN_TX <= 0;
	end
	
	always @(posedge clk) begin: FSM
		if (EN) begin //Caso esteja habilitado a funcionar
			if (BUSY_TX) begin //Caso o transmitter esteja ocupado em uma transmissão
				RESPONSE_DATA <= RESPONSE_DATA;
				EN_TX <= 0; //Desabilita transmitter para não haver confusão de dados
				DONE <= 0;
				count <= count; //Contagem se mantem parada
			end
			else begin
				case (count) 
					3'b000: begin //1º byte
						RESPONSE_DATA <= BYTE1;
						EN_TX <= 1; //Habilita transmitter
						DONE <= 0;
					end
					3'b010: begin //2º byte
						RESPONSE_DATA <= BYTE1;
						EN_TX <= 1; //Habilita transmitter
						DONE <= 0;
					end
					
					3'b100: begin //3º byte
						RESPONSE_DATA <= BYTE2;
						EN_TX <= 1; //Habilita transmitter
						DONE <= 0;
					end
					3'b110: begin //4º byte
						RESPONSE_DATA <= BYTE3;
						EN_TX <= 1; //Habilita transmitter
						DONE <= 0;
					end
					3'b111: begin //Finalização do processo
						RESPONSE_DATA <= RESPONSE_DATA;
						EN_TX <= 0; //Desabilita transmitter
						DONE <= 1; //Indica finalização
					end
				endcase
				
				count <= count + 1'b1; //Avança a contagem

			end
		end
		else begin //Caso não esteja habilitado a funcionar
			RESPONSE_DATA <= RESPONSE_DATA;
			EN_TX <= 0; //Mantém transmitter desligado
			DONE <= 0; //Mantém finalização desligada
			count <= 3'b000; //Mantém contagem zerada
		end
	end

	
endmodule