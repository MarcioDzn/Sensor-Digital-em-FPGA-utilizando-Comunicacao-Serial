/*
 * ----------------------------------------------------------------------
 * Módulo responsável por filtrar os dados solicitados advindos 
 * do DHT11 em valor Inteiro e fracionário
 * ----------------------------------------------------------------------
 */

module data_selector(
  input [1:0] DATA_TYPE, // Tipo de dado
  input [7:0] TEMP_INT, // Temperatura (porção inteira)
  input [7:0] TEMP_FLOAT, // Temperatura (porção fracionária)
  input [7:0] HUMI_INT, // Umidade (porção inteira)
  input [7:0] HUMI_FLOAT, // Umidade (porção fracionária)
  output [7:0] DATA_INT, // Dado (inteiro) selecionado
  output [7:0] DATA_FLOAT // Dado (fracionário) selecionado
);

  localparam T = 2'b01, H = 2'b10, S = 2'b11;

  assign DATA_INT = (DATA_TYPE == T) ? TEMP_INT : HUMI_INT;
  assign DATA_FLOAT = (DATA_TYPE == T) ? TEMP_FLOAT : HUMI_FLOAT;


endmodule