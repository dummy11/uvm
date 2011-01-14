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


module top;

import uvm_pkg::*;
`include "uvm_macros.svh"

// Test the simple setting of default sequences for a couple of
// different phases on two sequencers. Each phase has a different
// sequence type. Sequencer 1 runs the sequence in the configure 
// and main phases and Sequencer 2 runs in the pre_configure and 
// pre_main phases. Both run in the shutdown phase.
//
// The timing should be:
//    0    seqr2  (pre_configure)
//   10    seqr1  (configure)
//   20    seqr2  (pre_main)
//   30    seqr1  (main)
//  130    seqr1  (shutdown)
//         seqr2  (shutdown)

typedef class myseqr;
class wrapper;
  int array[time];
endclass

wrapper seqr_seqs[myseqr];

class myseq extends uvm_sequence;
  `uvm_object_utils(myseq)
 
  wrapper w; 
  task body;
    int c;
    myseqr seqr;

    $cast(seqr, m_sequencer);
    if(seqr_seqs.exists(seqr))
      w = seqr_seqs[seqr];
    else begin
      w = new;
      seqr_seqs[seqr] = w;
    end

    c = w.array[$time];
    w.array[$time] = c+1;
   
    `uvm_info("INBODY", $sformatf("Starting %s !!!",get_name()), UVM_NONE)
    #10;
    `uvm_info("INBODY", $sformatf("Ending %s !!!",get_name()), UVM_NONE)
  endtask
endclass

class my_preconfig_seq extends myseq;
  static int start_cnt = 0, end_cnt = 0;
  `uvm_object_utils(my_preconfig_seq)
  task body;
    start_cnt++;
    super.body();
    end_cnt++;
  endtask
endclass
class my_config_seq extends myseq;
  static int start_cnt = 0, end_cnt = 0;
  `uvm_object_utils(my_config_seq)
  task body;
    start_cnt++;
    super.body();
    end_cnt++;
  endtask
endclass
class my_premain_seq extends myseq;
  static int start_cnt = 0, end_cnt = 0;
  `uvm_object_utils(my_premain_seq)
  task body;
    start_cnt++;
    super.body();
    end_cnt++;
  endtask
endclass
class my_main_seq extends myseq;
  static int start_cnt = 0, end_cnt = 0;
  `uvm_object_utils(my_main_seq)
  task body;
    start_cnt++;
    super.body();
    end_cnt++;
  endtask
endclass
class my_shutdown_seq extends myseq;
  static int start_cnt = 0, end_cnt = 0;
  `uvm_object_utils(my_shutdown_seq)
  task body;
    start_cnt++;
    super.body();
    end_cnt++;
  endtask
endclass

class myseqr extends uvm_sequencer;
  function new(string name, uvm_component parent);
    super.new(name,parent);
    set_phase_domain("uvm", .hier(0));
  endfunction
  `uvm_component_utils(myseqr)

  task main_phase;
    `uvm_info("MAIN","In main!!!", UVM_NONE)
    #100;
    `uvm_info("MAIN","Exit main!!!", UVM_NONE)
  endtask
endclass


class test extends uvm_test;
   myseqr seqr1, seqr2;
   function new(string name = "my_comp", uvm_component parent = null);
      super.new(name, parent);
   endfunction

   `uvm_component_utils(test)

   function void build_phase();
      uvm_phase_schedule domain, cfg, main;
      seqr1 = new("seqr1", this);
      seqr2 = new("seqr2", this);
      seqr1.set_phase_seq(uvm_configure_ph, my_config_seq::type_id::get());
      seqr1.set_phase_seq(uvm_main_ph, my_main_seq::type_id::get());
      seqr1.set_phase_seq(uvm_shutdown_ph, my_shutdown_seq::type_id::get());
      seqr2.set_phase_seq(uvm_pre_configure_ph, my_preconfig_seq::type_id::get());
      seqr2.set_phase_seq(uvm_pre_main_ph, my_premain_seq::type_id::get());
      seqr2.set_phase_seq(uvm_shutdown_ph, my_shutdown_seq::type_id::get());
   endfunction
   
   function void report_phase();
     wrapper w;

     if(seqr_seqs.num() != 2) begin
       $display("*** UVM TEST FAILED expected 2 sequencers to report, got %0d ***", seqr_seqs.num());
       return;
     end
     if(!seqr_seqs.exists(seqr1) || !seqr_seqs.exists(seqr2)) begin
       $display("*** UVM TEST FAILED results from a sequencer do not exist***");
       return;
     end

     foreach(seqr_seqs[i]) begin
        myseqr seqr = i;
        time t;
        w = seqr_seqs[seqr];
        // Each sequencer has 3 default sequences
        if(w.array.num() != 3) begin
          $display("*** UVM TEST FAILED sequencer %s has %0d sequences, but expected 3 ***", seqr.get_full_name(), w.array.num());
         return;
        end
        // Should have exactly one sequence at each time
        if(w.array.first(t)) begin
          do begin
            if(w.array[t] != 1) begin
              $display("*** UVM TEST FAILED sequencer %s has %0d sequences at time %0t, but expected only 1 ***", seqr.get_full_name(), w.array[t], t);
              return;
            end
          end while(w.array.next(t));
        end
        // Check the specific sequencer times
        if(seqr == seqr1)
            begin
              if(!w.array.exists(10) || !w.array.exists(30) || !w.array.exists(130)) begin
                $display("*** UVM TEST FAILED sequencer %s has wrong sequence times ***", seqr.get_full_name());
                return;
              end
            end
        else if(seqr == seqr2)
            begin
              if(!w.array.exists(0) || !w.array.exists(20) || !w.array.exists(130)) begin
                $display("*** UVM TEST FAILED sequencer %s has wrong sequence times ***", seqr.get_full_name());
                return;
              end
            end
        else
            begin
              $display("*** UVM TEST FAILED invalid sequencer results ***");
              return;
            end
     end

     if(my_preconfig_seq::start_cnt != 1 && my_preconfig_seq::end_cnt != 1) begin
       $display("*** UVM TEST FAILED, expected a total of 1 preconfig sequence ***");
       return;
     end
     if(my_config_seq::start_cnt != 1 && my_config_seq::end_cnt != 1) begin
       $display("*** UVM TEST FAILED, expected a total of 1 config sequence ***");
       return;
     end
     if(my_premain_seq::start_cnt != 1 && my_premain_seq::end_cnt != 1) begin
       $display("*** UVM TEST FAILED, expected a total of 1 premain sequence ***");
       return;
     end
     if(my_main_seq::start_cnt != 1 && my_main_seq::end_cnt != 1) begin
       $display("*** UVM TEST FAILED, expected a total of 1 main sequence ***");
       return;
     end
     if(my_shutdown_seq::start_cnt != 2 && my_shutdown_seq::end_cnt != 2) begin
       $display("*** UVM TEST FAILED, expected a total of 2 shutdown sequence ***");
       return;
     end

     $display("*** UVM TEST PASSED ***");
   endfunction
   
endclass

initial
begin
   run_test();
end

endmodule
