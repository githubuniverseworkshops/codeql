/**
 * @name Use after free
 * @kind path-problem
 * @id cpp/workshop/use-after-free
 */

import cpp

import semmle.code.cpp.dataflow.TaintTracking
import DataFlow::PathGraph


class Config extends DataFlow::Configuration {
  Config() { this = "Use after free config (doesn't matter)"}

  override predicate isSource(DataFlow::Node arg) {
    exists(FunctionCall call |
      call.getArgument(0) = arg.asDefiningArgument() and
      call.getTarget().hasGlobalOrStdName("free")
    )
  }

  override predicate isSink(DataFlow::Node sink) {
    dereferenced(sink.asExpr()) // depends on DataFlow1
  }

  override predicate isBarrier(DataFlow::Node barrier) {
    none()
  }
}

from DataFlow::PathNode source, DataFlow::PathNode sink, Config config
where config.hasFlowPath(source, sink)
select sink, source, sink,
  "Potential use-after-free vulnerability: memory is $@ and $@.",
  source, "freed here", sink, "used here"
