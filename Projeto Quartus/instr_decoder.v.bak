/* 
 * Módulo decodificador de instrução responsável por enviar  
 * dados referentes ao sensoriamento continuo e parada de 
 * sensoriamento continuo com base na instrução recebida
 *
 * Além disso, envia um bit referente ao tipo de dado  
 * solicitado na instrução (umidade, temperatura e status)
 */
module instr_decoder(input [2:0] INSTR,
    output CONTINUOUS_EN, // Sinal que indica se houve instrução pra sensoriamento contínuo
    output BREAK_CONTINUOUS, // Sinal que indica se houve instrução pra parada de sensoriamento contínuo
    output [1:0] DATA_TYPE // Tipo de dado a ser enviado (umidade, status, temperatura)
    );

  localparam STATUS = 3'd0, TEMP = 3'd1, HUMID = 3'd2, TEMP_CONT = 3'd3, HUMID_CONT = 3'd4, X_TEMP_CONT = 3'd5, X_HUMID_CONT = 3'd6, IDLE = 3'd7;
  
  localparam T = 2'b01, H = 2'b10, S = 2'b11, N = 2'b00; //T = temperatura, H = umidade, S = status, N = nada.

  // Operador ternario: (condição) ? true : false
  /* 
   * Atribui nível alto ao CONTINUOUS_EN se a instrução
   * for referente a sensoriamento contínuo
   */
  assign CONTINUOUS_EN = (INSTR == TEMP_CONT || INSTR == HUMID_CONT) ? 1 : 0;
  
  /* 
   * Atribui nível alto ao BREAK_CONTINUOUS se a instrução
   * for referente a parada sensoriamento contínuo
   */
  assign BREAK_CONTINUOUS = (INSTR == X_TEMP_CONT || INSTR == X_HUMID_CONT) ? 1 : 0;


/* generate
 *   if (INSTR == STATUS) DATA_TYPE = S;
 *   else if (INSTR == TEMP || INSTR == TEMP_CONT) DATA_TYPE = T;
 *   else DATA_TYPE = H;  *endgenerate 
  */

  //assign DATA_TYPE = (INSTR == STATUS) ? S : ((INSTR == TEMP || INSTR == TEMP_CONT || INSTR == X_TEMP_CONT) ? T : H);
  assign DATA_TYPE = (INSTR == STATUS) ? S : ((INSTR == TEMP || INSTR == TEMP_CONT || INSTR == X_TEMP_CONT) ? T : (INSTR == HUMID || INSTR == HUMID_CONT || INSTR == X_HUMID_CONT) ? H : N);
  
endmodule