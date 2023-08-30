/*
 * ----------------------------------------------------------------------------
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
 * ----------------------------------------------------------------------------
 */

module uart(input wire [7:0] din,
	    input wire wr_en,
	    input wire clk_50m,
	    output wire tx,
	    output wire tx_busy,
	    input wire rx,
	    output wire rdy,
	    input wire rdy_clr,
	    output wire [7:0] dout
		 );

wire rxclk_en, txclk_en;


baud_rate_gen uart_baud(.clk_50m(clk_50m),
			.rxclk_en(rxclk_en),
			.txclk_en(txclk_en));
			
transmitter uart_tx(.din(din),
		    .wr_en(wr_en),
		    .clk_50m(clk_50m),
		    .clken(txclk_en),
		    .tx(tx),
		    .tx_busy(tx_busy));
			 
receiver uart_rx(.rx(rx),
		 .rdy(rdy),
		 .rdy_clr(rdy_clr),
		 .clk_50m(clk_50m),
		 .clken(rxclk_en),
		 .data(dout));

endmodule
