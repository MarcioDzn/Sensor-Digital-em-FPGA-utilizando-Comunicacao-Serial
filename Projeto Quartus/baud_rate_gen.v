/*
 * --------------------------------------------------------------------------------------------
 * Título: uart
 * Fonte: @jamieiles no GitHub
 * Repositório: https://github.com/jamieiles/uart/tree/master
 * 
 * Trecho de código copiado e utilizado neste projeto para realizar 
 * comunicação serial entre dois dispositivos a partir do protocolo UART.
 
 * Modificações foram realizadas para adaptar o baud rate aos propósitos do 
 * projeto no qual este módulo será utilizado.
 
 * Modificações realizadas por: @avcsilva, @BaptistaGabriel, @LuisBaiano, @MarcioDzn no GitHub
 * Data das modificações: 28-08-2023
 * --------------------------------------------------------------------------------------------
 */


/*
 * Gerador de taxa de transmissão para dividir um clock de 50 MHz em um clock de 9600 baud
 * par rx/tx onde o rx clcken superamostra em 16x
 */
module baud_rate_gen(input wire clk_50m,
		     output wire rxclk_en,
		     output wire txclk_en);

/* 
 * Divisor de baud rate para uma frequência de 50MHz
 * e uma taxa de 9600bps
 */			  
parameter RX_ACC_MAX = 50000000 / (9600 * 16); // Oversampling, a fim de obter amostras mais precisas
parameter TX_ACC_MAX = 50000000 / 9600;

/* 
 * Número de bits necessários para representar os 
 *	valores máximos de RX_ACC_MAX e TX_ACC_MAX, respectivamente
 */
parameter RX_ACC_WIDTH = $clog2(RX_ACC_MAX); // Número de bits necessários para representar o valor máx de RX_ACC_MAX
parameter TX_ACC_WIDTH = $clog2(TX_ACC_MAX); // Número de bits necessários para representar o valor máx de TX_ACC_MAX

/* 
 * Declaração de registradores rx_acc e tx_acc
 * com largura iguais a RX_ACC_MAX e TX_ACC_MAX, respectivamente
 */
reg [RX_ACC_WIDTH - 1:0] rx_acc = 0;
reg [TX_ACC_WIDTH - 1:0] tx_acc = 0;

/* 
 * Clocks de transmissão e recepção devem ser habilitados
 * quando rx_acc e tx_acc forem iguais a 0
 */
assign rxclk_en = (rx_acc == 5'd0);
assign txclk_en = (tx_acc == 9'd0);

/* Verifica se rx_acc é igual ao valor máximo encontrado em RX_ACC_MAX 
 * Se sim, zera rx_acc e reinicia a contagem
 *
 * Vale lembrar que sempre que rx_acc = 0, rx_clk_en = 1
 */
always @(posedge clk_50m) begin
	if (rx_acc == RX_ACC_MAX[RX_ACC_WIDTH - 1:0])
		rx_acc <= 0;
	else
		rx_acc <= rx_acc + 5'b1;
end

/* Verifica se tx_acc é igual ao valor máximo encontrado em RX_ACC_MAX 
 * Se sim, zera tx_acc e reinicia a contagem
 *
 * Vale lembrar que sempre que tx_acc = 0, tx_clk_en = 1
 */
always @(posedge clk_50m) begin
	if (tx_acc == TX_ACC_MAX[TX_ACC_WIDTH - 1:0])
		tx_acc <= 0;
	else
		tx_acc <= tx_acc + 9'b1;
end

endmodule