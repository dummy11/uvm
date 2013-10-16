//
//-----------------------------------------------------------------------------
//   Copyright 2007-2011 Mentor Graphics Corporation
//   Copyright 2007-2011 Cadence Design Systems, Inc.
//   Copyright 2010 Synopsys, Inc.
//   Copyright 2013 NVIDIA Corporation
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
//-----------------------------------------------------------------------------

//------------------------------------------------------------------------------
// File: Transaction Recording Streams
//

// class- m_uvm_tr_stream_cfg
// Undocumented helper class for storing stream
// initialization values.
class m_uvm_tr_stream_cfg;
   uvm_tr_database db;
   uvm_component cntxt;
   string stream_type_name;
endclass : m_uvm_tr_stream_cfg

typedef class uvm_set_before_get_dap;
typedef class uvm_text_recorder;
   
//------------------------------------------------------------------------------
//
// CLASS: uvm_tr_stream
//
// The ~uvm_tr_stream~ base class is a representation of a stream of records
// within a <uvm_tr_database>.
//
// The record stream is intended to hide the underlying database implementation
// from the end user, as these details are often vendor or tool-specific.
//
// The ~uvm_tr_stream~ class is pure virtual, and must be extended with an
// implementation.  A default text-based implementation is provided via the
// <uvm_text_tr_stream> class.
//
virtual class uvm_tr_stream extends uvm_object;

   // Variable- m_cfg_dap
   // Data access protected reference to the DB
   local uvm_set_before_get_dap#(m_uvm_tr_stream_cfg) m_cfg_dap;

   // Variable- m_open_records
   // Used for tracking records between the open..closed state
   time m_open_records[uvm_recorder];

   // Variable- m_closed_records
   // Used for tracking records between the closed..free state
   time m_closed_records[uvm_recorder];

   // Variable- m_warn_null_cfg
   // Used to limit the number of warnings
   local bit m_warn_null_cfg;
   
   // Function: new
   // Constructor
   //
   // Parameters:
   // name - Stream instance name
   function new(string name="unnamed-uvm_tr_stream");
      super.new(name);
      m_cfg_dap = new("cfg_dap");
   endfunction : new

   // Group: Stream API
   //
   // Transactions within a ~uvm_tr_stream~ follow a protocol similar to a folder,
   // in that the user can "Open" and "Close" a recorder.  
   //
   // Due to the fact that many database implementations will require crossing 
   // a language boundary, an additional step of "Freeing" the transaction is required.
   //
   // It is legal to add attributes to a record any time between "Open" and "Close",
   // however it is illegal to add attributes after "Close".
   //
   // A ~link~ can be established within the database any time between "Open" and
   // "Free", however it is illegal to establish a link after "Freeing" the recorder.
   //
   
   // Function: get_db
   // Returns a reference to the database which contains this
   // stream.
   //
   // A warning will be asserted if get_db is called prior to
   // the stream being initialized via <do_opened>.
   function uvm_tr_database get_db();
      m_uvm_tr_stream_cfg m_cfg;
      if (!m_cfg_dap.try_get(m_cfg)) begin
         if (m_warn_null_cfg == 1)
           `uvm_warning("UVM/REC_STR/NO_CFG",
                        $sformatf("attempt to retrieve DB from '%s' before it was set!",
                                  get_name()))
         m_warn_null_cfg = 0;
         return null;
      end
      return m_cfg.db;
   endfunction : get_db
      
   // Function: get_context
   // Returns a reference to the database which contains this
   // stream.
   //
   // A warning will be asserted if get_context is called prior to
   // the stream being initialized via <do_opened>.
   function uvm_component get_context();
      m_uvm_tr_stream_cfg m_cfg;
      if (!m_cfg_dap.try_get(m_cfg)) begin
         if (m_warn_null_cfg == 1)
           `uvm_warning("UVM/REC_STR/NO_CFG",
                        $sformatf("attempt to retrieve CONTEXT from '%s' before it was set!",
                                  get_name()))
         m_warn_null_cfg = 0;
         return null;
      end
      return m_cfg.cntxt;
   endfunction : get_context
      
   // Function: get_stream_type_name
   // Returns a reference to the database which contains this
   // stream.
   //
   // A warning will be asserted if get_stream_type_name is called prior to
   // the stream being initialized via <do_opened>.
   function string get_stream_type_name();
      m_uvm_tr_stream_cfg m_cfg;
      if (!m_cfg_dap.try_get(m_cfg)) begin
         if (m_warn_null_cfg == 1)
           `uvm_warning("UVM/REC_STR/NO_CFG",
                        $sformatf("attempt to retrieve STREAM_TYPE_NAME from '%s' before it was set!",
                                  get_name()))
         m_warn_null_cfg = 0;
         return "";
      end
      return m_cfg.stream_type_name;
   endfunction : get_stream_type_name

   // Function- m_do_opened
   // Initializes the state of the stream
   //
   // Parameters-
   // db - Database which the stream belongs to
   // context - Optional component context
   // stream_type_name - Optional type name for the stream
   //
   // This method will trigger a <do_opened> call.
   //
   // An error will be asserted if-
   // - m_do_opened is called more than once without the stream
   //   being ~freed~ between.
   // - m_do_opened is passed a ~null~ db
   function void m_do_opened(uvm_tr_database db,
                           uvm_component cntxt=null,
                           string stream_type_name="");
      
      m_uvm_tr_stream_cfg m_cfg;
      uvm_tr_database m_db;
      if (db == null) begin
         `uvm_error("UVM/REC_STR/NULL_DB",
                    $sformatf("Illegal attempt to set DB for '%s' to '<null>'",
                              this.get_full_name()))
         return;
      end

      if (m_cfg_dap.try_get(m_cfg)) begin
         `uvm_error("UVM/REC_STR/RE_CFG",
                    $sformatf("Illegal attempt to re-open '%s'",
                              this.get_full_name()))
      end
      else begin
         // Never set before
         m_cfg = new();
         m_cfg.db = db;
         m_cfg.cntxt = cntxt;
         m_cfg.stream_type_name = stream_type_name;
         m_cfg_dap.set(m_cfg);

         do_opened(db, cntxt, stream_type_name);
      end
      
   endfunction : m_do_opened

   // Function- m_do_closing
   // Closes any open recorders within the stream
   //
   // This method will trigger a <do_closing> call.
   function void m_do_closing();
      foreach(m_open_records[idx])
        close_recorder(idx);

      do_closing();
   endfunction : m_do_closing

   // Function- m_do_freeing
   // Flushes the internal state of the stream.
   //
   // This method will be called automatically when the
   // stream is ~freed~ on the database.  Any open ~recorders~
   // on the stream will be closed and freed.
   //
   // This method will trigger a <do_freeing> call.
   function void m_do_freeing();
      // Close and Free open recorders on the stream
      foreach (m_open_records[idx]) begin
         this.close_recorder(idx);
      end
      foreach (m_closed_records[idx]) begin
         this.free_recorder(idx);
      end
      
      m_cfg_dap = new("cfg_dap");
      m_warn_null_cfg = 1;
      // Backwards compat
      if (m_ids_by_stream.exists(this))
        m_free_id(m_ids_by_stream[this]);
      do_freeing();
   endfunction : m_do_freeing
   
   // Function: is_open
   // Returns true if this ~uvm_tr_stream~ was opened on the database,
   // but has not yet been closed.
   //
   function bit is_open();
      m_uvm_tr_stream_cfg m_cfg;
      if (!m_cfg_dap.try_get(m_cfg))
        return 0;

      return m_cfg.db.is_stream_open(this);
   endfunction : is_open

   // Function: is_closed
   // Returns true if this ~uvm_tr_stream~ was closed on the database,
   // but has not yet been freed.
   //
   function bit is_closed();
      m_uvm_tr_stream_cfg m_cfg;
      if (!m_cfg_dap.try_get(m_cfg))
        return 0;

      return m_cfg.db.is_stream_closed(this);
   endfunction : is_closed

   // Group: Transaction Recorder API
   
   // Function: open_recorder
   // Marks the opening of a new transaction recorder on the stream.
   //
   // Parameters:
   // name - A name for the new transaction
   // open_time - Optional time to record as the opening of this transaction
   // type_name - Optional type name for the transaction
   //
   // If ~open_time~ is omitted (or set to '0'), then the stream will use
   // the current time.
   //
   // This method will trigger a <do_open_recorder> call.  If ~do_open_recorder~
   // returns a non-null value, then the <uvm_recorder::do_opened> method will
   // be called in the recorder.
   //
   // Transaction recorders can only be opened if the stream is
   // ~open~ on the database (per <is_open>).  Otherwise the
   // request will be ignored, and ~null~ will be returned.
   function uvm_recorder open_recorder(string name,
                                      time   open_time = 0,
                                      string type_name="");
      time m_time = (open_time == 0) ? $time : open_time;

      // Check to make sure we're open
      if (!is_open())
        return null;
      
      open_recorder = do_open_recorder(name,
                                       m_time,
                                       type_name);

      if (open_recorder != null) begin
         m_open_records[open_recorder] = m_time;
         open_recorder.m_do_opened(this, m_time, type_name);
      end
   endfunction : open_recorder

   // Function: close_recorder
   // Marks the closing of a transaction in the stream.
   //
   // Parameters:
   // tr - The transaction recorder which is closing
   // close_time - Optional time to record as the closing of this transaction.
   //
   // If ~close_time~ is omitted (or set to '0'), then the stream will use
   // the current time.
   //
   // An error will be asserted if:
   // - ~tr~ is ~null~
   // - ~tr~ has already ended
   // - ~tr~ was not generated by this stream
   // - the ~close_time~ is prior to the ~open_time~
   //
   // This method will trigger a <uvm_recorder::do_closing> call, followed
   // by a <do_close_recorder> call.
   function void close_recorder(uvm_recorder tr,
                            time close_time = 0);
      time m_time = (close_time == 0) ? $time : close_time;
      if (tr == null) begin
         `uvm_error("UVM/REC_STR/END_NULL",
                    $sformatf("illegal '<null>' recorder passed to close_recorder on '%s'",
                              get_name()))
         return;
      end
      else if (m_closed_records.exists(tr)) begin
         `uvm_error("UVM/REC_STR/END_AGAIN",
                    $sformatf("illegal attempt to re-end tr '%s' on '%s'",
                              tr.get_name(),
                              get_name()))
         return;
      end
      else if (!m_open_records.exists(tr)) begin
         `uvm_error("UVM/REC_STR/END_INV",
                    $sformatf("illegal attempt to end invalid tr '%s' on '%s'",
                              tr.get_name(),
                              get_name()))
         return;
      end
      else if (m_time < m_open_records[tr]) begin
         `uvm_error("UVM/REC_STR/END_B4_BEGIN",
                    $sformatf("illegal attempt to end tr '%s' on '%s' at time %0t, which is before the begin time %0t",
                              tr.get_name(),
                              get_name(),
                              m_time,
                              m_open_records[tr]))
      end
      m_open_records.delete(tr);
      m_closed_records[tr] = m_time;
      tr.m_do_closing(m_time);
      do_close_recorder(tr, m_time);
   endfunction : close_recorder

   // Function: free_recorder
   // Indicates the stream and database can free any references to the recorder.
   //
   // Parameters:
   // tr - The transaction recorder which is being freed
   // close_time - Optional time to record as the ending of this record
   //
   // If a record has not yet ended (via a call to <close_recorder>), then the
   // record will be explicitly ended via the call to ~free_recorder~.  If
   // this is the case, <close_recorder> will be called automatically.
   //
   // If the record has already ended, then the second parameter to ~free_recorder~
   // will be ignored.
   //
   // This method will trigger a call to <uvm_recorder::do_freeing>, followed by
   // a call to <do_free_recorder>.
   //
   // An error will be asserted if:
   // - ~record~ is null
   // - ~record~ has already been freed
   // - ~record~ was not generated by this stream
   function void free_recorder(uvm_recorder recorder,
                             time close_time = 0);
      if (recorder == null) begin
         `uvm_error("UVM/REC_STR/END_NULL",
                    $sformatf("illegal '<null>' recorder passed to free_recorder on '%s'",
                              get_name()))
         return;
      end
      else if ((!m_closed_records.exists(recorder)) && (!m_open_records.exists(recorder))) begin
         `uvm_error("UVM/REC_STR/END_INV",
                    $sformatf("illegal attempt to free invalid recorder '%s' on '%s'",
                              recorder.get_name(),
                              get_name()))
         return;
      end

      if (m_open_records.exists(recorder)) begin
         // Need to end the record
         close_recorder(recorder, close_time);
      end

      recorder.m_do_freeing();

      do_free_recorder(recorder);

      m_closed_records.delete(recorder);
      
   endfunction : free_recorder

   // Function: get_open_recorders
   // Provides a queue of all open transactions within the stream.
   //
   // Parameters:
   //  q - A reference to a queue of <uvm_recorder>s
   //
   // The ~get_open_recorders~ method returns the size of the queue,
   // such that the user can conditionally process the elements.
   //
   // | uvm_recorder tr_q[$];
   // | if (my_stream.get_open_recorders(tr_q)) begin
   // |   // Process the queue...
   // | end
   function unsigned get_open_recorders(ref uvm_recorder q[$]);
      // Clear out the queue first...
      q.delete();
      // Then fill in the values
      foreach (m_open_records[idx])
        q.push_back(idx);
      // Finally, return the size of the queue
      return q.size();
   endfunction : get_open_recorders

   // Function: get_closed_recorders
   // Provides a queue of all closed transactions within the stream.
   //
   // Parameters:
   //  q = A reference to a queue of <uvm_recorder>s
   //
   // As with ~get_open_recorders~, the ~get_closed_recorders~ method returns 
   // the size of the queue, such that the user can conditionally 
   // process the elements.
   //
   function unsigned get_closed_recorders(ref uvm_recorder q[$]);
      // Clear out the queue first...
      q.delete();
      // Then fill in the values
      foreach (m_closed_records[idx])
        q.push_back(idx);
      // Finally, return the size of the queue
      return q.size();
   endfunction : get_closed_recorders
   
   // Function: is_recorder_open
   // Returns true if the <uvm_recorder> has been ~opened~, but not ~closed~.
   //
   function bit is_recorder_open(uvm_recorder tr);
      return m_open_records.exists(tr);
   endfunction : is_recorder_open

   // Function: is_recorder_closed
   // Returns true if the <uvm_recorder> has been ~closed~, but not ~freed~.
   //
   function bit is_recorder_closed(uvm_recorder tr);
      return m_closed_records.exists(tr);
   endfunction : is_recorder_closed
   
   // Group: Handles

   // Variable- m_ids_by_stream
   // An associative array of integers, indexed by uvm_tr_streams.  This
   // provides a unique 'id' or 'handle' for each stream, which can be
   // used to identify the stream.
   //
   // By default, neither ~m_ids_by_stream~ or ~m_streams_by_id~ are
   // used.  Streams are only placed in the arrays when the user
   // attempts to determine the id for a stream.
   local static integer m_ids_by_stream[uvm_tr_stream];

   // Variable- m_streams_by_id
   // A corollary to ~m_ids_by_stream~, this indexes the streams by their
   // unique ids.
   local static uvm_tr_stream m_streams_by_id[integer];

   // Function: get_handle
   // Returns a unique ID for this stream.
   //
   // A value of ~0~ indicates that the recorder has been ~freed~,
   // and no longer has a valid ID.
   //
   // The value returned by a call to ~get_handle~ is implementation
   // specific, and is provided via the <do_get_handle> method.
   function integer get_handle();
      if (!is_open() && !is_closed()) begin
        return 0;
      end
      else begin
         integer handle = do_get_handle();
         
         // Check for the weird case where our handle changed.
         if (m_ids_by_stream.exists(this) && m_ids_by_stream[this] != handle)
           m_streams_by_id.delete(m_ids_by_stream[this]);

         m_streams_by_id[handle] = this;
         m_ids_by_stream[this] = handle;

         return handle;
      end
   endfunction : get_handle
   
   // Function: get_stream_from_handle
   // Static accessor, returns a stream reference for a given unique id.
   //
   // If no stream exists with the given ~id~, or if the
   // stream with that ~id~ has been freed, then ~null~ is
   // returned.
   //
   static function uvm_tr_stream get_stream_from_handle(integer id);
      if (id == 0)
        return null;

      if (!m_streams_by_id.exists(id))
        return null;

      return m_streams_by_id[id];
   endfunction : get_stream_from_handle
        
   // Function- m_free_id
   // Frees the id/stream link (memory cleanup)
   //
   static function void m_free_id(integer id);
      uvm_tr_stream stream;
      if (m_streams_by_id.exists(id))
        stream = m_streams_by_id[id];

      if (stream != null) begin
         m_streams_by_id.delete(id);
         m_ids_by_stream.delete(stream);
      end
   endfunction : m_free_id

   // Group: Implementation Agnostic API
   //

   // Function: do_opened
   // Callback triggered via <uvm_tr_database::open_stream>.
   //
   // Parameters:
   // db - Database which the stream belongs to
   // context - Optional component context
   // stream_type_name - Optional type name for the stream
   //
   // The ~do_opened~ callback can be used to initialize any internal
   // state within the stream, as well as providing a location to
   // record any initial information about the stream.
   protected virtual function void do_opened(uvm_tr_database db,
                                             uvm_component cntxt,
                                             string stream_type_name);
   endfunction : do_opened

   // Function: do_closing
   // Callback triggered via <uvm_tr_database::close_stream>.
   //
   // The ~do_closing~ callback can be used to set internal state
   // within the stream, as well as providing a location to
   // record any closing information.
   protected virtual function void do_closing();
   endfunction : do_closing
      
   // Function: do_freeing
   // Callback triggered via <uvm_tr_database::free_stream>.
   //
   // The ~do_freeing~ callback can be used to release the internal
   // state within the stream, as well as providing a location
   // to record any "freeing" information.
   protected virtual function void do_freeing();
   endfunction : do_freeing

   // Function: do_open_recorder
   // Marks the beginning of a new record in the stream.
   //
   // Backend implementation of <open_recorder>
   protected virtual function uvm_recorder do_open_recorder(string name,
                                                            time   open_time,
                                                            string type_name);
   endfunction : do_open_recorder

   // Function: do_close_recorder
   // Marks the end of a record in the stream
   //
   // Backend implementation of <close_recorder>
   protected virtual function void do_close_recorder(uvm_recorder recorder,
                                                     time close_time);
   endfunction : do_close_recorder

   // Function: do_free_recorder
   // Indicates the stream and database can free any references to the recorder.
   //
   // Backend implementation of <free_recorder>.
   //
   // Note that unlike the <free_recorder> method, ~do_free_recorder~ does not
   // have the optional ~close_time~ argument.  The argument will be processed
   // by <free_recorder> prior to the ~do_free_recorder~ call.
   protected virtual function void do_free_recorder(uvm_recorder recorder);
   endfunction : do_free_recorder

   // Function: do_get_handle
   // Returns a unique ID for this stream.
   //
   // ~Optional~ Backend implementation for <get_handle>.
   //
   // By default, the unique <uvm_object::get_inst_id> will be
   // used as a handle.
   protected virtual function integer do_get_handle();
      return this.get_inst_id();
   endfunction : do_get_handle
   
   
endclass : uvm_tr_stream

//------------------------------------------------------------------------------
//
// CLASS: uvm_text_tr_stream
//
// The ~uvm_text_tr_stream~ is the default stream implementation for the
// <uvm_text_tr_database>.  
//
//                     

class uvm_text_tr_stream extends uvm_tr_stream;

   // Variable- m_text_db
   // Internal reference to the text-based backend
   local uvm_text_tr_database m_text_db;
   
   // Variable- m_free_recorders
   // Used for memory savings
   static uvm_text_recorder m_free_recorders[$];

   `uvm_object_utils_begin(uvm_text_tr_stream)
   `uvm_object_utils_end

   // Function: new
   // Constructor
   //
   // Parameters:
   // name - Instance name
   function new(string name="unnamed-uvm_text_tr_stream");
      super.new(name);
   endfunction : new

   // Group: Implementation Agnostic API

   // Function: do_opened
   // Callback triggered via <uvm_tr_database::open_stream>.
   //
   protected virtual function void do_opened(uvm_tr_database db,
                                             uvm_component cntxt,
                                             string stream_type_name);
      $cast(m_text_db, db);
      $fdisplay(m_text_db.m_file, 
                "  CREATE_STREAM @%0t {NAME:%s T:%s SCOPE:%s STREAM:%0d}",
                $time,
                this.get_name(),
                stream_type_name,
                (cntxt == null) ? "" : cntxt.get_full_name(),
                this.get_handle());
   endfunction : do_opened

   // Function: do_closing
   // Callback triggered via <uvm_tr_database::close_stream>.
   protected virtual function void do_closing();
      uvm_component cntxt = get_context();
      $fdisplay(m_text_db.m_file,
                "  CLOSE_STREAM @%0t {NAME:%s T:%s SCOPE:%s STREAM:%0d}",
                $time,
                this.get_name(),
                this.get_stream_type_name(),
                (cntxt == null) ? "" : cntxt.get_full_name(),
                this.get_handle());
   endfunction : do_closing
      
   // Function: do_freeing
   // Callback triggered via <uvm_tr_database::free_stream>.
   //
   protected virtual function void do_freeing();
      uvm_component cntxt = get_context();
      $fdisplay(m_text_db.m_file, 
                "  FREE_STREAM @%0t {NAME:%s T:%s SCOPE:%s STREAM:%0d}",
                $time,
                this.get_name(),
                this.get_stream_type_name(),
                (cntxt == null) ? "" : cntxt.get_full_name(),
                this.get_handle());
      m_text_db = null;
      return;
   endfunction : do_freeing
   
   // Function: do_open_recorder
   // Marks the beginning of a new record in the stream
   //
   // Text-backend specific implementation.
   protected virtual function uvm_recorder do_open_recorder(string name,
                                                           time   open_time,
                                                           string type_name);
      if (m_text_db.open_db()) begin
         UVM_FILE file = m_text_db.m_file;
         uvm_text_recorder m_recorder;
         if (m_free_recorders.size() > 0) begin
            m_recorder = m_free_recorders.pop_front();
            m_recorder.set_name(name);
         end
         else
           m_recorder = new(name);
         
         return m_recorder;
      end

      return null;
   endfunction : do_open_recorder

   // Function: do_close_recorder
   // Marks the end of a record in the stream
   //
   // Text-backend specific implementation.
   protected virtual function void do_close_recorder(uvm_recorder recorder,
                                                     time close_time);
      // Text-backend doesn't do anything here
   endfunction : do_close_recorder

   // Function: do_free_recorder
   // Indicates the stream and database can free any references to the recorder.
   //
   // Text-backend specific implementation.
   protected virtual function void do_free_recorder(uvm_recorder recorder);
      // Arbitrary size, useful for example purposes
      if (m_free_recorders.size() < 8) begin
         uvm_text_recorder m_recorder;
         $cast(m_recorder, recorder);
         m_free_recorders.push_back(m_recorder);
      end
   endfunction : do_free_recorder

endclass : uvm_text_tr_stream