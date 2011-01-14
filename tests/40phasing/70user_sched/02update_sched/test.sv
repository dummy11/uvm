//----------------------------------------------------------------------
//   Copyright 2007-2010 Mentor Graphics, Corp.
//   Copyright 2007-2010 Cadence Design Systems, Inc.
//   Copyright 2010 Synopsys, Inc.
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------

// This test demonstrates a user defined phase into the 
// uvm shedule.
//
// This test puts a hard_reset phase between the pre_reset and
// reset phases.
//
// There are two components, one which uses the new phase and
// one which doesn't.
//
// Component                        Phase        Start time    End time
// ---------------------------------------------------------------------
//  uvm_test_top.me.mc (mycomp)     reset           0            30
//  uvm_test_top.me.oc (othercomp)  reset           0            40
//  uvm_test_top.me.mc (mycomp)     post_reset     40            70
//  uvm_test_top.me.mc (ohtercomp)  post_reset     40            60
//  uvm_test_top.me.mc (mycomp)     my_cfg         70            100
//  uvm_test_top.me.mc (ohtercomp)  configure      100           130
//  uvm_test_top.me.mc (ohtercomp)  configure      100           140


`include "uvm_macros.svh"

// Macro for creating a phase that calls a phase implementation
// task for a specific component type which implements. The implemenation
// has to be a parameterized type parameterized to a component type which
// has the phase implementation as part of this. The alternative would be
// to explicitly call set_phase_imp in each component ctor.

`define my_task_phase(PHASE) \
   class ``PHASE``_phase#(type T=my_component) extends uvm_task_phase; \
     task exec_task(uvm_component comp, uvm_phase_schedule phase); \
       T mycomp; \
       if($cast(mycomp, comp)) begin \
         mycomp.``PHASE ; \
       end \
     endtask \
     function new(string name); \
       super.new(`"PHASE`"); \
       set_name(`"PHASE`"); \
     endfunction \
     static ``PHASE``_phase#(T) m_inst = get(); \
     static function ``PHASE``_phase#(T) get(); \
       if(m_inst == null) begin \
         m_inst = new(`"PHASE`"); \
       end \
       return m_inst; \
     endfunction \
   endclass \

package mypkg;
  import uvm_pkg::*;

  // Pseudo interface class for phase schedule just for
  // defining the schedule. When SV supports interface classes,
  // this would be an interface class.
  virtual class my_component;
    pure virtual task my_cfg;
  endclass

  // Create the paramterized class definitions for:
  // my_cfg_phase#(T)

  `my_task_phase(my_cfg)
endpackage

module test;
  import uvm_pkg::*;
  import mypkg::*;

  // Some component that will use the new schedule
  class mycomp extends uvm_component;
    time start_reset, start_pre_configure, start_my_cfg, start_configure;
    time end_reset, end_pre_configure, end_my_cfg, end_configure;

    uvm_phase_schedule my_sched;
    function new(string name, uvm_component parent);
      super.new(name,parent);
      set_phase_domain("uvm");
    endfunction

    // The component needs to override teh set_phase_schedule to add
    // the new schedule.
    function void set_phase_schedule(string domain_name);
      uvm_phase_schedule new_phase;
      super.set_phase_schedule(domain_name);
      my_sched = find_phase_schedule("uvm_pkg::uvm", domain_name);

      assert(my_sched != null);

      //Add the new phase if needed
      new_phase = my_sched.find_schedule("my_cfg");
      if(new_phase == null) begin
        my_sched.add_phase(my_cfg_phase#(mycomp)::get(),
          .after_phase(my_sched.find_schedule("pre_configure")),
          .before_phase(my_sched.find_schedule("configure")));
      end
    endfunction

    task reset_phase;
      start_reset = $time;
      `uvm_info("RST", "IN RESET", UVM_NONE)
      #30 `uvm_info("RST", "END RESET", UVM_NONE)
      end_reset = $time;
    endtask
    task pre_configure_phase;
      start_pre_configure = $time;
      `uvm_info("PRECFG", "IN PRECFG", UVM_NONE)
      #30 `uvm_info("PRECFG", "END PRECFG", UVM_NONE)
      end_pre_configure = $time;
    endtask
    task my_cfg;
      start_my_cfg = $time;
      `uvm_info("MYCFG", "IN MY CFG", UVM_NONE)
      #30 `uvm_info("MYCFG", "END MY CFG", UVM_NONE)
      end_my_cfg = $time;
    endtask
    task configure_phase;
      start_configure = $time;
      `uvm_info("CFG", "IN CONFIGURE", UVM_NONE)
      #30 `uvm_info("CFG", "END CONFIGURE", UVM_NONE)
      end_configure = $time;
    endtask
  endclass

  // Some other component that will use the new schedule
  class othercomp extends uvm_component;
    time start_reset, start_pre_configure, start_configure;
    time end_reset, end_pre_configure, end_configure;

    function new(string name, uvm_component parent);
      super.new(name,parent);
      set_phase_domain("uvm");
    endfunction

    task reset_phase;
      start_reset = $time;
      `uvm_info("RST", "IN RESET", UVM_NONE)
      #40 `uvm_info("RST", "END RESET", UVM_NONE)
      end_reset = $time;
    endtask
    task pre_configure_phase;
      start_pre_configure = $time;
      `uvm_info("PRECFG", "IN PRECFG", UVM_NONE)
      #20 `uvm_info("PRECFG", "END PRECFG", UVM_NONE)
      end_pre_configure = $time;
    endtask
    task configure_phase;
      start_configure = $time;
      `uvm_info("CFG", "IN CONFIGURE", UVM_NONE)
      #40 `uvm_info("CFG", "END CONFIGURE", UVM_NONE)
      end_configure = $time;
    endtask
  endclass

  // Normal environment adds the two sub component.
  class myenv extends uvm_component;
    mycomp mc;
    othercomp oc;
    function new(string name, uvm_component parent);
      super.new(name,parent);
      mc = new("mc", this);
      oc = new("oc", this);
    endfunction
    task run_phase;
      `uvm_info("RUN", "In run", UVM_NONE)
      #10 `uvm_info("RUN", "Done with run", UVM_NONE)
//Current global stop integration has an issue here... needs
//to be looked at
`ifdef WORKAROUND
run_ph.phase_done.drop_objection();
`endif
    endtask
  endclass

  // Normal test that contains just the one env.
  class test extends uvm_component;
    myenv me;
    `uvm_component_utils(test)
    function new(string name, uvm_component parent);
      super.new(name,parent);
      me = new("me", this);
    endfunction
    function void report_phase;
      if(me.mc.start_reset != 0 || 
         me.oc.start_reset != 0) begin
        $display("*** UVM TEST FAILED , reset started at time %t/%0t instead of 0", me.mc.start_reset, me.oc.start_reset);
        return;
      end
      if(me.mc.end_reset != 30 || 
         me.oc.end_reset != 40) begin
        $display("*** UVM TEST FAILED , reset end times (%0t/%0t)", me.mc.end_reset, me.oc.end_reset);
        return;
      end
      if(me.mc.start_pre_configure != 40 || 
         me.oc.start_pre_configure != 40) begin
        $display("*** UVM TEST FAILED , pre_configure started at time %t/%0t instead of 0", me.mc.start_pre_configure, me.oc.start_pre_configure);
        return;
      end
      if(me.mc.end_pre_configure != 70 || 
         me.oc.end_pre_configure != 60) begin
        $display("*** UVM TEST FAILED , pre_configure end times (%0t/%0t)", me.mc.end_pre_configure, me.oc.end_pre_configure);
        return;
      end
      if(me.mc.start_my_cfg != 70) begin 
        $display("*** UVM TEST FAILED , my_cfg started at time %t instead of 0", me.mc.start_my_cfg);
        return;
      end
      if(me.mc.end_my_cfg != 100 ) begin
        $display("*** UVM TEST FAILED , my_cfg end times (%0t)", me.mc.end_my_cfg);
        return;
      end
      if(me.mc.start_configure != 100 || 
         me.oc.start_configure != 100) begin
        $display("*** UVM TEST FAILED , configure started at time %t/%0t instead of 0", me.mc.start_configure, me.oc.start_configure);
        return;
      end
      if(me.mc.end_configure != 130 || 
         me.oc.end_configure != 140) begin
        $display("*** UVM TEST FAILED , configure end times (%0t/%0t)", me.mc.end_configure, me.oc.end_configure);
        return;
      end
      $display("**** UVM TEST PASSED *****");

    endfunction
  endclass

  initial run_test(); 
endmodule

