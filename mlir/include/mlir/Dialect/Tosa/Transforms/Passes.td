//===-- Passes.td - TOSA optimization pass declarations ----*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares the optimization passes for the TOSA Dialect in MLIR.
//
//===----------------------------------------------------------------------===//

include "mlir/Pass/PassBase.td"

def TosaMakeBroadcastable : FunctionPass<"tosa-make-broadcastable"> {
  let summary = "TOSA rank Reshape to enable Broadcasting";
  let description = [{
    Pass that enables broadcast by making all input arrays have the same
    number of dimensions. Insert RESHAPE operations to prepend dimensions
    of size one until the number of dimensions is equal. Implements
    approach similar to step 1 of Numpy 4-step broadcasting:
    https://numpy.org/doc/stable/reference/ufuncs.html#broadcasting
  }];

  let constructor = "createTosaMakeBroadcastablePass()";
}

// TOSA Test Passes

def TosaTestQuantUtils : FunctionPass<"tosa-test-quant-utils"> {
  let summary = "TOSA Test: Exercise the APIs in QuantUtils.cpp";
  let description = [{
    Exercises the API that builds a quantized type from min/max quantized range.
  }];

  let constructor = "createTosaTestQuantUtilAPIPass()";
}
