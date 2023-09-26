/*
 * ----------------------------------------------------------------------------
 * Título: uart
 * Fonte: @jamieiles no GitHub
 * Repositório: https://github.com/jamieiles/uart/tree/master
 * 
 * Trecho de código copiado e utilizado neste projeto para realizar 
 * comunicação serial entre dois dispositivos a partir do protocolo UART.
 *
 * Modificações realizadas por: @avcsilva, @BaptistaGabriel, @LuisBaiano, @MarcioDzn no GitHub
 * Data das modificações: 28-08-2023
 * ----------------------------------------------------------------------------
 */

module receiver(input wire rx, // Dados recebidos
		output reg rdy, // Indica quando os dados estão prontos para serem lidos
		input wire rdy_clr, // Permite zerar o rdy
		input wire clk_50m, // Clock 50MHz
		input wire clken, // Sinal advindo do baud_rate_gen (habilita ou desabilita a operação do módulo)
		output reg [7:0] data); // Trnsporta os dados recebidos após terem sido processados

initial begin
	rdy = 0;
	data = 8'b0;
end

parameter RX_STATE_START	= 2'b00;
parameter RX_STATE_DATA		= 2'b01;
parameter RX_STATE_STOP		= 2'b10;

reg [1:0] state = RX_STATE_START; // Estado inicial é START
reg [3:0] sample = 0; // Contador de amostras
reg [3:0] bitpos = 0; // Posição do bit atual
reg [7:0] scratch = 8'b0; // Armazena os dados recebidos

always @(posedge clk_50m) begin

	/* 
	 * Se rdy_clr (clear) = 1, então zera o sinal de rdy 
	 */
	if (rdy_clr)
		rdy <= 0;

	/* Só há execução se clken estiver habilitado */
	if (clken) begin
		case (state)
		
		RX_STATE_START: begin
			/*
			* Start counting from the first low sample, once we've
			* sampled a full bit, start collecting data bits.
			*/
			
			/* 
			 * Enquanto o sinal for baixo (0) OU a contagem 
			 * já tiver sido iniciada, continua contando.
			 * 
			 */
			if (!rx || sample != 0)
				sample <= sample + 4'b1;
			
			/* Caso sample == 15, prepara para receber os dados */
			if (sample == 15) begin
				state <= RX_STATE_DATA; // Muda para o estado DATA
				bitpos <= 0; // Zera a posição dos bits    
				sample <= 0; // Zera a contagem 
				scratch <= 0; // Zera a informação guardada     
			end
		end
		
		
		RX_STATE_DATA: begin
			sample <= sample + 4'b1; // Conta de 1 em 1
			
			/* Bit recebido é aramazenado no vetor scratch e o index bitpos é incrementado*/
			if (sample == 4'h8) begin 
				scratch[bitpos[2:0]] <= rx; 
				bitpos <= bitpos + 4'b1;
			end
			
			/* Se todos os dados ja tiverem sido aramazenados
			 * vai para o estado STOP
			 */
			if (bitpos == 8 && sample == 15)
				state <= RX_STATE_STOP;
		end
		
		RX_STATE_STOP: begin
			/*
			 * Our baud clock may not be running at exactly the
			 * same rate as the transmitter.  If we thing that
			 * we're at least half way into the stop bit, allow
			 * transition into handling the next start bit.
			 */
			if (sample == 15 || (sample >= 8 && !rx)) begin
				state <= RX_STATE_START; // estado volta para START
				data <= scratch; // dados são passados para a saída data
				rdy <= 1'b1; // rdy = 1 indica fim da transmissão de dados
				sample <= 0; // contador é zerado
			end else begin
				sample <= sample + 4'b1;
			end
		end
		default: begin
			state <= RX_STATE_START;
		end
		endcase
	end
end

endmodule