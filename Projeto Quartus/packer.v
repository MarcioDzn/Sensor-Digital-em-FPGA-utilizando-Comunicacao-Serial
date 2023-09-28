/*
 * ----------------------------------------------------------------------
 * Módulo responsável por "empacotar" os bytes de resposta e/ou de 
 * dados a serem posteriormente enviados para o computador
 * ----------------------------------------------------------------------
 */
 
module packer(input EN,
		input ERROR,
		input BREAK_CONTINUOUS,
		input [1:0] DATA_TYPE,
		input [7:0] DATA_INT,
		input [7:0] DATA_FLOAT,
		output reg [7:0] BYTE1,
		output reg [7:0] BYTE2,
		output reg [7:0] BYTE3);
		
	localparam SENSOR_ISSUE = 8'b00011111, SENSOR_OK = 8'b00000111, HUMIDITY_MEASURE = 8'b00001000, TEMPERATURE_MEASURE = 8'b00001001, DIS_TEMP_CONT = 8'b00001010, DIS_HUMI_CONT = 8'b00001011, SUPER_IDLE = 8'b11111111;
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
					if (BREAK_CONTINUOUS) begin
						BYTE1 <= DIS_TEMP_CONT;
						BYTE2 <= DIS_TEMP_CONT;
						BYTE3 <= DIS_TEMP_CONT;
					end
					else begin
						BYTE1 <= TEMPERATURE_MEASURE;
						BYTE2 <= DATA_INT;
						BYTE3 <= DATA_FLOAT;
					end
				end
				H: begin
					if (BREAK_CONTINUOUS) begin
						BYTE1 <= DIS_HUMI_CONT;
						BYTE2 <= DIS_HUMI_CONT;
						BYTE3 <= DIS_HUMI_CONT;
					end
					else begin
						BYTE1 <= HUMIDITY_MEASURE;
						BYTE2 <= DATA_INT;
						BYTE3 <= DATA_FLOAT;
					end
				end
				S: begin
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