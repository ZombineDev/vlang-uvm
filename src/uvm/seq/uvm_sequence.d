//----------------------------------------------------------------------
//   Copyright 2007-2011 Mentor Graphics Corporation
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
module uvm.seq.uvm_sequence;

import uvm.meta.misc;
import uvm.base.uvm_printer;
import uvm.base.uvm_object_globals;

import uvm.seq.uvm_sequence_item;
import uvm.seq.uvm_sequence_base;
import uvm.seq.uvm_sequencer_param_base;
import esdl.data.rand;

//------------------------------------------------------------------------------
//
// CLASS: uvm_sequence #(REQ,RSP)
//
// The uvm_sequence class provides the interfaces necessary in order to create
// streams of sequence items and/or other sequences.
//
//------------------------------------------------------------------------------

abstract class uvm_sequence (REQ = uvm_sequence_item,
			     RSP = REQ):
  uvm_sequence_base
{
  mixin uvm_sync;

  alias uvm_sequencer_param_base!(REQ, RSP) sequencer_t;

  @uvm_public_sync @rand!false
  private sequencer_t        _param_sequencer;
  @uvm_public_sync @rand!false
  private REQ                _req;
  @uvm_public_sync @rand!false
  private RSP                _rsp;

  // Function: new
  //
  // Creates and initializes a new sequence object.

  public this(string name = "uvm_sequence") {
    super(name);
  }

  // Function: send_request
  //
  // This method will send the request item to the sequencer, which will forward
  // it to the driver.  If the rerandomize bit is set, the item will be
  // randomized before being sent to the driver. The send_request function may
  // only be called after <uvm_sequence_base::wait_for_grant> returns.

  final override public void send_request(uvm_sequence_item request,
					  bool rerandomize = 0) {
    synchronized(this) {
      REQ m_request = cast(REQ) request;

      if (m_sequencer is null) {
	uvm_report_fatal("SSENDREQ", "Null m_sequencer reference", UVM_NONE);
      }
      if (request is null) {
	uvm_report_fatal("SSENDREQ", "Failure to cast uvm_sequence_item to request", UVM_NONE);
      }
      m_sequencer.send_request(this, m_request, rerandomize);
    }
  }


  // Function: get_current_item
  //
  // Returns the request item currently being executed by the sequencer. If the
  // sequencer is not currently executing an item, this method will return null.
  //
  // The sequencer is executing an item from the time that get_next_item or peek
  // is called until the time that get or item_done is called.
  //
  // Note that a driver that only calls get will never show a current item,
  // since the item is completed at the same time as it is requested.

  final public REQ get_current_item() {
    synchronized(this) {
      _param_sequencer = cast(sequencer_t) m_sequencer;
      if (_param_sequencer is null) {
	uvm_report_fatal("SGTCURR", "Failure to cast m_sequencer to the"
			 " parameterized sequencer", UVM_NONE);
      }
      return (_param_sequencer.get_current_item());
    }
  }

  // Task: get_response
  //
  // By default, sequences must retrieve responses by calling get_response.
  // If no transaction_id is specified, this task will return the next response
  // sent to this sequence.  If no response is available in the response queue,
  // the method will block until a response is recieved.
  //
  // If a transaction_id is parameter is specified, the task will block until
  // a response with that transaction_id is received in the response queue.
  //
  // The default size of the response queue is 8.  The get_response method must
  // be called soon enough to avoid an overflow of the response queue to prevent
  // responses from being dropped.
  //
  // If a response is dropped in the response queue, an error will be reported
  // unless the error reporting is disabled via
  // set_response_queue_error_report_disabled.

  // task
  public void get_response(out RSP response, int transaction_id = -1) {
    uvm_sequence_item rsp;
    get_base_response(rsp, transaction_id);

    response = cast(RSP) rsp;
  }



  // Function- put_response
  //
  // Internal method.

  override public void put_response(uvm_sequence_item response_item) {
    synchronized(this) {
      RSP response = cast(RSP) response_item;
      if (response is null) {
	uvm_report_fatal("PUTRSP", "Failure to cast response in put_response", UVM_NONE);
      }
      put_base_response(response_item);
    }
  }


  // Function- do_print
  //
  final override public void do_print (uvm_printer printer) {
    super.do_print(printer);
    printer.print_object("req", req);
    printer.print_object("rsp", rsp);
  }


  // // Function- create_request
  // //
  // // Returns an instance of the ~REQ~ type in a <uvm_sequence_item> base handle.
  // // Used for type-compatibility checking. Unrelated (inheritance-wise) sequence
  // // A #(R1,S1) can run on sequencer #(R,S) as long as R1 and S1 are by themselves
  // // type-compatible with R and S, respectively.
  // override public uvm_sequence_item create_request () {
  //   REQ req = new REQ();
  //   return req;
  // }

  // // Function- create_response
  // //
  // // Returns an instance of the ~RSP~ type in a <uvm_sequence_item> base handle.
  // // Used for type-compatibility checking. Unrelated (inheritance-wise) sequence
  // // A #(R1,S1) can run on sequencer #(R,S) as long as R1 and S1 are by themselves
  // // type-compatible with R and S, respectively.
  // override public uvm_sequence_item create_response () {
  //   RSP rsp = new RSP();
  //   return rsp;
  // }
}
