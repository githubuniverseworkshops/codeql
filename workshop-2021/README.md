# CodeQL workshop for Java: Unsafe deserialization in Apache Dubbo

<h5 align="center">@adityasharad and @pwntester, moderated by @aeisenberg @jkcso @jf205 @xcorail</h5>

## Prerequisites and setup instructions <a id="setup"></a>

Please complete this section before the workshop, if possible.

- Install [Visual Studio Code](https://code.visualstudio.com/).
- Install the [CodeQL extension for Visual Studio Code](https://codeql.github.com/docs/codeql-for-visual-studio-code/setting-up-codeql-in-visual-studio-code/).
- You do _not_ need to install the CodeQL CLI: the extension will handle this for you.
- Clone this repository:
  ```
  git clone --recursive https://github.com/githubuniverseworkshops/codeql
  ```
  - **Please don't forget `--recursive`:** This allows you to obtain the standard CodeQL query libraries, which are included as a Git submodule of this repository.
  - **What if I forgot to add `--recursive`?** If you've already cloned the repository, please set up the submodule by running:
    ```
    git submodule update --init
    ```
- Open the repository in Visual Studio Code: **File** > **Open** (or **Open Folder**) > Browse to the checkout of `githubuniverseworkshops/codeql`.
- Import the [CodeQL database](https://github.com/githubuniverseworkshops/codeql/releases/download/universe-2021/codeql-java-workshop-apache-dubbo.zip) to be used in the workshop:
  - Click the **CodeQL** rectangular icon in the left sidebar.
  - Place your mouse over **Databases**, and click the icon labelled `Download Database`.
  - Copy and paste this URL into the box, then press **OK**/**Enter**: https://github.com/githubuniverseworkshops/codeql/releases/download/universe-2021/codeql-java-workshop-apache-dubbo.zip
  - Click on the database name, and click **Set Current Database**.
- Create a new file in the `workshop-2021` directory called `UnsafeDeserialization.ql`.

## Overview

- [Prerequisites and setup instructions](#setup)
- [Problem statement](#problemstatement)
- [Documentation links](#documentationlinks)
- [Workshop](#workshop)
  - [Section 1: Finding deserialization](#section1)
  - [Section 2: Find the implementations of the `decodeBody` method from DubboCodec](#section2)
  - [Section 3: Unsafe deserialization](#section3)

## Problem statement <a id="problemstatement"></a>

_Serialization_ is the process of converting in memory objects to text or binary output formats, usually for the purpose of sharing or saving program state. This serialized data can then be loaded back into memory at a future point through the process of _deserialization_.

In languages such as Java, Python and Ruby, deserialization provides the ability to restore not only primitive data, but also complex types such as library and user defined classes. This provides great power and flexibility, but introduces a signficant attack vector if the deserialization happens on untrusted user data without restriction.

[Apache Dubbo](https://dubbo.apache.org/) is a popular open-source RPC framework in Java. In 2021, a researcher from the [GitHub Security Lab](https://securitylab.github.com/) found [multiple vulnerabilities](https://securitylab.github.com/research/apache-dubbo/) leading to remote code execution (RCE) through different deserialization formats.

In this workshop, we will write a query to find variants for [CVE-2020-11995](https://www.cvedetails.com/cve/CVE-2020-11995/) in a database built from the known vulnerable version of Apache Dubbo.

The problem occurred because user-controlled data received by the different network libraries used by Apache Dubbo were deserialized using insecure deserialization formats.

## Documentation links <a id="documentationlinks"></a>
If you get stuck, try searching our documentation and blog posts for help and ideas. Below are a few links to help you get started:
- [CodeQL overview](https://codeql.github.com/docs/codeql-overview/)
- [CodeQL for Java](https://codeql.github.com/docs/codeql-language-guides/codeql-for-java/)
- [Analyzing data flow in Java](https://codeql.github.com/docs/codeql-language-guides/analyzing-data-flow-in-java/)
- [Using the CodeQL extension for VS Code](https://codeql.github.com/docs/codeql-for-visual-studio-code/)
- [GitHub Security Lab research](https://securitylab.github.com/research)
- CodeQL on [GitHub Learning Lab](https://lab.github.com/search?q=codeql)
- For more advanced CodeQL development in future, you may wish to set up the [CodeQL starter workspace](https://codeql.github.com/docs/codeql-for-visual-studio-code/setting-up-codeql-in-visual-studio-code/#using-the-starter-workspace) for all languages.

### Useful commands
- Run a query using the following commands from the Command Palette (`Cmd/Ctrl + Shift + P`) or right-click menu:
  - `CodeQL: Run Query` (run the entire query)
  - `CodeQL: Quick Evaluation` (run only the selected predicate or snippet)
- Click the links in the query results to navigate to the source code.
- Explore the CodeQL libraries in your IDE using:
  - autocomplete suggestions (`Cmd/Ctrl + Space`)
  - jump-to-definition (`F12`, or `Cmd/Ctrl + F12` in a Codespace)
  - documentation hovers (place your cursor over an element)
  - the AST viewer on an open source file (`View AST` from the CodeQL sidebar or Command Palette)

## Workshop <a id="workshop"></a>

The workshop is split into several steps. You can write one query per step, or work with a single query that you refine at each step. Each step has a **hint** that describes useful classes and predicates in the CodeQL standard libraries for Java.

### Section 1: Finding ObjectInput deserialization <a id="section1"></a>

Apache Dubbo uses an [abstraction layer](https://dubbo.apache.org/en/docs/v2.7/dev/impls/serialize/) to wrap multiple deserialization formats. Most of the supported serialization libraries might lead to arbitrary code execution upon deserialization of untrusted data. The SPI interface used for deserialization is called [ObjectInput](https://javadoc.io/doc/org.apache.dubbo/dubbo/latest/com/alibaba/dubbo/common/serialize/ObjectInput.html). It provides multiple `readXXX` methods for deserializing data to a Java object. By default, the input is not validated in any way, and is vulnerable to remote code execution exploits.

In this section, we will identify calls to `ObjectInput.readXXX` methods in the codebase. The qualifiers of these calls are the values being deserialized, and hence are **sinks** for deserialization vulnerabilities.

 1. Find all method calls in the program.
    <details>
    <summary>Hint</summary>

    - A method call is represented by the `MethodAccess` type in the CodeQL Java library.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import java

    from MethodAccess call
    select call
    ```
    </details>

 1. Update your query to report the method being called by each method call.
    <details>
    <summary>Hints</summary>

    - Add a CodeQL variable called `method` with type `Method`.
    - Add a `where` clause.
    - `MethodAccess` has a predicate called `getMethod()` for returning the method.
    - Use the equality operator `=` to assert that two CodeQL expressions are the same.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import java

    from MethodAccess call, Method method
    where call.getMethod() = method
    select call, method
    ```
    </details>

 1. Find all calls in the program to methods starting with `read`.<a id="question1"></a>

    <details>
    <summary>Hint</summary>

    - `Method.getName()` returns a string representing the name of the method.
    - `string.matches("foo%")` can be used to check if a string starts with `foo`.
    - Use the `and` keyword to add multiple conditions to the `where` clause.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import java

    from MethodAccess read, Method method
    where
      read.getMethod() = method and
      method.getName().matches("read%")
    select read
    ```
    </details>

 1. Refine your query to only match calls to `read` methods on classes implementing the `org.apache.dubbo.common.serialize.ObjectInput` interface.<a id="question1"></a>

    <details>
    <summary>Hint</summary>

    - `Method.getDeclaringType()` returns the `RefType` this method is declared on. A `Class` is one kind of `RefType`.
    - `RefType.getASourceSupertype()` returns the immediate parent/supertypes for a given type, as defined in the Java source. (Hover to see the documentation.)
    - Use the "reflexive transitive closure" operator `*` on a call to a predicate with 2 arguments, e.g. `getASourceSupertype*()`, to apply the predicate 0 or more times in succession.
    - `RefType.hasQualifiedName("package", "class")` holds if the given `RefType` has the fully-qualified name `package.class`.
    For example, the query
      ```ql
      from RefType r
      where r.hasQualifiedName("java.lang", "String")
      select r
      ```
      will find the type `java.lang.String`.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import java

    from MethodAccess read, Method method
    where
      read.getMethod() = method and
      method.getName().matches("read%") and
      method.getDeclaringType().getASourceSupertype*().hasQualifiedName("org.apache.dubbo.common.serialize", "ObjectInput")
    select read
    ```
    </details>
  
 1. The `ObjectInput.readXXX` methods deserialize the qualifier argument (i.e. the `this` argument, or the object before the `.`). Update your query to report the deserialized argument.

    <details>
    <summary>Hint</summary>

    - `MethodAccess.getQualifier()` returns the qualifier of the method call.
    - The qualifier is an _expression_ in the program, represented by the CodeQL class `Expr`.
    - Introduce a new variable in the `from` clause to hold this expression, and output the variable in the `select` clause.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import java

    from MethodAccess read, Method method, Expr qualifier
    where
      read.getMethod() = method and
      method.getName().matches("read%") and
      method.getDeclaringType().getASourceSupertype*().hasQualifiedName("org.apache.dubbo.common.serialize", "ObjectInput") and
      qualifier = read.getQualifier()
    select read, qualifier
    ```
    </details>

 1. Recall that _predicates_ allow you to encapsulate logical conditions in a reusable format. Convert your previous query to a predicate which identifies the set of expressions in the program which are deserialized directly by `ObjectInput.readXXX` methods. You can use the following template:
    ```ql
    predicate isDeserialized(Expr arg) {
      exists(MethodAccess read, Method method |
        // TODO fill me in
      )
    }
    ```
    [`exists`](https://codeql.github.com/docs/ql-language-reference/formulas/#exists) is a mechanism for introducing temporary variables with a restricted scope. You can think of them as their own `from`-`where`-`select`. In this case, we use `exists` to introduce the variable `read`  with type `MethodAccess`, and the variable `method` with type `Method`.

    <details>
    <summary>Hint</summary>

     - You can translate from the previous query clause to a predicate by:
       - Converting some variable declarations in the `from` part to the variable declarations of an `exists`
       - Placing the `where` clause conditions (if any) in the body of the exists
       - Adding a condition which equates the `select` to one of the parameters of the predicate.
    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import java

    predicate isDeserialized(Expr qualifier) {
      exists(MethodAccess read, Method method |
        read.getMethod() = method and
        method.getName().matches("read%") and
        method.getDeclaringType().getASourceSupertype*().hasQualifiedName("org.apache.dubbo.common.serialize", "ObjectInput") and
        qualifier = read.getQualifier()
      )
    }

    from Expr arg
    where isDeserialized(arg)
    select arg
    ```

### Section 2: Find the implementations of the decodeBody method from DubboCodec<a id="section2"></a>

Classes that implement the interface `org.apache.dubbo.remoting.Codec2` process user input in their `decodeBody` methods. In this section we will find these methods and their parameters, which are **sources** of untrusted user input.

Like predicates, _classes_ in CodeQL can be used to encapsulate reusable portions of logic. Classes represent sets of values, and they can also include operations (known as _member predicates_) specific to that set of values. You have already seen numerous instances of CodeQL classes (`MethodAccess`, `Method` etc.) and associated member predicates (`MethodAccess.getMethod()`, `Method.getName()`, etc.).

 1. Create a CodeQL class called `DubboCodec` to find the interface `org.apache.dubbo.remoting.Codec2`. You can use this template:
    ```ql
    class DubboCodec extends RefType {
      // Characteristic predicate
      DubboCodec() {
          // TODO Fill me in
      }
    }
    ```

    <details>
    <summary>Hint</summary>

    - Use `RefType.hasQualifiedName("package", "class")` to identify classes with the given package name and class name.
    - Within the characteristic predicate, use the special variable `this` to refer to the `RefType` we are describing.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import java

    /** The interface `org.apache.dubbo.remoting.Codec2`. */
    class DubboCodec extends RefType {
      DubboCodec() {
        this.hasQualifiedName("org.apache.dubbo.remoting", "Codec2")
      }
    }
    ```
    </details>

 2. Create a CodeQL class called `DubboCodecDecodeBody` for identfying `Method`s called `decodeBody` on classes whose direct super-types include `DubboCodec`.

    <details>
    <summary>Hint</summary>

    - Use `Method.getName()` to identify the name of the method.
    - To identify whether the method is declared on a class whose direct super-type includes `DubboCodec`, you will need to:
      - Identify the declaring type of the method using `Method.getDeclaringType()`.
      - Identify the super-types of that type using `RefType.getASuperType()`
      - Use `instanceof` to assert that one of the super-types is a `DubboCodec`

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    /** A `decodeBody` method on a subtype of `org.apache.dubbo.remoting.Codec2`. */
    class DubboCodecDecodeBody extends Method {
      DubboCodecDecodeBody() {
        this.getDeclaringType().getASupertype*() instanceof DubboCodec and
        this.hasName("decodeBody")
      }
    }
    ```
    </details>

 3. `decodeBody` methods should consider the second and third parameters as untrusted user input. Add a member predicate to your `DubboCodecDecodeBody` class that finds these parameters of `decodeBody` methods.
    <details>
    <summary>Hint</summary>

    - Create a predicate `Parameter getAnUntrustedParameter() { ... } ` within the class. This has result type `Parameter`.
    - Within the predicate, use the special variable `result` to refer to the values to be "returned" or identified by the predicate.
    - Within the predicate, use the special variable `this` to refer to the `DubboCodecDecodeBody` method.
    - Use `Method.getParameter(int index)` to get the `i`-th index parameter. Indices are 0-based, so we want index 1 and index 2 here.
    - Use Quick Evaluation to run your predicate.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    class DubboCodecDecodeBody extends Method {
      DubboCodecDecodeBody() {
        this.getDeclaringType().getASupertype*() instanceof DubboCodec and
        this.hasName("decodeBody")
      }

      Parameter getAnUntrustedParameter() { result = this.getParameter([1, 2]) }
    }
    ```
    </details>

### Section 3: Unsafe deserialization <a id="section3"></a>

We have now identified (a) places in the program which receive untrusted data and (b) places in the program which potentially perform unsafe deserialization. We now want to tie these two together to ask: does the untrusted data ever _flow_ to the potentially unsafe deserialization call?

In program analysis we call this a _data flow_ problem. Data flow helps us answer questions like: does this expression ever hold a value that originates from a particular other place in the program?

We can visualize the data flow problem as one of finding paths through a directed graph, where the nodes of the graph are elements in program, and the edges represent the flow of data between those elements. If a path exists, then the data flows between those two nodes.

Consider this example Java method:

```c
int func(int tainted) {
   int x = tainted;
   if (someCondition) {
     int y = x;
     callFoo(y);
   } else {
     return x;
   }
   return -1;
}
```
The data flow graph for this method will look something like this:

<img src="https://help.semmle.com/QL/ql-training/_images/graphviz-2ad90ce0f4b6f3f315f2caf0dd8753fbba789a14.png" alt="drawing" width="260"/>

This graph represents the flow of data from the tainted parameter. The nodes of graph represent program elements that have a value, such as function parameters and expressions. The edges of this graph represent flow through these nodes.

CodeQL for Java provides data flow analysis as part of the standard library. You can import it using `semmle.code.java.dataflow.DataFlow` or `semmle.code.java.dataflow.TaintTracking`. The library models nodes using the `DataFlow::Node` CodeQL class. These nodes are separate and distinct from the AST (Abstract Syntax Tree, which represents the basic structure of the program) nodes, to allow for flexibility in how data flow is modeled.

There are a small number of data flow node types – expression nodes and parameter nodes are most common. We can use the `asExpr()` and `asParameter()` methods to convert a `DataFlow::Node` into the corresponding AST node.

In this section we will create a data flow query by populating this template:

```ql
/**
 * @name Unsafe deserialization
 * @kind problem
 * @id java/unsafe-deserialization
 */
import java
import semmle.code.java.dataflow.TaintTracking

// TODO add previous class and predicate definitions here

class DubboUnsafeDeserializationConfig extends TaintTracking::Configuration {
  DubboUnsafeDeserializationConfig() { this = "DubboUnsafeDeserializationConfig" }
  override predicate isSource(DataFlow::Node source) {
    exists(/** TODO fill me in **/ |
      source.asParameter() = /** TODO fill me in **/
    )
  }
  override predicate isSink(DataFlow::Node sink) {
    exists(/** TODO fill me in **/ |
      sink.asExpr() = /** TODO fill me in **/
    )
  }
  override predicate isAdditionalTaintStep(DataFlow::Node n1, DataFlow::Node n2) {
      /** TODO fill me in **/
  }
}

from DubboUnsafeDeserializationConfig config, DataFlow::Node source, DataFlow::Node sink
where config.hasFlow(source, sink)
select sink, "Unsafe deserialization"
```

 1. Complete the `isSource` predicate, using the logic you wrote for [Section 2](#section2).

    <details>
    <summary>Hint</summary>

    - Remember the `DubboCodecDecodeBody` class and `getAnUntrustedParameter` predicate you defined earlier.
    - Use `asParameter()` to convert a `DataFlow::Node` into a `Parameter`.
    - Use `exists` to declare new variables, and `=` to assert that two values are the same.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
      override predicate isSource(DataFlow::Node source) {
        exists(DubboCodecDecodeBody decodeBodyMethod |
          source.asParameter() = decodeBodyMethod.getAnUntrustedParameter()
      }
    ```
    </details>

 1. Complete the `isSink` predicate, using the logic you wrote for [Section 1](#section1).
    <details>
    <summary>Hint</summary>

    - Complete the same process as above.
    - Remember the `isDeserialized` predicate you defined earlier.
    - Use `asExpr()` to convert a `DataFlow::Node` into an `Expr`.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
      override predicate isSink(DataFlow::Node sink) {
        isDeserialized(sink.asExpr())
      }
    ```
    </details>

 1. Teach CodeQL about extra data flow steps that it should follow. Complete the `isAdditionalTaintStep` predicate by modelling the `Serialization.deserialize()` method, which connects its _first argument_ with the _return value_.
    <details>
    <summary>Hint</summary>

    - As before, use `exists` to declare new variables, `asExpr()` to convert from `DataFlow::Node` to `Expr`,
      and `=` to assert equality.
    - `isAdditionalTaintStep` has two arguments: the node where data starts, and the node where data ends.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
      override predicate isAdditionalTaintStep(DataFlow::Node n1, DataFlow::Node n2) {
        exists(MethodAccess ma |
          ma.getMethod().getName() = "deserialize" and
          ma.getMethod().getDeclaringType().getName() = "Serialization" and
          
          ma.getArgument(1) = n1.asExpr() and
          ma = n2.asExpr()
        )
      }
    ```
    </details>

You can now run the completed query. You should find exactly eleven results, which will include the original CVE-2020-11995 but also new variants that were reported by our security researchers!

For some results, it is easy to verify that it is correct, because both the source and sink are may be in the same method. However, for many data flow problems this is not the case.

We can update the query so that it not only reports the sink, but it also reports the source and the path to that source. We can do this by making these changes:
The answer to this is to convert the query to a _path problem_ query. There are five parts we will need to change:
 - Convert the `@kind` from `problem` to `path-problem`. This tells the CodeQL toolchain to interpret the results of this query as path results.
 - Add a new import `DataFlow::PathGraph`, which will report the path data alongside the query results.
 - Change `source` and `sink` variables from `DataFlow::Node` to `DataFlow::PathNode`, to ensure that the nodes retain path information.
 - Use `hasFlowPath` instead of `hasFlow`.
 - Change the `select` clause to report the `source` and `sink` as the second and third columns. The toolchain combines this data with the path information from `PathGraph` to build the paths.

 3. Convert your previous query to a path-problem query. Run the query to see the paths in the results view.
    <details>
    <summary>Solution</summary>

    ```ql
    /**
    * @name Unsafe deserialization
    * @kind path-problem
    * @id java/unsafe-deserialization
    */
    import java
    import semmle.code.java.dataflow.TaintTracking
    import DataFlow::PathGraph

    predicate isDeserialized(Expr qualifier) {
      exists(MethodAccess read, Method method |
        read.getMethod() = method and
        method.getName().matches("read%") and
        method.getDeclaringType().getASourceSupertype*().hasQualifiedName("org.apache.dubbo.common.serialize", "ObjectInput") and
        qualifier = read.getQualifier()
      )
    }

    /** The interface `org.apache.dubbo.remoting.Codec2`. */
    class DubboCodec extends RefType {
      DubboCodec() {
        this.hasQualifiedName("org.apache.dubbo.remoting", "Codec2")
      }
    }

    /** A `decodeBody` method on a subtype of `org.apache.dubbo.rpc.protocol.dubbo.DubboCodec`. */
    class DubboCodecDecodeBody extends Method {
      DubboCodecDecodeBody() {
        this.getDeclaringType().getASupertype*() instanceof DubboCodec and
        this.hasName("decodeBody")
      }

      Parameter getAnUntrustedParameter() {
        result = this.getParameter([1, 2])
      }
    }

    class DubboUnsafeDeserializationConfig extends TaintTracking::Configuration {
      DubboUnsafeDeserializationConfig() { this = "DubboUnsafeDeserializationConfig" }
      override predicate isSource(DataFlow::Node source) {
        exists(DubboCodecDecodeBody decodeBodyMethod |
          source.asParameter() = decodeBodyMethod.getAnUntrustedParameter()
        )
      }
      override predicate isSink(DataFlow::Node sink) {
        isDeserialized(sink.asExpr())
      }
      override predicate isAdditionalTaintStep(DataFlow::Node n1, DataFlow::Node n2) {
        exists(MethodAccess ma |
          ma.getMethod().getName() = "deserialize" and
          ma.getMethod().getDeclaringType().getName() = "Serialization" and
          
          ma.getArgument(1) = n1.asExpr() and
          ma = n2.asExpr()
        )
      }
    }

    from DubboUnsafeDeserializationConfig config, DataFlow::PathNode source, DataFlow::PathNode sink
    where config.hasFlowPath(source, sink)
    select sink, source, sink, "Unsafe deserialization"
    ```
    </details>

For more information on how the vulnerability was identified, read the [blog post on the original problem](https://securitylab.github.com/research/apache-dubbo/).

## What's next?
- [CodeQL overview](https://codeql.github.com/docs/codeql-overview/)
- [CodeQL for Java](https://codeql.github.com/docs/codeql-language-guides/codeql-for-java/)
- [Analyzing data flow in Java](https://codeql.github.com/docs/codeql-language-guides/analyzing-data-flow-in-java/)
- [Using the CodeQL extension for VS Code](https://codeql.github.com/docs/codeql-for-visual-studio-code/)
- Try out the latest CodeQL Java Capture-the-Flag challenge on the [GitHub Security Lab website](https://securitylab.github.com/ctf) for a chance to win a prize! Or try one of the older Capture-the-Flag challenges to improve your CodeQL skills.
- Read about more vulnerabilities found using CodeQL on the [GitHub Security Lab research blog](https://securitylab.github.com/research).
- Explore the [open-source CodeQL queries and libraries](https://github.com/github/codeql), and [learn how to contribute a new query](https://github.com/github/codeql/blob/main/CONTRIBUTING.md).
- [Configure CodeQL code scanning](https://docs.github.com/en/code-security/code-scanning) in your open-source repository.
