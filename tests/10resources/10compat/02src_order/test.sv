module test;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  class mycomp extends uvm_component;
    int build_val=0;
 
    `uvm_new_func
    `uvm_component_utils(mycomp)

    function void build();
      super.build();
      get_config_int("value", build_val);
    endfunction
  endclass
 
  class mid extends uvm_component;
    mycomp mc1;
    mycomp mc2;
    `uvm_new_func
    `uvm_component_utils(mycomp)

    function void build();
      super.build();
      set_config_int("*", "value", 1);
      mc1 = new("mc1", this);
      mc2 = new("mc2", this);
    endfunction
  endclass
 
  class test extends uvm_component;
    mid m1;
    function new(string name, uvm_component parent);
      super.new(name,parent);
    endfunction
    `uvm_component_utils(test)

    function void build();
      super.build();
      set_config_int("*", "value", 22);
      set_config_int("*.mc2", "value", 33);
      m1 = new("m1", this);
    endfunction

    task run;
      bit failed = 0;
      if(m1.mc1.build_val != 22) begin 
        $display("*** UVM TEST FAILED, expected m1.mc1.build_val=22 but got %0d ***", m1.mc1.build_val);
        failed = 1;
      end
      if(m1.mc2.build_val != 33) begin
        $display("*** UVM TEST FAILED, expected m1.mc2.build_val=33 but got %0d ***", m1.mc2.build_val);
        failed = 1;
      end
      if(!failed) $display("*** UVM TEST PASSED ***");
      global_stop_request();
    endtask
  endclass

  initial run_test();
endmodule
