# CodeQL workshop for C/C++: Finding use-after-free security vulnerabilities

- Analyzed language: C/C++

If you are attending this workshop at GitHub Universe, or watching [the recording](https://www.youtube.com/watch?v=eAjecQrfv3o), the facilitators will guide you through the steps below. You can use this document as a written reference.

## Overview

- [Problem statement](#problemstatement)
- [Setup instructions](#setupinstructions)
- [Workshop](#workshop)
  - [Section 0: Getting started](#section0)
  - [Section 1: Finding references to freed memory](#section1)
  - [Section 2: Finding dereferences](#section2)
  - [Section 3: Finding use-after-free vulnerabilities](#section3)

## Problem statement <a id="problemstatement"></a>

Use-after-free vulnerabilities occur when a program retains a pointer to memory locations after they have been freed, and attempts to reference the freed memory. When the memory was freed, the system may choose to allocate that memory for another purpose. Attempting to reference the freed memory could result in a variety of unsafe behaviour: crashing the program, retrieving an unexpected value, corrupting data used by another program, or executing unsafe code.

The following C code shows a simple example of using memory after it has been freed.
```c
free(s->x);
...
use(s->x);
```

The code frees the field `x` of a struct `s`, but does not immediately reset the field's value to zero. As a result, the struct now contains a 'dangling' pointer, which creates the potential for a use-after-free vulnerability. This becomes a real vulnerability when the code references `s->x` again, passing it to `use`.

A safer coding practice is to always immediately zero the field after freeing it, like this:

```c
free(s->x);
s->x = 0;
```

Then until `s->x` is reassigned, any attempts to reference it will simply obtain the `null` memory address.

This is a well-known class of vulnerability, documented as [CWE-416](https://cwe.mitre.org/data/definitions/416.html). A relatively recent example in the `curl` tool was assigned [CVE-2018-16840](https://curl.se/docs/CVE-2018-16840.html), and inspired the material here.

In security terminology, a reference to freed memory is considered a **source** of tainted data, and a pointer that is dereferenced (used) is considered a **sink** for a use-after-free vulnerability.

If the tainted reference is reassigned (e.g. to zero) before it reaches a use, it is considered safe.

In this workshop, we will use CodeQL to analyze a sample of C++ source code that demonstrates simple variants of use-after-free vulnerabilities, and write a CodeQL query to identify the vulnerable pattern with reasonable precision.

## Setup instructions for Visual Studio Code <a id="setupinstructions"></a>

To take part in the workshop you will need to set up a CodeQL development environment. See the [Prerequisites section in the README](README.md#mega-prerequisites) for full instructions.

When you have completed setup, you should have:

1. Installed the Visual Studio Code IDE.
1. Installed the [CodeQL extension for Visual Studio Code](https://help.semmle.com/codeql/codeql-for-vscode.html).
1. Cloned this repository with `git clone --recursive`.
1. Opened this repository in VS Code.
1. Downloaded, imported, and selected the [`codeql-cpp-workshop-uaf`](https://github.com/githubuniverseworkshops/codeql/releases/download/universe-2020/codeql-cpp-workshop-uaf.zip) CodeQL database from within VS Code.
1. A `workshop-2020` folder within your workspace, containing an example query named `example.ql`.
1. A `codeql` folder within your workspace, containing the CodeQL standard libraries for most target languages.
1. A copy of this `workshop.md` guide in your workspace.
1. Open the query `workshop-queries/example.ql` and try running it!

## Workshop <a id="workshop"></a>

### Getting started <a id="section0"></a>

- Use the IDE's autocomplete suggestions (`Ctrl+Space`) and jump-to-definition command (`F12`) to explore the CodeQL libraries.
- To run a query, open the Command Palette (`Cmd+Shift+P` or `Ctrl+Shift+P`), and click **CodeQL: Run Query**. You can also see this command when right-clicking on a query file in the editor.
- Try this out by running the example query `example.ql` in the workshop repository!
- When the query completes, click on the results to jump to the corresponding location in the source code.
- To run a part of a query, such as a single predicate, open the Command Palette and click **CodeQL: Quick Evaluation**. You can also see this command when right-clicking on selected query text in the editor.
- To understand how the source code is represented in the CodeQL libraries, use the **AST Viewer**. You can see this in the left panel of the CodeQL view. Click on a query result to get to a source file, and then click **View AST**, or run **CodeQL: View AST** from the Command Palette.

The rest of the workshop is split into several steps. You can write one query per step, or work with a single query that you refine at each step.

Each step has a **Hint** that describes useful classes and predicates in the CodeQL standard libraries for C/C++ and keywords in CodeQL.

Each step has a **Solution** that indicates one possible answer. Note that all queries will need to begin with `import cpp` to use the standard libraries, but for simplicity this may be omitted below.

### Finding references to freed memory <a id="section1"></a>

1. Find all function call expressions, such as `free(x)` and `use(y, z)`.
    <details>
    <summary>Hint</summary>

    After you have run the example query and clicked on a result, look at the AST Viewer for the `example.cpp` source file.
    A function call is called a `FunctionCall` in the CodeQL C/C++ library.
    </details>
     <details>
    <summary>Solution</summary>

    ```ql
    from FunctionCall call
    select call
    ```
    </details>

1. Identify the expression that is used as the first argument for each call, such as `free(<first arg>)` and `use(<first arg>, z)`.

    <details>
    <summary>Hint</summary>

    - Add another variable to your `from` clause. Declare its type (this can be `Expr`) and give it a name.
    - Add a `where` clause.
    - The AST viewer and autocomplete tell us that `FunctionCall` has a predicate `getArgument(int)` to find the argument at a 0-based index.
    </details>
    <details>
    <summary>Solution</summary>
    
    ```ql
    from FunctionCall call, Expr arg
    where arg = call.getArgument(0)
    select arg
    ```
    </details>

1. Filter your results to only those calls to a function named `free`.

    <details>
    <summary>Hint</summary>

    - `FunctionCall` has a predicate `getTarget()` to find the `Function` being called.
    - A `Function` (and most other named elements) has predicates `getName()` and `hasName(string)` to identify its name as a string.
    - You may also be interested in the predicate `hasGlobalOrStdName(string)`, which identifies named elements from the global or `std` namespaces.
    - Use the `and` keyword to add conditions to your query.
    - If you use `getName()`, use the `=` operator to assert that two values are equal. If you use `has*Name(string)`, passing the name into the predicate makes the assertion.
    </details><details>
    <summary>Solution</summary>
    
    ```ql
    from FunctionCall call, Expr arg
    where
      arg = call.getArgument(0) and
      call.getTarget().hasGlobalOrStdName("free")
    select arg
    ```
    </details>

1. (Bonus) What other operations might free memory? Try looking for `delete` expressions using CodeQL. The example for this workshop only uses `free` but another codebase may use variations of this function name, or use different delete operators.

1. Factor out your logic into a predicate: `predicate isSource(Expr arg) { ... }`.
    <details>
    <summary>Hint</summary>

    - The `predicate` keyword declares a relation that has no explicit result / return value, but asserts a logical property about its variables.
    - The `from` clause of a query allowed you to declare variables,
      and the `where` clause described conditions on those variables.

      Within a predicate definition, variables are either declared as the parameters of the predicate, or 'locally' using the `exists` keyword.
      The first part of the `exists` declares some variables, and the body acts like a `where`, enforcing some conditions on the variables.
      ```ql
      exists(<type> <variableName> |
        // some logic about the variable here
      )
      ```
    - Use **Quick Evaluation** to evaluate the predicate on its own.
    </details>
    <details>
    <summary>Solution</summary>
    
    ```ql
    predicate isSource(Expr arg) {
      exists(FunctionCall call |
        arg = call.getArgument(0) and
        call.getTarget().hasGlobalOrStdName("free")
      )
    }
    ```
    </details>

1. We are going to track the flow of information from the pointer that was freed. For this, we will use the CodeQL library for **data flow analysis**, which helps us answer questions like: does this expression ever hold a value that originates from a particular other place in the program?

    We can visualize the data flow analysis problem as one of finding paths through a directed graph, where the **nodes** of the graph are places in the source code that may have a value, and the **edges** represent the flow of data between those elements. If a path exists, then the data flows between those two nodes.

    The class `DataFlow::Node` describes all data flow nodes. These are different from the abstract syntax tree (AST) nodes, which only represent the structure of the source code. `DataFlow::Node` has various subclasses that describe different types of node, depending on the type of program syntax element they correspond to.

    You can find out more in the [documentation](https://codeql.github.com/docs/codeql-language-guides/analyzing-data-flow-in-cpp).
    
    Modify your predicate to describe `arg` as a `DataFlow::Node`, not an `Expr`.
    <details><summary>Instructions</summary>

    - Add `import semmle.code.cpp.dataflow.DataFlow` to your query file.
    - Change your predicate so that the parameter has type `DataFlow::Node`.
    - This will give you a compile error, since the types no longer match. Convert the data flow node back into an `Expr` using the predicate `asExpr()`.
    </details><details>
    <summary>Solution</summary>
    
    ```ql
    import semmle.code.cpp.dataflow.DataFlow

    predicate isSource(DataFlow::Node arg) {
      exists(FunctionCall call |
        arg.asExpr() = call.getArgument(0) and
        call.getTarget().hasGlobalOrStdName("free")
      )
    }
    ```
    </details>

1. Let's think about the meaning of the `free` function and the value of its argument.

    _Before_ the function runs, the function argument is a pointer to memory, and is passed to the function by reference.

    _After_ the function body, the memory that was referenced by the pointer has been freed.

    So the _one_ expression for the function call argument in the program syntax actually _two_ possible values to think about in the data flow graph:
    1. the pointer before it was freed
    2. the dangling pointer after it was freed.

    Expand the Hint to see how to distinguish between these two cases. Modify your predicate so that `arg` describes the memory _after_ it has been freed, not before.

    <details><summary>Hint</summary>

    - The value before the call is a `DataFlow::ExprNode`, a subtype of `DataFlow::Node`.
    - We can call `asExpr()` on such a node to get the original syntactic expression.

    - The value after the call is a `DataFlow::DefinitionByReferenceNode`.
    - We can call `asDefiningArgument()` on such a node to get the original syntactic expression.
    
    - Jump to the definition of `DataFlow::Node` to read more.

    - Modify your predicate to describe `arg` using `getDefiningArgument()`.

    </details><details>
    <summary>Solution</summary>
    
    ```ql
    predicate isSource(DataFlow::Node arg) {
      exists(FunctionCall call |
        arg.asDefiningArgument() = call.getArgument(0) and
        call.getTarget().hasGlobalOrStdName("free")
      )
    }
    ```
    </details>

### Finding dereferences <a id="section2"></a>

A dereference is a place in the program that uses the memory referenced by a pointer.

1. Write a `predicate isSink(DataFlow::Node sink)` that describes expressions that may be dereferenced.
    <details>
    <summary>Hint</summary>

      - Think of some examples of operations that might dereference a pointer. The `*` operator? Passing it to a function? Performing pointer arithmetic? Use autocomplete or the AST viewer to explore how these are modelled in CodeQL.
      - Search for `dereference` in autocomplete to find a predicate from the standard library that models all these patterns for you.
    </details>
    <details>
    <summary>Solution</summary>
    
    ```ql
    predicate isSink(DataFlow::Node sink) {
      dereferenced(sink.asExpr())
    }
    ```
    </details>

### Finding use-after-free vulnerabilities <a id="section3"></a>

We have now identified (a) places in the program which reference freed memory and (b) places in the program which dereference a pointer to memory. We now want to tie these two together to ask: does a pointer to freed memory ever _flow_ to a potentially unsafe a dereference operation?

This a data flow problem. We could approach it using **local data flow analysis**, whose scope would be limited to a single function. However, it is possible for the free and dereference operations to be in different functions. We call this a **global data flow** problem, and use CodeQL's libraries for this purpose.

In this section we will create a  **path-problem query** capable of looking for global data flow, by populating this template:

```ql
/**
 * @name Use after free
 * @kind path-problem
 * @id cpp/workshop/use-after-free
 */
import cpp
import semmle.code.cpp.dataflow.DataFlow
import DataFlow::PathGraph

class Config extends DataFlow::Configuration {
  Config() { this = "Config: name doesn't matter" }

  /* TODO move over solution from Section 1 */
  override predicate isSource(DataFlow::Node source) {
    exists(/* TODO fill me in from Section 1 */ |
      /* TODO fill me in from Section 1 */
    )
  }

  /* TODO move over solution from Section 2 */
  override predicate isSink(DataFlow::Node sink) {
    /* TODO fill me in from Section 2 **/
  }
}

from Config config, DataFlow::PathNode source, DataFlow::PathNode sink
where config.hasFlowPath(source, sink)
select sink, source, sink, "Memory is $@ and $@, causing a potential vulnerability.", source, "freed here", sink, "used here"
```

1. Fill in or move the `isSource` predicate you wrote for [Section 1](#section1).

1. Fill in or move the `isSink` predicate you wrote for [Section 2](#section2).

1. You can now run the completed query. Use the path explorer in the results view to check the results.

    <details>
    <summary>Completed query</summary>

      ```ql
      /**
       * @name Use after free
       * @kind path-problem
       * @id cpp/workshop/use-after-free
       */
      import cpp
      import semmle.code.cpp.dataflow.DataFlow
      import DataFlow::PathGraph

      class Config extends DataFlow::Configuration {
        Config() { this = "Config: name doesn't matter" }
        override predicate isSource(DataFlow::Node source) {
          exists(FunctionCall call |
            source.asDefiningArgument() = call.getArgument(0) and
            call.getTarget().hasGlobalOrStdName("free")
          )
        }
        override predicate isSink(DataFlow::Node sink) {
          dereferenced(sink.asExpr())
        }
      }

      from Config config, DataFlow::PathNode source, DataFlow::PathNode sink
      where config.hasFlowPath(source, sink)
      select sink, source, sink, "Memory is $@ and $@, causing a potential vulnerability.", source, "freed here", sink, "used here"
      ```
    </details>

1. Bonus: Does your query handle the false positives in the example code? How can we expand it to handle more real-world codebases?

## Follow-up material
- [CodeQL overview](https://codeql.github.com/docs/codeql-overview/)
- [CodeQL for C/C++](https://codeql.github.com/docs/codeql-language-guides/codeql-for-cpp/)
- [Analyzing data flow in C/C++](https://codeql.github.com/docs/codeql-language-guides/analyzing-data-flow-in-cpp/)
- [Using the CodeQL extension for VS Code](https://codeql.github.com/docs/codeql-for-visual-studio-code/)
- CodeQL on [GitHub Learning Lab](https://lab.github.com/search?q=codeql)
- CodeQL on [GitHub Security Lab](https://codeql.com)

## Acknowledgements

This is a modified version of a Capture-the-Flag challenge devised by @kevinbackhouse, available at https://securitylab.github.com/ctf/eko2020.
