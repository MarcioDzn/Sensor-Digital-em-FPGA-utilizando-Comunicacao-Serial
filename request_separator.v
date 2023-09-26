/*
 * ----------------------------------------------------------------------
 * Módulo responsável por separar os dados recebidos do COMPUTADOR
 * em 1 byte de CÓDIGO DE INSTRUÇÃO e 1 byte de ENDEREÇO DO SENSOR
 *
 * Quando concluida a separação, envia como saída um sinal de DONE
 * ----------------------------------------------------------------------
 */
 
module request_separator( 
	input IDLE, // Indica se a main_state_machine está em IDLE
	input EN, // Sinal de enable do rx do UART
	input [7:0] DATA, // Dados advindos do módulo UART
   input CONTINUOUS_EN, // Enable referente à solicitação continua
	output [2:0] INSTR, // Dados de instrução
	output [4:0] ADDR, // Endereço
	output reg DONE_OUT // Sinal que indica a finalização da separação de dados
 );
		
	reg[2:0] INSTR_REG = 0; //3 bits = suficiente para 7 possibilidades de instrução
	reg[4:0] ADDR_REG = 0; //5 bits = suficiente para 32 possibilidades de endereços

	reg counter = 0; // 
	reg DONE = 0;
	
	/* 
	 *	A cada borda de subida do EN (enable), atribui o dado recebido pelo receiver 
	 * ao respectivo registrador 
	 *	
	 *	Na primeira borda de subida recebe o dado da instrução
	 *	e na segunda borda recebe o dado do endereço do sensor
	 */
  always @(posedge EN) begin
		
			if (counter == 1'b0) begin
				INSTR_REG <= DATA[2:0];
				DONE <= 0;
				counter = counter + 1'b1;
			end	

		 /* Se entrou aqui significa que os dois bytes foram recebidos e separados*/
			else begin
				ADDR_REG <= DATA[4:0];
				DONE <= 1; // Indica que os dados foram separados corretamente
				counter = 0;
			end
			
	end


  /*
	* Always que só funciona sobre uma borda de subida de DONE (significando que foram recebidos 2
	* bytes do PC) ou uma borda de descida de IDLE (significando que a MEF saiu do estado de IDLE)
	*
	* (MEF = Máquina de Estados Finita [main_state_machine.v])
	*
	* Verifica se CONTINUOUS_EN (sinal que indica se a instrução
   * é referente a sensoriamento continuo) está em nível alto.
   * Se sim, mantém o DONE em 1 para nova solicitação de dados
	*/
  always @(posedge DONE, negedge IDLE) begin
    if (!IDLE) begin //Caso a MEF não esteja em IDLE (ou tenha saído de IDLE, vide "negedge IDLE")
		if (CONTINUOUS_EN) begin //Se for um pedido de contínuo, DONE_OUT permanece
			DONE_OUT <= DONE_OUT;
		end
		else begin //Se não for um pedido de contínuo, DONE_OUT torna 0
			DONE_OUT <= 0;
		end
    end
    else begin //Caso a MEF esteja em IDLE
		DONE_OUT <= 1; //Torna 1 para permitir mudança de estado na MEF
    end
  end
	
	/* Envia os dados dos registradores para as respectivas saídas */
	assign INSTR = INSTR_REG;
	assign ADDR = ADDR_REG;

endmodule