/*
* Módulo responsável por organizar os bytes a serem enviados pelo send_pc
*/
module packer(input EN, //Sinal de "pack" vindo da main_state_machine
		input ERROR, //Sinal de erro do DHT11
		input BREAK_CONTINUOUS, //Sinal de quebra de contínup
		input [1:0] DATA_TYPE, //Tipo de dado requerido
		input [7:0] DATA_INT, //Dado filtrado pelo data_selector
		input [7:0] DATA_FLOAT, //Dado filtrado pelo data_selector
		output reg [7:0] BYTE1,
		output reg [7:0] BYTE2, 
		output reg [7:0] BYTE3);

	//Códigos de resposta possíveis
	localparam SENSOR_ISSUE = 8'b00011111, SENSOR_OK = 8'b00000111, HUMIDITY_MEASURE = 8'b00001000, TEMPERATURE_MEASURE = 8'b00001001, DIS_TEMP_CONT = 8'b00001010, DIS_HUMI_CONT = 8'b00001011, SUPER_IDLE = 8'b11111111;
	
	//Possíveis tipos de dados
	localparam T = 2'b01, H = 2'b10, S = 2'b11;
	
	always @(posedge EN) begin
		/*
		* Respostas se tornam código de erro caso:
		* - Seja emitido um sinal de erro pelo módulo DHT11
		* - Caso se queira temperatura e esta se mostre igual a 0 ou acima de 50 (limites do DHT11)
		* - Caso se queira umidade e esta se mostre abaixo de 20 ou acima de 90 (limites do DHT11)
		*/
		if (ERROR || (DATA_TYPE == T && (DATA_INT == 8'd0 || DATA_INT > 8'd50)) || (DATA_TYPE == H && (DATA_INT < 8'd20 || DATA_INT > 8'd90))) begin
			BYTE1 <= SENSOR_ISSUE;
			BYTE2 <= SENSOR_ISSUE;
			BYTE3 <= SENSOR_ISSUE;
		end
		
		/*
		* Caso não haja nenhum erro
		*/
		else begin
			case (DATA_TYPE)
				T: begin
					if (BREAK_CONTINUOUS) begin //Caso de quebra, resposta será apenas código de resposta
						BYTE1 <= DIS_TEMP_CONT;
						BYTE2 <= DIS_TEMP_CONT;
						BYTE3 <= DIS_TEMP_CONT;
					end
					else begin //Caso não seja quebra de contínuo, ou seja, requisição normal de medidas
						BYTE1 <= TEMPERATURE_MEASURE;
						BYTE2 <= DATA_INT;
						BYTE3 <= DATA_FLOAT;
					end
				end
				H: begin
					if (BREAK_CONTINUOUS) begin //Caso de quebra, resposta será apenas código de resposta
						BYTE1 <= DIS_HUMI_CONT;
						BYTE2 <= DIS_HUMI_CONT;
						BYTE3 <= DIS_HUMI_CONT;
					end
					else begin //Caso não seja quebra de contínuo, ou seja, requisição normal de medidas
						BYTE1 <= HUMIDITY_MEASURE;
						BYTE2 <= DATA_INT;
						BYTE3 <= DATA_FLOAT;
					end
				end
				S: begin //Caso se peça status e não tenha havido erro
					BYTE1 <= SENSOR_OK;
					BYTE2 <= SENSOR_OK;
					BYTE3 <= SENSOR_OK;
				end
				default : begin //DATA_TYPE também pode ser N = nada. Pra isso a saída será SUPER_IDLE.
					BYTE1 <= SUPER_IDLE;
					BYTE2 <= SUPER_IDLE;
					BYTE3 <= SUPER_IDLE;
				end
			endcase
		end
	end


endmodule