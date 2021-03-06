//
//------------------------------------------------------------------------------
//   Copyright 2007-2010 Mentor Graphics Corporation
//   Copyright 2007-2010 Cadence Design Systems, Inc.
//   Copyright 2010 Synopsys, Inc.
//   Copyright 2014 Coverify Systems Technology
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
//------------------------------------------------------------------------------


module uvm.base.uvm_array;

//------------------------------------------------------------------------------
//
// CLASS: uvm_array #(T)
//
//------------------------------------------------------------------------------
// Implements a class-based dynamic array. Allows arrays to be allocated on
// demand, and passed and stored by reference.
//------------------------------------------------------------------------------

import uvm.base.uvm_object;

class uvm_array (T=int): uvm_object
{
  import uvm.base.uvm_globals: uvm_report_warning;
  import std.string: format;
  // const static string type_name = "uvm_array";

  alias uvm_array!T this_type;

  // No this aliasing -- this aliasing is making the array object
  // escape from the synchronization guards

  // // For this aliasing
  // @property public ref auto get_array() {
  //   synchronized(this) {
  //     return _array;
  //   }
  // }

  // // Some DMD bug is not allowing this alias here
  // alias get_array this;

  protected T[] _array;

  // Function: new
  //
  // Creates a new array with the given ~name~.

  this (string name = "") {
    super(name);
  }


  public T opIndex(size_t index) {
    synchronized(this) {
      return _array[index];
    }
  }

  public T opIndexAssign(T item, size_t index) {
    synchronized(this) {
      _array[index] = item;
      return item;
    }
  }

  int opApply(int delegate(ref T) dg) {
    synchronized(this) {
      int result = 0;
      for (size_t i = 0; i < _array.length; ++i) {
	result = dg(_array[i]);
	if (result) break;
      }
      return result;
    }
  }



  // Function: get
  //
  // Returns the item at the given ~index~.
  //
  // If no item exists by that key, a new item is created with that key
  // and returned.

  public T get (ptrdiff_t index) {
    synchronized(this) {
      T default_value;
      if (index >= size() || index < 0) {
	uvm_report_warning("ARRAYGET",
			   format("get: given index out of range for array of"
				  " size %0d. Ignoring get request", size()));
	return default_value;
      }
      return _array[index];
    }
  }


  // Function: size
  //
  // Returns the number of items stored in the array.

  public size_t length() {
    synchronized(this) {
      return _array.length;
    }
  }

  alias length size;
  // Function: insert
  //
  // Inserts the item at the given ~index~ in the array.

  public void insert (ptrdiff_t index, T item) {
    synchronized(this) {
      if (index >= size() || index < 0) {
	import uvm.base.uvm_globals;
	uvm_report_warning("ARRAYINS",
			   format("insert: given index out of range for array of"
				  " size %0d. Ignoring insert request", size()));
	return;
      }
      auto pre = _array[0..index];
      auto post = _array[index..$];
      _array = pre ~ item ~ post;
    }
  }


  // Function: delete
  //
  // Removes the item at the given ~index~ from the array; if ~index~ is
  // not provided, the entire contents of the array are deleted.

  // it is named delete in systemverilog version -- but D reserves
  // delete as a keyword
  public void remove (ptrdiff_t index=-1) {
    synchronized(this) {
      if (index >= size() || index < -1) {
	uvm_report_warning("ARRAYDEL",
			   format("remove: given index out of range for array of"
				  " size %0d. Ignoring delete request", size()));
	return;
      }
      if (index is -1) _array = [];
      else {
	auto pre = _array[0..index];
	auto post = _array[index+1..$];
	_array = pre ~ post;
      }
    }
  }


  // Function: pop_front
  //
  // Returns the first element in the array (index=0),
  // or ~null~ if the array is empty.

  public T pop_front() {
    synchronized(this) {
      auto pop = _array[0];
      _array = _array[1..$];
      return pop;
    }
  }


  // Function: pop_back
  //
  // Returns the last element in the array (index=size()-1),
  // or ~null~ if the array is empty.

  public T pop_back() {
    synchronized(this) {
      auto pop = _array[$-1];
      _array = _array[0..$-1];
      return pop;
    }
  }


  // Function: push_back
  //
  // Inserts the given ~item~ at the back of the array.

  public void push_back(T item) {
    synchronized(this) {
      _array ~= item;
    }
  }

  public void opOpAssign(string op, R)(R other)
    if(op == "~" && is(R unused: T)) {
      synchronized(this) {
	_array ~= other;
      }
    }

  override public uvm_object create (string name = "") {
    synchronized(this) {
      this_type v = new this_type (name);
      return v;
    }
  }

  override public string get_type_name () {
    synchronized(this) {
      import std.conv: to;
      return to!string(typeid(this));
    }
  }

  override public void do_copy (uvm_object rhs) {
    synchronized(this) {
      super.do_copy(rhs);
      this_type p = cast(this_type) rhs;
      if (rhs is null || p is null) {
	return;
      }
      _array = p._array.dup;
    }
  }

  override public string convert2string() {
    import std.conv: to;
    return to!string(this);
  }

  public string to(S)() if(is(S == string)) {
    synchronized(this) {
      import std.conv: to;
      return std.conv.to!string(this._array);
    }
  }

}
