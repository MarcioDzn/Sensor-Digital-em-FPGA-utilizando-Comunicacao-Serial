/* 
 * ----------------------------------------------------------------------
 * Modulo responsavel por enviar sinais de enable para modulos 
 * como o DHT11, o UART e outros.
 *
 * Controla os demais modulos a fim de sincronizar corretamente
 * o recebimento, processamento e envio de dados
 * ----------------------------------------------------------------------
 */
module main_state_machine(
		clk_50m, // Clock 50MHz
		done_uart_rx, // Sinal de finalizacao de recepçao de dados pelo uart (PC -> Placa)
		done_uart_tx, // Sinal de finalizacao de envio de dados pelo uart (Placa -> PC)
		done_dht, // Sinal de finalizacao de envio de dados pelo DHT11
		//continuous_rx, // Sinal referente ao recebimento de instrucao de sensoriamento continuo 
		break_continuous, // Sinal referente a instrucao de finalizacao de sensoriamento continuo
		state, // Saida referente ao tipo de estado em que se encontra
		dht_out, // Sinal de start para o DHT11
		//clr_uart, // Clear do UART, que limpa o sinal de done_dht 
		en_request, // Sinal enviado para o modulo decodificador de instrucao
		idle,
		pack
	);
	
	input clk_50m, done_uart_rx, done_uart_tx, /*continuous_rx,*/ break_continuous;
	input done_dht;
	
	output reg[1:0] state;
	output reg /*clr_uart,*/ dht_out, en_request, idle, pack;
		
	localparam IDLE =2'b00, RECEIVE =2'b01, ORGANIZE = 2'b10, SEND =2'b11;
	
initial begin
  state <= IDLE;
  dht_out <= 0;
  en_request <= 0;
  idle <= 1;
  pack <= 0;
end	
	
/* 
 * Maquina de estados responsavel por alterar entre os estados de IDLE, RECEIVE e SEND
 *
 *	O estado inicial e IDLE, e permanece assim enquanto done_uart_rx=0
 *	
 *	Assim que os dados forem recebidos pelo `transmitter`, done_uart_rx = 1 e STATE=RECEIVE
 *	
 *	Assim que os dados forem enviados pelo DHT11, o estado muda para SEND
 *	
 *	Quando os dados forem enviados ao PC, sai de SEND  e vai para IDLE, para receber novos dados
 */
always @(posedge clk_50m) begin: FSM
	
	case(state)
	
			/* 
			 * O estado inicial e' IDLE, e permanece assim enquanto done_uart_rx=0
			 * Assim que os dados forem recebidos pelo `transmitter`, done_uart_rx = 1 e STATE=RECEIVE
			 */
			IDLE: begin
				if (done_uart_rx && !break_continuous) begin
					state <= RECEIVE; //Entra em estado de coleta
					dht_out <= 1; //Habilita módulo DHT11
					en_request <= 0;
					idle <= 0; //Desliga sinal de espera
					pack <= 0;
				end
				
				/* 
				 * Caso seja solicitado o fim do sensoriamento continuo
				 * envia direto para o SEND
				 */
				else if (done_uart_rx && break_continuous) begin
					state <= ORGANIZE; //Entra em estado de empacotamento
					dht_out <= 0;
					en_request <= 0;
					idle <= 0; //Desliga sinal de espera
					pack <= 1; //Habilita módulo packer
				end
				
				//Enquanto não recebe um done_uart_tx, permanece em IDLE
				else begin 
					state <= IDLE;
					dht_out <= 0;
					en_request <= 0;
					idle <= 1; //Sinal de espera continua ativo
					pack <= 0;
				end
				
			end
			 	 
			/*
			 *	Se mantem nesse estado ate o DHT11 terminar de enviar a decodificar os dados 
			 * Muda para o estado SEND caso done_dht=1 (dht11 termine de enviar os dados) 
			 */
			RECEIVE: begin
				if (done_dht) begin
					state <= ORGANIZE; //Entra em estado de empacotamento
					dht_out <= 0; //Desabilita módulo DHT11
					en_request <= 0;
					idle <= 0;
					pack <= 1; //Habilita módulo packer
				end  
				
				//Enquanto não recebe um done_dht, permanece em RECEIVE
				else begin
					state <= RECEIVE;
					dht_out <= 1; //Habilita o módulo DHT11
					en_request <= 0;
					idle <= 0;
					pack <= 0;
				end
			end
			
			ORGANIZE: begin
				state <= SEND; //Entra em estado de envio
				dht_out <= 0;
				en_request <= 0;
				idle <= 0;
				pack <= 0; //Desabilita módulo packer
			end
			/* 
			 * Muda para o estado IDLE apo's o transmitter terminar de enviar
			 *	os dados para o PC
			 *
			 * Envia um sinal de enable para o modulo que vai decodificar
			 * o que foi solicitado (temperatura, umidade, status, etc.)
			 */
			SEND: begin
				if (done_uart_tx) begin
					state <= IDLE; //Entra em estado de espera
					dht_out <= 0;
					en_request <= 0;
					idle <= 1; //Ativa sinal que indica espera
					pack <= 0;
				end
				
				//Enquanto não recebe um done_uart_tx permanece em SEND
				else  begin
					state <= SEND;
					dht_out <= 0;
					en_request <= 1; //Habilita módulo send_pc
					idle <= 0;
					pack <= 0;
				end	
			end
	endcase
	
end
	

endmodule