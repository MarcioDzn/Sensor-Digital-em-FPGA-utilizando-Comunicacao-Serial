/*
 * ----------------------------------------------------------------------------
 * Título: DHT11
 * Fonte: https://www.kancloud.cn/dlover/fpga/1637659
 
 * Trecho de código copiado e utilizado neste projeto para receber 
 * e decodificar dados do sensor DHT11.
 
 * Modificações foram realizadas para melhor identificação e tratamento 
 * de casos de erro e adaptação ao contexto do projeto.
 
 * Modificações realizadas por: @avcsilva, @BaptistaGabriel, @LuisBaiano, @MarcioDzn no GitHub
 * Data das modificações: 28-08-2023
 * ----------------------------------------------------------------------------
 */

module DHT11(
	input wire clk_50mhz,
	input wire start,
	input wire rst_n,
	inout dat_io,
	output [7:0] HUM_INT,
	output [7:0] HUM_FLOAT,
	output [7:0] TEMP_INT,
	output [7:0] TEMP_FLOAT,
	output error, 
	output done 
);

	wire din;
	reg read_flag;
	reg dout;
	reg[3:0] state;
	localparam s1 = 0;
	localparam s2 = 1;
	localparam s3 = 2;
	localparam s4 = 3;
	localparam s5 = 4;
	localparam s6 = 5;
	localparam s7 = 6;
	localparam s8 = 7;
	localparam s9 = 8;
	localparam s10 = 9;
	localparam STOP = 10;
	
	assign dat_io = read_flag ? 1'bz : dout;
	assign din = dat_io;
	assign done =  done_reg; 
	assign error = error_reg; 
	reg [5:0]data_cnt, count_50;
	reg [22:0] count_5_sec;
	reg start_f1, start_f2, start_rising, clk_1mhz, error_reg, done_reg;
	reg [39:0] data;
	
	/* Atribuição dos dados recebidos ao respectivo registrador */
	assign TEMP_INT[0] = data[16];
	assign TEMP_INT[1] = data[17];
	assign TEMP_INT[2] = data[18];
	assign TEMP_INT[3] = data[19];
	assign TEMP_INT[4] = data[20];
	assign TEMP_INT[5] = data[21];
	assign TEMP_INT[6] = data[22];
	assign TEMP_INT[7] = data[23];
	
	assign TEMP_FLOAT[0] = data[8];
	assign TEMP_FLOAT[1] = data[9];
	assign TEMP_FLOAT[2] = data[10];
	assign TEMP_FLOAT[3] = data[11];
	assign TEMP_FLOAT[4] = data[12];
	assign TEMP_FLOAT[5] = data[13];
	assign TEMP_FLOAT[6] = data[14];
	assign TEMP_FLOAT[7] = data[15];
	
	assign HUM_INT[0] = data[32];
	assign HUM_INT[1] = data[33];
	assign HUM_INT[2] = data[34];
	assign HUM_INT[3] = data[35];
	assign HUM_INT[4] = data[36];
	assign HUM_INT[5] = data[37];
	assign HUM_INT[6] = data[38];
	assign HUM_INT[7] = data[39];
	
	assign HUM_FLOAT[0] = data[24];
	assign HUM_FLOAT[1] = data[25];
	assign HUM_FLOAT[2] = data[26];
	assign HUM_FLOAT[3] = data[27];
	assign HUM_FLOAT[4] = data[28];
	assign HUM_FLOAT[5] = data[29];
	assign HUM_FLOAT[6] = data[30];
	assign HUM_FLOAT[7] = data[31];

	
	/* Divisor de clock de 50MHz pra 1MHz */
	always @(posedge clk_50mhz) begin
		if (count_50 == 6'd50) begin 
			clk_1mhz <= 1'b1;
			count_50 <= 6'd0;
			
		end else begin
			clk_1mhz <= 1'b0;
			count_50 <= count_50 + 1;
		end
	end
  
	/* Buffer pra armazenar o valor de start */
	always @(posedge clk_1mhz, negedge rst_n) begin
		if(!rst_n)begin
			start_f1 <=1'b0;
			start_f2 <= 1'b0;
			start_rising<= 1'b0;
		end
		else begin
			start_f1 <= start;
			start_f2 <= start_f1;
			start_rising <= start_f1 & (~start_f2);
		end
	end
  
  
	reg [39:0] data_buf;
	reg [15:0] cnt;
  
  
	always @(posedge clk_1mhz or negedge rst_n) begin
		/* Seta os registradores com seus valores padrão */
		if(rst_n == 1'b0) begin
			error_reg <= error_reg;
			done_reg <= 1'b0;
			read_flag <= 1'b1;
			state <= s1;
			dout <= 1'b1;
			data_buf <= 40'd0;
			cnt <= 16'd0;
			data_cnt <= 6'd0;
			data<= data;
		end
		else begin
			case(state)
				s1:begin // Preparando pra enviar nível baixo para o DHT11
						if(start_rising && din==1'b1)begin
							state <= s2;
							read_flag <= 1'b0; // PC -> DHT11
							dout <= 1'b0; // Valor enviado para o DHT11 = 0
							cnt <= 16'd0;
							data_cnt <= 6'd0;
							data <= 40'd0;
						end
						else begin
							read_flag <= 1'b1; // DHT11 -> PC
							dout<=1'b1;
							cnt<=16'd0;
						end	
					end
				s2:begin
						/* Conta 19ms enviando nível baixo */
						if(cnt >= 16'd19000)begin
							state <= s3;
							dout <= 1'b1;
							cnt <= 16'd0;
						end
						else begin
							cnt<= cnt + 1'b1;
						end
					end
				s3:begin
						/* Conta 20us em nível alto */
						if(cnt >= 16'd20)begin
							cnt<=16'd0;
							read_flag <= 1'b1; // Muda a direção do barramento pra DHT11 -> PC
							state <= s4;
						end
						else begin
							cnt <= cnt + 1'b1;
						end
					end
				s4:begin // Preparando pra a resposta do DHT11
						if(din == 1'b0)begin
							state<= s5;
							cnt <= 16'd0;
						end
						else begin
							/* Se din ficar em nível alto por mais tempo que o necessário dá erro */
							cnt <= cnt + 1'b1;
							if(cnt >= 16'd65500)begin
								state <= STOP;
								cnt<=16'd0; 
								read_flag <= 1'b1;
								error_reg <= 1'b1;
							end	
						end
					end
				s5:begin // Espera 80us de resposta do DHT11 em nível baixo
						if(din==1'b1)begin
							state <= s6;
							cnt<=16'd0;
							data_cnt <= 6'd0;
						end
						else begin
							/* Se din ficar em nível baixo por mais tempo que o necessário dá erro */
							cnt <= cnt + 1'b1;
							if(cnt >= 16'd65500)begin
								state <= STOP;
								cnt<=16'd0;
								read_flag <= 1'b1;
								error_reg <= 1'b1;
							end								
						end
					end
				s6:begin // Espera 80us de resposta do DHT11 em nível alto
						if(din == 1'b0)begin
							state <= s7;
							cnt <= cnt + 1'b1;
						end
						else begin
						/* Se din ficar em nível alto por mais tempo que o necessário dá erro */
							cnt <= cnt + 1'b1;
							if(cnt >= 16'd65500)begin
								state <= STOP;
								cnt<=16'd0;
								read_flag <= 1'b1;
								error_reg <= 1'b1;
							end							
						end
					end
				s7:begin // Inicio da transmissão de dados
						if(din == 1'b1)begin
							state <= s8;
							cnt <= 16'd0;
						end
						else begin
							/* Se din ficar em nível baixo por mais tempo que o necessário dá erro */
							cnt <= cnt + 1'b1;
							if(cnt >= 16'd65500)begin
								state <= STOP;
								cnt<=16'd0;
								read_flag <= 1'b1;
								error_reg <= 1'b1;
							end							
						end
					end
				s8:begin
						if(din == 1'b0)begin
							data_cnt <= data_cnt + 1'b1;
							
							/* 
							 * Enquanto todos os bits de dados não tiverem sido enviados
							 * volta pra s7 pra receber um bit de dado novamente
							 */
							state <= (data_cnt >= 6'd39)? s9:s7;
							cnt<=16'd0;
							
							/* A depender do tempo em nível alto, atribui 0 ou 1 */
							if(cnt >= 16'd60)begin
								data_buf<={data_buf[39:0],1'b1}; // Deslocamento
							end
							else begin
								data_buf<={data_buf[39:0],1'b0};
							end
						end
						else begin
						
							/* 
							 * Conta o tempo que ficou em nível alto para
							 * posteriormente decidir se o dado representa 1 ou 0
							 */
							cnt <= cnt + 1'b1;
							if(cnt >= 16'd65500)begin
								state <= STOP;
								cnt<=16'd0;
								read_flag <= 1'b1;
								error_reg <= 1'b1;
							end	
						end
					end
				s9:begin
						/* Guarda em data os dados recebidos pelo DHT11 */
						data <= data_buf;
						if(din == 1'b1)begin
							state <= s10;
							cnt<=16'd0;
						end
						else begin
							cnt <= cnt + 1'b1;
							if(cnt >= 16'd65500)begin
								state <= STOP;
								cnt<=16'd0;
								read_flag <= 1'b1;
								error_reg <= 1'b1;
							end	
						end
				end
					
				s10:begin
						state <= STOP; 
						cnt <= 16'd0;
						error_reg <= 1'b0;
				end
					
				STOP: begin
				   /* Conta 5 segundos de cooldown para evitar erros */
					if (count_5_sec == 23'd5000000) begin
						count_5_sec <= 23'd0;
						state <= s1; // Volta pra o estado s1
						done_reg <= 1'b1;
					
					end else begin
						count_5_sec <= count_5_sec + 1;
						state <= STOP; 
						done_reg <= 1'b0;
					end
				end
				
				default:begin
					state <= s1;
					cnt <= 16'd0;
					error_reg <= 1'b0;
					done_reg <= 1'b1;
				end	
			endcase
		end		
	end

  
	
endmodule 