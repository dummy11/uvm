//----------------------------------------------------------------------
//   Copyright 2007-2009 Mentor Graphics Corporation
//   Copyright 2007-2009 Cadence Design Systems, Inc. 
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

`ifndef UVM_VERSION_SVH
`define UVM_VERSION_SVH

parameter string uvm_mgc_copyright = "(C) 2007-2009 Mentor Graphics Corporation";
parameter string uvm_cdn_copyright = "(C) 2007-2009 Cadence Design Systems, Inc.";
parameter string uvm_snps_copyright = "(C) 2010 Synopsys, Inc.";
parameter string uvm_revision = `UVM_VERSION_STRING;

function string uvm_revision_string();
  return uvm_revision;
endfunction

`endif // UVM_VERSION_SVH