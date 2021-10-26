/**
 * @name Block
 * @kind problem
 * @problem.severity warning
 * @id cpp/example/block
 */

import cpp

from BlockStmt b, int n
where n = b.getNumStmt()
select b, "This is a block with " + n + " statements."
