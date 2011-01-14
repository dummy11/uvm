//---------------------------------------------------------------------- 
//   Copyright 2010 Cadence Design Systems, Inc.
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

// This test creates a simple hierarchy and makes sure that a
// process can wait for specific states of a phase.
//
// The top component executes a run phase forks processes to
// wait for state transitions of the reset, main and shutdown
// phases.

module test;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  bit failed = 0;
  time phase_transition_time = 300;
  bit phase_run[uvm_phase_imp];

  class base extends uvm_component;
    time delay = 100;
    function new(string name, uvm_component parent);
      super.new(name,parent);
      set_phase_schedule("uvm");
    endfunction
    function void build_phase;
      phase_run[uvm_build_ph] = 1;
      `uvm_info("BUILD", "Starting Build", UVM_NONE)
      if($time != 0)  begin
        failed = 1;
        `uvm_error("BUILD", "Expected Build start time of 0")
      end
      `uvm_info("BUILD", "Ending Build", UVM_NONE)
    endfunction
    task reset_phase;
      phase_run[uvm_reset_ph] = 1;
      `uvm_info("RESET", "Starting Reset", UVM_NONE)
      if($time != 0)  begin
        failed = 1;
        `uvm_error("RESET", $sformatf("Expected Reset start time of 0, got %0t", $time))
      end
      #(delay);
      `uvm_info("RESET", "Ending Reset", UVM_NONE)
    endtask
    task main_phase;
      phase_run[uvm_main_ph] = 1;
      `uvm_info("MAIN", "Starting Main", UVM_NONE)
      // Even though there is not configure phase, the test is holding
      // up the configure phase.
      if($time != phase_transition_time)  begin
        failed = 1;
        `uvm_error("MAIN", $sformatf("Expected main start time of %0t, got %0t",phase_transition_time, $time))
      end
      #(delay);
      `uvm_info("MAIN", "Ending Main", UVM_NONE)
    endtask
    task shutdown_phase;
      phase_run[uvm_shutdown_ph] = 1;
      `uvm_info("SHUTDOWN", "Starting Shutdown", UVM_NONE)
      // Even though there is not configure phase, the test is holding
      // up the configure phase.
      if($time != 2*phase_transition_time)  begin
        failed = 1;
        `uvm_error("SHUTDOWN", $sformatf("Expected shutdown start time of %0t, got %0t", 2*phase_transition_time, $time))
      end
      #(delay);
      `uvm_info("SHUTDOWN", "Ending Shutdown", UVM_NONE)
    endtask
    task run_phase;
      phase_run[uvm_run_ph] = 1;
      `uvm_info("RUN", "Starting Run", UVM_NONE)
      if($time != 0)  begin
        failed = 1;
        `uvm_error("RUN", "Expected Run start time of 0")
      end
      #100;
      `uvm_info("RUN", "Ending Run", UVM_NONE)
    endtask
    function void extract_phase;
      phase_run[uvm_extract_ph] = 1;
      `uvm_info("EXTRACT", "Starting Extract", UVM_NONE)
      if($time != 3*phase_transition_time)  begin
        failed = 1;
        `uvm_error("extract", $sformatf("Expected extract start time of %0t but got %0t", 3*phase_transition_time, $time))
      end
      `uvm_info("EXTRACT", "Ending Extract", UVM_NONE)
    endfunction
  endclass

  class leaf extends base;
    function new(string name, uvm_component parent);
      super.new(name,parent);
    endfunction
  endclass
  class test extends base;
    leaf l1, l2; 
    int phases_run = 0;

    `uvm_component_utils(test)
    function new(string name, uvm_component parent);
      super.new(name,parent);
      l1 = new("l1", this);
      l2 = new("l2", this);
      l2.delay = phase_transition_time;
    endfunction
    function void connect_phase();
      set_phase_domain("uvm");
    endfunction

    //Start up the checkers
    function void start_of_simulation_phase;
      uvm_phase_schedule uvm_p = find_phase_schedule("*", "uvm");
      uvm_phase_schedule reset_p = uvm_p.find_schedule("reset");
      uvm_phase_schedule main_p = uvm_p.find_schedule("main");
      uvm_phase_schedule shutdown_p = uvm_p.find_schedule("shutdown");

      //Do the raise, wait, drop for each phase
      fork
        do_phase_test(reset_p, 0);
        do_phase_test(main_p, phase_transition_time);
        do_phase_test(shutdown_p, 2*phase_transition_time);
      join_none
    endfunction

    int start_cnt = 0;
    int end_cnt = 0;

    //By the time this runs, the run phase is done, so make sure
    //that extract is already scheduled.
    task main_phase;
      if(extract_ph.get_state() != UVM_PHASE_SCHEDULED) begin
        uvm_phase_state_t state = extract_ph.get_state();
        failed = 1;
        `uvm_error("SCHED", $sformatf("Expected extract phase be scheduled, but it %s", state.name()))
      end
    endtask

    task do_phase_test(uvm_phase_schedule phase, time start_time);
      //Phase must either be dormant or scheduled at the very start
      if(phase.get_state() != UVM_PHASE_DORMANT && phase.get_state() != UVM_PHASE_SCHEDULED) 
      begin
        uvm_phase_state_t state = phase.get_state();
        failed = 1;
        `uvm_error("DORMANT", $sformatf("Expected phase %s to start out dormant, but it started out %s", phase.get_name(), state.name()))
      end

      //Wait for phase to be started
      wait(phase.get_state() == UVM_PHASE_EXECUTING);
      start_cnt++;
      if($time != start_time) begin
        failed = 1;
        `uvm_error("START", $sformatf("Expected start time of %0t for phase %s, got %0t", start_time, phase.get_name(), $time))
      end

      wait(phase.get_state() == UVM_PHASE_DONE);
      end_cnt++;
      if($time != start_time+phase_transition_time) begin
        failed = 1;
        `uvm_error("END", $sformatf("Expected end time of %0t for phase %s, got %0t", start_time+phase_transition_time, phase.get_name(), $time))
      end
    endtask

    function void report_phase();
      phase_run[uvm_report_ph] = 1;
      if(start_cnt != 3) begin
        failed = 1;
        `uvm_error("NUMSTART", $sformatf("Expected 3 phases to start but got %0d", start_cnt))
      end
      if(end_cnt != 3) begin
        failed = 1;
        `uvm_error("NUMSTART", $sformatf("Expected 3 phases to finish but got %0d", end_cnt))
      end
      if(failed) $display("*** UVM TEST FAILED ***");
      else $display("*** UVM TEST PASSED ***");
    endfunction
  endclass

  initial run_test();
endmodule
