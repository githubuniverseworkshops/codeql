/**
 * @name Block
 * @kind problem
 * @problem.severity warning
 * @id java/example/block
 */

import java

from BlockStmt b, int n
where n = b.getNumStmt()
select b, "This is a block with " + n + " statements."
