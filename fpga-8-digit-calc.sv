`default_nettype none
// Empty top module

module top (
  // I/O ports
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);

  // Your code goes here...
  logic [4:0] keycode;
  logic strobe;
  scankey sk1 (.clk(hz100), .rst(reset), .in(pb[19:0]), .strobe(strobe), .out(keycode));
  logic [31:0] data;
  digits d1 (.in(keycode), .out(data), .clk(strobe), .reset(reset));
  ssdec s0(.in(data[3:0]),   .out(ss0[6:0]), .enable(1'b1));
  ssdec s1(.in(data[7:4]),   .out(ss1[6:0]), .enable(|data[31:4]));
  ssdec s2(.in(data[11:8]),  .out(ss2[6:0]), .enable(|data[31:8]));
  ssdec s3(.in(data[15:12]), .out(ss3[6:0]), .enable(|data[31:12]));
  ssdec s4(.in(data[19:16]), .out(ss4[6:0]), .enable(|data[31:16]));
  ssdec s5(.in(data[23:20]), .out(ss5[6:0]), .enable(|data[31:20]));
  ssdec s6(.in(data[27:24]), .out(ss6[6:0]), .enable(|data[31:24]));
  ssdec s7(.in(data[31:28]), .out(ss7[6:0]), .enable(|data[31:28]));
  
endmodule

// Add more modules down here...
module digits(input logic [4:0]in, output logic [31:0]out, input logic clk, input logic reset);
 math m(.op(op), .a(save), .b(current), .r(result)); 
  logic show;
  logic [31:0] current;
  logic [31:0] save;
  logic [3:0] op;
  logic [31:0] result;
  logic [7:0]full;
  
always_ff @(posedge clk, posedge reset) begin
if (reset) begin
  current<= 32'b0;
  save <= 0;
  op <= 0;
  show<= 1'b0;
  full <= 0;
 end
 
  else if(in[4]==1'b0)begin
  if(show==1 && full != 8'b11111111) begin
  current <= {28'b0, in[3:0]};
  show<=1'b0;
  if (in != 0) begin 
  full <= 8'b00000001;
  end 
  end
  
  else if (full != 8'b11111111) begin
  if (full[0] == 1 || in != 0)
    full <= full<<1 | 8'b00000001;
    
  current<= current<<4;
  current[3:0]<=in[3:0];
  end
  end

else if(in==5'b10000) begin
save<=result;
show<=1;
full <= 0;
end

else if(in==5'b10001) begin //X
//current <=current>>4; //failed here 
  if(full[7:0] != 8'b0) begin
   current <=current>>4;
    full <= full>>1;
  end
end

  else if(in==5'b10010) begin
    op<= 0;
     if(show==0)
      save<= current;
    else
        current<=32'b0;
        show<=1;
        full <= 0;
    end
    
  else if(in==5'b10011) begin
     op<= 1;
     if(show==0)
      save<= current;
    else
        current<=32'b0;
        show<=1;
        full <= 0;//step 3
    end
  
  end
  
  always_comb begin
    if (show==0)
     out = current;
    else
     out = save;
  end
endmodule


module math(input logic [3:0] op,
                      input logic [31:0] a,b,
                      output logic [31:0] r);
            always_comb
              case (op)
                0: r = a + b;
                1: r = a - b;
                default: r = 0;
              endcase
    endmodule

module ssdec(input logic [3:0] in,
            input logic enable,
            output logic [6:0]out);
    
    logic [6:0] seg7[15:0];
    
    assign seg7[4'hf] = (enable==1)? 7'b1110001:7'b0000000;
    assign seg7[4'he] = (enable==1)? 7'b1111001:7'b0000000;
    assign seg7[4'hd] = (enable==1)?7'b1011110:7'b0000000;
    assign seg7[4'hc] = (enable==1)?7'b0111001:7'b0000000;
    assign seg7[4'hb] = (enable==1)?7'b1111100:7'b0000000;
    assign seg7[4'ha] = (enable==1)?7'b1110111:7'b0000000;
    assign seg7[4'h9] = (enable==1)?7'b1100111:7'b0000000;
    assign seg7[4'h8] = (enable==1)?7'b1111111:7'b0000000;
    assign seg7[4'h7] = (enable==1)?7'b0000111:7'b0000000;
    assign seg7[4'h6] = (enable==1)?7'b1111101:7'b0000000;
    assign seg7[4'h5] = (enable==1)?7'b1101101:7'b0000000;
    assign seg7[4'h4] = (enable==1)?7'b1100110:7'b0000000;
    assign seg7[4'h3] = (enable==1)?7'b1001111:7'b0000000;
    assign seg7[4'h2] = (enable==1)?7'b1011011:7'b0000000;
    assign seg7[4'h1] = (enable==1)?7'b0000110:7'b0000000;
    assign seg7[4'h0] =(enable==1)?7'b0111111:7'b0000000;
    
    assign out = seg7[in];
 
endmodule

module scankey(input logic clk, input logic [19:0]in, input logic rst, output logic strobe, output logic[4:0]out);
logic [1:0]delay;
assign strobe = delay[1];

always_ff@(posedge clk, posedge rst) begin
if(rst)
  delay<=2'b00;
else begin
  delay[0]<=|in;
  delay[1]<= delay[0];
end
end
always_comb begin

out[0]=in[19]|in[17]|in[15]|in[13]|in[11]|in[9]|in[7]|in[5]|in[3]|in[1];
out[1]=in[19]|in[18]|in[15]|in[14]|in[11]|in[10]|in[7]|in[6]|in[3]|in[2];
out[2]=in[15]|in[14]|in[13]|in[12]|in[7]|in[6]|in[5]|in[4];
out[3]=in[15]|in[14]|in[13]|in[12]|in[11]|in[10]|in[9]|in[8];
out[4]=in[19]|in[18]|in[17]|in[16];
end
endmodule

