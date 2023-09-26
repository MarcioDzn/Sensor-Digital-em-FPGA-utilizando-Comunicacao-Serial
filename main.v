module main(input clk,
    input pc_in,
    inout dht,
    output pc_out /*,
	 output [1:0] state,
	 output [7:0] ebyte1,
	 output [7:0] ebyte2 */
);

	wire [7:0] data_send, data_in, /*instr,*/ t_int, t_float, h_int, h_float, d_int, d_float, byte1, byte2, byte3;
	wire [2:0] instr; //Necessita apenas de 3 bits para representar todas requisições possíveis.
	wire [1:0] data_type;
	wire en_tx, busy_tx, rx_en, done_sep, en_send, done_send, en_dht, done_dht, error_dht, en_pack;
	wire break_cont, continuous, idle_fsm;

	/*
	assign ebyte1 = byte1;//byte1;
	assign ebyte2 = byte2; // 01000101
	*/
	
  uart UART(.din(data_send),
    .wr_en(en_tx),
    .clk_50m(clk),
    .tx(pc_out),
    .tx_busy(busy_tx),
    .rx(pc_in),
    .rdy(rx_en),
    .rdy_clr(),
    .dout(data_in)
  );
  
  DHT11 SENSOR(
    .clk_50mhz(clk),
    .start(1),
    .rst_n(en_dht),
    .dat_io(dht),
    //.data(),
	 .HUM_INT(h_int),
	 .HUM_FLOAT(h_float),
	 .TEMP_INT(t_int),
	 .TEMP_FLOAT(t_float),
    .error(error_dht),
    .done(done_dht)
  );
  
  // funcionando
  instr_decoder DECODIFICADOR(.INSTR(instr),
   .CONTINUOUS_EN(continuous),
   .BREAK_CONTINUOUS(break_cont),
   .DATA_TYPE(data_type) 
  );
  
  request_separator SEPARADOR(.IDLE(idle_fsm),
    .EN(rx_en),
    .DATA(data_in),
    .CONTINUOUS_EN(continuous),
    .INSTR(instr),
    .ADDR(), 
    .DONE_OUT(done_sep)
  );
  
  main_state_machine MAQUINA_ESTADOS(
    .clk_50m(clk), 
    .done_uart_rx(done_sep), 
    .done_uart_tx(done_send), 
    .done_dht(done_dht), 
    .break_continuous(break_cont),
    .state(state),
    .dht_out(en_dht),
    .en_request(en_send),
	 .idle(idle_fsm),
	 .pack(en_pack)
  );
  
  
  data_selector SELETOR(
  .DATA_TYPE(data_type),
  .TEMP_INT(t_int), 
  .TEMP_FLOAT(t_float), 
  .HUMI_INT(h_int), 
  .HUMI_FLOAT(h_float),
  .DATA_INT(d_int), 
  .DATA_FLOAT(d_float) 
);

	
	// Funciona
  packer ORGANIZADOR(.EN(en_pack),
	.ERROR(error_dht),
	.BREAK_CONTINUOUS(break_cont),
	.DATA_TYPE(data_type),
	.DATA_INT(d_int),
	.DATA_FLOAT(d_float),
	.BYTE1(byte1),
	.BYTE2(byte2),
	.BYTE3(byte3)
);
  
  send_pc ENVIA_PC( 
    .clk(clk),
    .EN(en_send),
	 .BYTE1(byte1),
    .BYTE2(byte2),
    .BYTE3(byte3),
    .BUSY_TX(busy_tx),
    .EN_TX(en_tx),
    .DONE(done_send),
    .RESPONSE_DATA(data_send)
  );
  
endmodule