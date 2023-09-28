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
 * Hacky baud rate generator to divide a 50MHz clock into a 9600 baud
 * rx/tx pair where the rx clcken oversamples by 16x.
 */
module baud_rate_gen(input wire clk_50m,
		     output wire rxclk_en,
		     output wire txclk_en);

parameter RX_ACC_MAX = 50000000 / (9600 * 16);
parameter TX_ACC_MAX = 50000000 / 9600;
parameter RX_ACC_WIDTH = $clog2(RX_ACC_MAX);
parameter TX_ACC_WIDTH = $clog2(TX_ACC_MAX);
reg [RX_ACC_WIDTH - 1:0] rx_acc = 0;
reg [TX_ACC_WIDTH - 1:0] tx_acc = 0;

assign rxclk_en = (rx_acc == 5'd0);
assign txclk_en = (tx_acc == 9'd0);

always @(posedge clk_50m) begin
	if (rx_acc == RX_ACC_MAX[RX_ACC_WIDTH - 1:0])
		rx_acc <= 0;
	else
		rx_acc <= rx_acc + 5'b1;
end

always @(posedge clk_50m) begin
	if (tx_acc == TX_ACC_MAX[TX_ACC_WIDTH - 1:0])
		tx_acc <= 0;
	else
		tx_acc <= tx_acc + 9'b1;
end

endmodule