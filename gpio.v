module gpio(
	input rst,
	input clk,
	output reg readssr_req,
	output reg byte_received_ack,
	input byte_ready,
	input [7:0] byte_in,
	input start,
	output[7:0] LED
);

reg clk24 = 0;
reg clk12 = 0;
reg clk6 = 0;

always @(posedge clk) begin
	clk24 <= ~clk24;
end

always @(posedge clk24) begin
	clk12 <= ~clk12;
end

always @(posedge clk12) begin
	clk6 <= ~clk6;
end

integer index = 0;

integer state = 0;

parameter IDLE = 0;
parameter REQ_READSSR = 1;
parameter READ_BYTE = 2;
parameter ACK_BYTE_RECEIVED = 3;
parameter INCREMENT_INDEX = 4;
parameter STOP = 5;

reg[7:0] buffer[0:39];

always @(posedge clk12) begin
	if(!rst) begin
		state <= IDLE;
	end
	else begin
		case(state)
			IDLE: begin
				index <= 0;
				readssr_req <= 1'b0;
				byte_received_ack <= 1'b0;
				if(!start) begin 
					state <= REQ_READSSR;
				end
			end
			
			REQ_READSSR: begin
				readssr_req <= 1'b1;
				if(byte_ready) begin
					state <= READ_BYTE;
				end
			end
			
			READ_BYTE: begin
				//a byte is read here
				buffer[index] <= byte_in;
				state <= ACK_BYTE_RECEIVED;
			end
			
			ACK_BYTE_RECEIVED: begin
				byte_received_ack <= 1'b1;
				// ack and wait for deassertion
				if(!byte_ready) begin
					byte_received_ack <= 1'b0;
					state <= INCREMENT_INDEX;
				end
			end
			
			INCREMENT_INDEX: begin
				byte_received_ack <= 1'b0;
				index <= index + 1;
				if(index == 39) begin //40 bytes
					state <= STOP;
				end else begin
					state <= REQ_READSSR;
				end
			end
			
			STOP: begin
				index <= 0;
				readssr_req <= 1'b0;
			end
			
			default: begin
				//do nothing
			end
			
		endcase
	end
end

assign LED = buffer[8];

endmodule