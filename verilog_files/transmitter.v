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

module transmitter(input wire [7:0] din, // Dados a serem transmitidos
		   input wire wr_en, // Em nível 1, indica que o módulo transmitter deve começar a transmitir dados
		   input wire clk_50m, // Clock 50MHz
		   input wire clken, // Sinal de habilitação de transmissão
		   output reg tx, // Saída principal
		   output wire tx_busy // Indica se o transmissor está ocupado ou não
			);

initial begin
	 tx = 1'b1;
end

parameter STATE_IDLE	= 2'b00;
parameter STATE_START	= 2'b01;
parameter STATE_DATA	= 2'b10;
parameter STATE_STOP	= 2'b11;

reg [7:0] data = 8'h00; // Dados a serem enviados
reg [2:0] bitpos = 3'h0; // Posição do dado a ser enviado a seguir em data
reg [1:0] state = STATE_IDLE; // Estado inicial IDLE

always @(posedge clk_50m) begin
	case (state)
	STATE_IDLE: begin
		/* Permanece no estado IDLE até wr_en ser nível alto (1)*/
		if (wr_en) begin
			state <= STATE_START;
			data <= din; // Registrado data recebe os dados de din
			bitpos <= 3'h0; // Posição do vetor data é zerada
		end
	end
	STATE_START: begin
		// Envia bit 0 (bit de start) e muda para STATE_DATA
		if (clken) begin
			tx <= 1'b0;
			state <= STATE_DATA;
		end
	end
	
	STATE_DATA: begin
		/* 
		 * A cada pulso clken, incrementa o index e 
		 * envia o valor em data[index] para a saída tx
		 *
		 * Quando todos os valores tiverem sido enviados
		 * muda para o estado STOP
		 */
		if (clken) begin
			if (bitpos == 3'h7)
				state <= STATE_STOP;
			else
				bitpos <= bitpos + 3'h1;
			tx <= data[bitpos];
		end
	end
	
	STATE_STOP: begin
		/* Envia 1 para a saída e m,uda o estado para IDLE */
		if (clken) begin
			tx <= 1'b1;
			state <= STATE_IDLE;
		end
	end
	
	/* Envia 1 para a saída enquanto estiver no idle */
	default: begin
		tx <= 1'b1;
		state <= STATE_IDLE;
	end
	endcase
end

/* 
 * Enquanto o estado for diferente de IDLE
 * tx_busy = 1 
 */
assign tx_busy = (state != STATE_IDLE);

endmodule