module send_pc( 
	input clk,
  	input EN, // Enable advindo da máquina de estados principal
	input [7:0] BYTE1,
  	input [7:0] BYTE2, // Dados solicitados (porção inteira)
  	input [7:0] BYTE3, // Dados solicitados (porção fracionária)
  	input BUSY_TX, // Sinal de ocupado advindo do transmitter
  	output reg EN_TX,
  	output reg DONE,
  	output reg [7:0] RESPONSE_DATA
  	);
  
	reg [2:0] count;
	
	initial begin
		count <= 3'b000;
		RESPONSE_DATA <= 8'b11111111;
		DONE <= 0;
		EN_TX <= 0;
	end
	
	always @(posedge clk) begin: FSM
		if (EN) begin
			if (BUSY_TX) begin
				RESPONSE_DATA <= RESPONSE_DATA;
				EN_TX <= 0;
				DONE <= 0;
				count <= count;
			end
			else begin
				case (count) 
					3'b000: begin 
						RESPONSE_DATA <= BYTE1;
						EN_TX <= 1;
						DONE <= 0;
					end
					3'b010: begin
						RESPONSE_DATA <= BYTE1;
						EN_TX <= 1;
						DONE <= 0;
					end
					
					3'b100: begin
						RESPONSE_DATA <= BYTE2;
						EN_TX <= 1;
						DONE <= 0;
					end
					3'b110: begin
						RESPONSE_DATA <= BYTE3;
						EN_TX <= 1;
						DONE <= 0;
					end
					3'b111: begin
						RESPONSE_DATA <= RESPONSE_DATA;
						EN_TX <= 0;
						DONE <= 1;
					end
				endcase
				
				count <= count + 1'b1;

			end
		end
		else begin
			RESPONSE_DATA <= RESPONSE_DATA;
			EN_TX <= 0;
			DONE <= 0;
			count <= 3'b000;
		end
	end

	
endmodule