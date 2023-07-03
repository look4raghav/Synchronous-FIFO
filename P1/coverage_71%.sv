// Code your testbench here
// or browse Examples
// Code your testbench here
// or browse Examples
module testbench(synchronous_fifo.tb intf);
  initial
    begin
      intf.clk = 0;
      intf.w_en = 0;
      intf.r_en = 0;
      intf.rst_n = 0;
      intf.data_in = 0;
    end
  
  always #2 intf.clk = ~intf.clk;
  
  covergroup c @(posedge intf.clk);
    option.per_instance = 1;
    
    coverpoint intf.empty 
    {
      bins empty_y = {0};
      bins empty_n = {1};
    }
    coverpoint intf.full 
    {
      bins full_y = {0};
      bins full_n = {1};
    }
    coverpoint intf.rst_n 
    {
      bins rst_y = {0};
      bins rst_n = {1};
    }
    coverpoint intf.w_en 
    {
      bins w_y = {0};
      bins w_n = {1};
    }
    coverpoint intf.r_en 
    {
      bins r_y = {0};
      bins r_n = {1};
    }
    coverpoint intf.data_in 
    {
      option.auto_bin_max = 256;
      bins low = {[0:127]};
      bins high = {[128:255]};
    }
    coverpoint intf.data_out 
    {
      option.auto_bin_max = 256;
      bins low = {[0:127]};
      bins high = {[128:255]};
    }
    //cross
    cross_w_enXdata_in: cross intf.w_en, intf.data_in;
    cross_r_enXdata_out: cross intf.r_en, intf.data_out;
  endgroup
  
  c ci; //group instantaionsss
  
  task push();
    if(!intf.full) begin
      intf.w_en = 1;
      intf.data_in = $random;
      #1 $display("Push In: w_en=%b, r_en=%b, data_in=%h",intf.w_en, intf.r_en,intf.data_in);
    end
    else $display("FIFO Full!! Can not push data_in=%d", intf.data_in);
  endtask 
  
  task pop();
    if(!intf.empty) begin
      intf.r_en = 1;
      #1 $display("Pop Out: w_en=%b, r_en=%b, data_out=%h",intf.w_en, intf.r_en,intf.data_out);
    end
    else $display("FIFO Empty!! Can not pop data_out");
  endtask
  
  task drive(int delay);
    intf.w_en = 0; intf.r_en = 0;
    fork
      begin
        repeat(10) begin @(posedge intf.clk) push(); end
        intf.w_en = 0;
      end
      begin
        #delay;
        repeat(10) begin @(posedge intf.clk) pop(); end
        intf.r_en = 0;
      end
    join
  endtask
  
  initial
    begin
      intf.rst_n = 1'b1;
      #20;
      intf.rst_n = 0;
      intf.w_en = 0;
      intf.r_en = 0;
      #8;
      push();
      #12
      pop();
      #12;
    end
  
  initial 
    begin
      ci = new();
      $display("---");
      $display("Coverage is %0f", ci.get_coverage());
      $display("---");
      $dumpfile("dump.vcd"); 
      $dumpvars;
      #400
      $finish();
  end
endmodule

module top_module();
  synchronous_fifo dtt();
  fifo dut(dtt);
  testbench test(dtt);
endmodule














// Code your design here
// Code your design here
interface synchronous_fifo();
  logic clk, rst_n, w_en, r_en, empty, full;
  logic [1:0] data_in, data_out;
  
  modport dt(input clk, rst_n, w_en, r_en, data_in, output data_out, full, empty);
  modport tb(output clk, rst_n, w_en, r_en, data_in, input data_out, full, empty);
endinterface


module fifo (synchronous_fifo.dt intf);
  
  reg [2:0] w_ptr, r_ptr;
  reg [7:0] fifo[8];
  reg [2:0] count;
  
  always@(posedge intf.clk) begin    			// Set Default values on reset.
    if(!intf.rst_n) begin
      w_ptr <= 0; r_ptr <= 0;
      intf.data_out <= 0;
      count <= 0;
    end
    else begin
      case({intf.w_en, intf.r_en})
        2'b00, 2'b11: count <= count;
        2'b01: count <= count - 1'b1;
        2'b10: count <= count + 1'b1;
      endcase
    end
  end
  
  always@(posedge intf.clk) begin    			// Write data FIFO
    if(intf.w_en & !intf.full)begin
      fifo[w_ptr] <= intf.data_in;
      w_ptr <= w_ptr + 1;
    end
  end
  
  always@(posedge intf.clk) begin   			// Read data FIFO
    if(intf.r_en & !intf.empty) begin
      intf.data_out <= fifo[r_ptr];
      r_ptr <= r_ptr + 1;
    end
  end
  
  assign intf.full = (count == 8);
  assign intf.empty = (count == 0);
endmodule
