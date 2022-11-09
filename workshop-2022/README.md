# CodeQL workshop for Ruby: Finding open URL redirection vulnerabilities

<h5 align="center">@adityasharad and @rvermeulen</h5>

If you are attending this workshop at GitHub Universe, please follow the instructions below to prepare for the workshop in advance.

Closer to the workshop date, the detailed workshop steps will be available below, which the facilitators will guide you through.

## Contents

- Prerequisites and setup instructions
  - [On your local machine](#setup)
  - [On Codespaces](#setup-codespaces)
  - Useful commands
- [Workshop](#workshop)
  - [Section 1: syntactic reasoning](#section1)
  - [Section 2: semantic reasoning](#section2)
  - [Section 3: URL redirection](#section3)

## Prerequisites and setup instructions

### On your local machine <a id="setup"></a>

Please complete this section before the workshop, if possible.

#### Installation
- Install [Visual Studio Code](https://code.visualstudio.com/).
- Install the [CodeQL extension for Visual Studio Code](https://codeql.github.com/docs/codeql-for-visual-studio-code/setting-up-codeql-in-visual-studio-code/).
- You do _not_ need to install the CodeQL CLI: the extension will handle this for you.
- Clone this repository:
  ```
  git clone https://github.com/githubuniverseworkshops/codeql
  ```
  - Use `git pull origin main` to regularly keep this clone up to date with the latest state of the repository.
- Open the repository in Visual Studio Code: **File** > **Open** (or **Open Folder**) > Browse to the checkout of `githubuniverseworkshops/codeql`.
- Follow **Common setup steps (local and Codespaces)** below.

#### Common setup steps (local and Codespaces)
- Import the [CodeQL database](https://github.com/githubuniverseworkshops/codeql/releases/download/universe-2022/codeql-ruby-workshop-opf-openproject.zip) to be used in the workshop:
  - Click the **CodeQL** rectangular icon in the left sidebar.
  - Place your mouse over **Databases**, and click the cloud-shaped icon labelled `Download Database`.
  - Copy and paste this URL into the box, then press **OK**/**Enter**: https://github.com/githubuniverseworkshops/codeql/releases/download/universe-2022/codeql-ruby-workshop-opf-openproject.zip
  - The CodeQL extension will download the CodeQL CLI and the chosen database.
  - After the database is downloaded, it will appear in the left sidebar under **Databases**. Click on the database name, and click **Set Current Database**.
- Install the CodeQL library package for analyzing Ruby code.
  - From the Command Palette (`Cmd/Ctrl+Shift+P`), search for and run the command `CodeQL: Install Pack Dependencies`.
  - At the top of your VS Code window, type `github` in the box to filter the list.
  - Check the box next to `githubuniverseworkshops/codeql-workshop-2022-ruby`.
  - Click **OK**/**Enter**.
- Run a test CodeQL query:
  - Open the file [`workshop-2022/example.ql`](/workshop-2022/example.ql).
  - From the Command Palette (`Cmd/Ctrl+Shift+P`) or the right-click context menu, click the command `CodeQL: Run Query`.
  - After the query compiles and runs, you should see the results in a new `CodeQL Query Results` tab.
- Create a new file in the `workshop-2022` directory called `UrlRedirect.ql`. You'll develop this query during the workshop.

### On Codespaces <a id="setup-codespaces"></a>

- Go to https://github.com/githubuniverseworkshops/codeql/codespaces.
- Click **Create codespace on main**.
- A Codespace will open in a new browser tab.
- When the Codespace is ready, it will open a VS Code workspace file, and prompt you to open this workspace and reload. Accept the prompt. The Codespace will reload.
- After the Codespace reloads, follow **Common setup steps (local and Codespaces)** under [On your local machine](#setup).

### Useful commands
- Run a query using the following commands from the Command Palette (`Cmd/Ctrl + Shift + P`) or right-click menu:
  - `CodeQL: Run Query` (run the entire query)
  - `CodeQL: Quick Evaluation` (run only the selected predicate or snippet)
- Click the links in the query results to navigate to the source code.
- Explore the CodeQL libraries in your IDE using:
  - autocomplete suggestions (`Cmd/Ctrl + Space`)
  - jump-to-definition (`F12`, or `Cmd/Ctrl + F12` in a Codespace in the browser)
  - documentation hovers (place your cursor over an element)
  - the AST viewer on an open source file (`View AST` from the CodeQL sidebar or Command Palette)

## Workshop <a id="workshop"></a>

### Problem statement

In this workshop we will look for _URL redirection vulnerabilities_ in Ruby code that uses the Ruby on Rails framework. Such vulnerabilities can occur in web applications when a URL string that is controlled by an external user makes its way to application code that redirects the current user's browser to the supplied URL.

The example that we will find was a potential vulnerability in the open-source project management software [OpenProject](https://github.com/opf/openproject), which was introduced in a pull request, identified by CodeQL static analysis on the PR, diagnosed during PR review, and fixed before the PR was merged. Note that it remained a potential problem, not a real vulnerability, thanks to the efforts of the project maintainers and a safe default setting built into Rails 7. However, it is a good example to help us understand and detect serious URL redirection vulnerabilities that may occur elsewhere.

(OpenProject is licensed under the [GNU GPL v3.0](https://github.com/opf/openproject/blob/dev/LICENSE).)

The workshop is split into several steps.
You can write one query per step, or work with a single query that you refine at each step. Each step has a **hint** that describes useful classes and predicates in the CodeQL standard libraries for Ruby.

### Section 1: Reasoning about syntactic information<a id="section1"></a>

In this section, we will reason about the abstract syntax tree (AST) of a Ruby program.

We will use this reasoning to identify specific Ruby on Rails method calls, which:
- redirect the application to another URL
- are invoked as part of HTTP `GET` request handler methods configured in the application.

The arguments of these method calls are the URLs being redirected to, and hence are potential **sinks** for URL redirection vulnerabilities.

1. Find all method calls in the program. To reason about the abstract syntax tree (AST) of a Ruby program, start by adding `import ruby` to your CodeQL query, and use the types defined in the `Ast` module.
    <details>
    <summary>Hint</summary>

    - Start typing `from Ast::` to see the types available in the AST library.
    - A method call is represented by the `Ast::MethodCall` type in the CodeQL Ruby library.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import ruby

    from Ast::MethodCall call
    select call
    ```
    </details>

1. Find all calls in the program to methods named `redirect_to`.

    <details>
    <summary>Hint</summary>

    - Add a `where` clause.
    - `MethodCall` has a predicate called `getMethodName()` that returns the method name as a `string`.
    - CodeQL string literals are written in "double quotes".
    - Use the equality operator `=` to assert that two CodeQL expressions are the same.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import ruby

    from Ast::MethodCall redirectCall
    where
      redirectCall.getMethodName() = "redirect_to"
    select redirectCall
    ```
    </details>

1. Calls to the `redirect_to` method use its first argument as the target URL. Update your query to report the redirection argument.

    <details>
    <summary>Hint</summary>

    - `MethodCall.getAnArgument()` returns all possible arguments of the method call.
    - `MethodCall.getArgument(int i)` returns the argument at (0-based) index `i` of the method call.
    - The argument is an _expression_ in the program, represented by the CodeQL class `Ast::Expr`.
    - Introduce a new variable in the `from` clause to hold this expression, and output the variable in the `select` clause.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import ruby

    from Ast::MethodCall redirectCall, Ast::Expr arg
    where
      redirectCall.getMethodName() = "redirect_to" and
      arg = redirectCall.getArgument(0)
    select redirectCall, arg
    ```
    </details>

1. Recall that _predicates_ allow you to encapsulate logical conditions in a reusable format. Convert your previous query to a predicate which identifies the set of expressions in the program which are arguments of `redirect_to` method calls. You can use the following template:
    ```ql
    predicate isRedirect(Ast::Expr redirectLocation) {
      exists(Ast::MethodCall redirectCall |
        // TODO fill me in
      )
    }
    ```
    [`exists`](https://codeql.github.com/docs/ql-language-reference/formulas/#exists) is a mechanism for introducing temporary variables with a restricted scope. You can think of them as their own `from`-`where`-`select`. In this case, we use `exists` to introduce the variable `call` with type `MethodCall`.

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
    import ruby

    predicate isRedirect(Ast::Expr redirectLocation) {
      exists(Ast::MethodCall redirectCall |
        redirectCall.getMethodName() = "redirect_to" and
        redirectLocation = redirectCall.getArgument(0)
      )
    }
    ```

1. When you've written your predicate, you can evaluate it directly using Quick Evaluation (click on the prompt above the predicate name, or right-click on the predicate), or using a query that calls the predicate.

    <details>
    <summary>Solution</summary>

    ```ql
    import ruby

     predicate isRedirect(Ast::Expr redirectLocation) {
      exists(Ast::MethodCall redirectCall |
        redirectCall.getMethodName() = "redirect_to" and
        redirectLocation = redirectCall.getArgument(0)
      )
    }

    from Ast::Expr e
    where isRedirect(e)
    select e
    ```
    </details>

1. Like predicates, _classes_ in CodeQL can be used to encapsulate reusable portions of logic. Classes represent sets of values, and they can also include operations (known as _member predicates_) specific to that set of values. You have already seen some CodeQL classes (`MethodCall`, `Expr` etc.) and associated member predicates (`MethodCall.getMethodName()`, `MethodCall.getArgument(int i)`, etc.).

    `Ast::MethodBase` is the class of all Ruby methods. Create a subclass named `GetHandlerMethod`. To begin with, your subclass will contain all the values from the superclass.

    <details>
    <summary>Hint</summary>

    - Use the `class` keyword to declare a class, and the `extends` keyword to declare the supertypes of your class.
    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import ruby

    class GetHandlerMethod extends Ast::MethodBase {}
    ```
    </details>

1. Ruby on Rails allows developers to define routing logic, describing the various kinds of URL route that are accepted by the Rails application, and which Ruby methods handle HTTP requests to each of those URL routes. The request handlers are Ruby methods in a controller class, usually a subclass of `ActionController`. We want to find all methods that are request handlers for HTTP `GET` requests, because these are potentially susceptible to URL redirection vulnerabilities.

    Refine your class so that it describes only the set of methods that are guaranteed to be request handlers for HTTP `GET` requests in Rails, according to the routing logic written in Ruby code.
    You do not need to identify request handlers yourself: the CodeQL standard library has a module called `ActionController` and a class called `ActionControllerActionMethod` that already do this for you.

    <details>
    <summary>Hint</summary>

    - Add `import codeql.ruby.frameworks.ActionController`. This library helps reason about the Rails `ActionController` class and its subclasses and methods, which define routing and handling for server-side Rails applications.
    - Create a _characteristic predicate_ for your class. This looks like a constructor: `GetHandlerMethod() { ... }`
    - Within the characteristic predicate, use the special `this` variable to refer to the methods whose properties we are describing in the class.
    - Use an _inline cast_ of the form `this.(ActionControllerActionMethod)` to assert that `this` is a public Rails controller method. Then you can call further Rails-specific predicates on this value.
    - Use `ActionControllerActionMethod.getARoute()` to find all URL routes that are directed to this handler, according to the code.
    - Use `Route.getHttpMethod()` to find the HTTP method name (e.g. "get") for a given route.
    - Use Quick Evaluation on the characteristic predicate to see all values of your new class.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import ruby
    import codeql.ruby.frameworks.ActionController

    class GetHandlerMethod extends Ast::MethodBase {
      GetHandlerMethod() {
        this.(ActionControllerActionMethod).getARoute().getHttpMethod() = "get"
      }
    }
    ```
    </details>

1. The previous step only finds handler methods that we know for sure are handling `GET` requests, according to the routes identified in the code by CodeQL. What about handler methods where CodeQL isn't sure about the request type? Let's try and handle those too. Expand your class's characteristic predicate to include handler methods where we cannot statically find a route definition.

    <details>
    <summary>Hint</summary>

    - Use the `or` keyword to expand the set of values that satisfy a logical formula.
    - Use the `not exists` keywords to assert that a logical formula does _not_ hold, or that a particular value does _not_ exist.
    - Use Quick Evaluation on the characteristic predicate to see all values of your new class.

    To view the differences in results, you can select the results of both query runs in the Query History view, right-click and use the `Compare Results` command to
    view the differences.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import ruby
    import codeql.ruby.frameworks.ActionController

    class GetHandlerMethod extends Ast::MethodBase {
      GetHandlerMethod() {
        this.(ActionControllerActionMethod).getARoute().getHttpMethod() = "get"
        or
        not exists(this.(ActionControllerActionMethod).getARoute())
      }
    }
    ```
    </details>

1. The previous step may now find too many possible methods! Limit your class to methods declared within `ActionController` classes.

    <details>
    <summary>Hint</summary>

    - Use the `exists` or `any` quantifiers to declare a variable of type `ActionControllerControllerClass`, and assert that `this` is one of the methods of such a class.
    - Use Quick Evaluation on the characteristic predicate to see all values of your new class.
    - Use the Compare Results command in the Query History view to view the differences in results.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import ruby
    import codeql.ruby.frameworks.ActionController

    class GetHandlerMethod extends Ast::MethodBase {
      GetHandlerMethod() {
        this.(ActionControllerActionMethod).getARoute().getHttpMethod() = "get"
        or
        not exists(this.(ActionControllerActionMethod).getARoute()) and
        this = any(ActionControllerControllerClass c).getAMethod()
      }
    }
    ```
    </details>

1. The previous step may still find too many possible methods! Methods named `create/update/destroy/delete` are probably not HTTP `GET` handlers if we can't find a `GET` route in the code. Exclude them from your class.

    <details>
    <summary>Hint</summary>

    - Use the `and not` keywords to exclude values from a logical formula.
    - Use the `regexpMatch` built-in predicate to match a `string` value using a (Java-style) regular expression. `.*` matches any string pattern. `|` is the alternation/or operator.
    - Use Quick Evaluation on the characteristic predicate to see all values of your new class.
    - Use the Compare Results command in the Query History view to view the differences in results.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import ruby
    import codeql.ruby.frameworks.ActionController

    class GetHandlerMethod extends Ast::MethodBase {
      GetHandlerMethod() {
        this.(ActionControllerActionMethod).getARoute().getHttpMethod() = "get"
        or
        not exists(this.(ActionControllerActionMethod).getARoute()) and
        this = any(ActionControllerControllerClass c).getAMethod() and
        not this.getName().regexpMatch(".*(create|update|destroy).*")
      }
    }
    ```
    </details>

1. Change your `isRedirect` predicate to find redirect calls only within methods we think are HTTP `GET` handlers.

    <details>
    <summary>Hint</summary>

    - Add a parameter to the predicate, and declare its type to be the class you just defined. This states that all values of the parameter must belong to the class.
    - We need to find the enclosing method of either `redirectCall` or `redirectLocation` from the previous predicate. (They should both have the same enclosing method; choose one.)
    - Look for a predicate on `Expr` that finds the enclosing method.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import ruby
    import codeql.ruby.frameworks.ActionController

    class GetHandlerMethod extends Ast::MethodBase {
      GetHandlerMethod() {
        this.(ActionControllerActionMethod).getARoute().getHttpMethod() = "get"
        or
        not exists(this.(ActionControllerActionMethod).getARoute()) and
        this = any(ActionControllerControllerClass c).getAMethod() and
        not this.getName().regexpMatch(".*(create|update|destroy).*")
      }
    }

    predicate isRedirect(Ast::Expr redirectLocation, GetHandlerMethod method) {
      exists(Ast::MethodCall redirectCall |
        redirectCall.getMethodName() = "redirect_to" and
        redirectLocation = redirectCall.getArgument(0) and
        redirectCall.getEnclosingMethod() = method
      )
    }
    ```
    </details>


### Section 2: Reasoning about semantic information<a id="section2"></a>

In this section, we will move from reasoning about the AST to reasoning about data flow.
The data flow graph is built on top of the AST, but contains more detailed semantic information about the flow of information through the program. We will also use more concepts that are already modelled in the CodeQL standard libraries for Ruby, instead of having to manually model each pattern.

1. The `DataFlow` library models the flow of data through the program. This is already imported by `import ruby`, but you can also explicitly import it using `import codeql.ruby.DataFlow`. The class `DataFlow::Node` from this library represents semantic elements in the program that may have a value. Data flow nodes typically have corresponding AST nodes, but we can perform more sophisticated reasoning on the data flow graph. Modify your predicate from the previous section to reason about data flow nodes instead of AST nodes.

    <details>
    <summary>Hint</summary>

     - Change the type of `redirectLocation` from `Ast::Expr` to `DataFlow::Node`. This is the generic type of all data flow nodes. Most nodes correspond to expressions or parameters in the AST.
     - Change the type of `redirectCall` from `Ast::MethodCall` to `DataFlow::CallNode`. This is a more specialised type of data flow node, corresponding to a particular type of expression in the AST -- a `Call`.
    - There are still compilation errors! Methods are a concept in the AST, not the data flow graph. We cannot call `getEnclosingMethod` on a `DataFlow::Node`, so we have to convert it first into an AST node.
    - Use `asExpr()` to convert from a `DataFlow::Node` into a `Cfg::ExprCfgNode` -- this is a type of node in the "control flow" graph.
    - Use `getExpr()` to convert from a `ExprCfgNode` into an `Ast::Expr` -- this is a type of AST node.
    - The rest of the predicate continues to compile without errors. This is because structural predicates like `getArgument` are defined in parallel on both the AST library and the data flow library.
    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import ruby
    import codeql.ruby.frameworks.ActionController

    predicate isRedirect(DataFlow::Node redirectLocation, GetHandlerMethod method) {
      exists(DataFlow::CallNode redirectCall |
        redirectCall.getMethodName() = "redirect_to" and
        redirectLocation = redirectCall.getArgument(0) and
        redirectCall.asExpr().getExpr().getEnclosingMethod() = method
      )
    }
    ```

1. We have manually modelled one method that performs redirects: `redirect_to`. There may be others! Instead of manually modelling each possible case ourselves, let's use the modelling already provided in the CodeQL standard library. The `Concepts` library models common semantic concepts in Ruby programs, such as HTTP requests and responses. Import this library using `import codeql.ruby.Concepts`, and modify your predicate to use its modelling of HTTP redirect responses.

    <details>
    <summary>Hint</summary>

    - Add `import codeql.ruby.Concepts`.
    - Change the type of `redirectCall` to `Http::Server::HttpRedirectResponse`.
    - Remove the logical condition that states the method name of `redirectCall` must be `"redirect_to"`.
    - Use `HttpRedirectResponse.getRedirectLocation()` to identify the redirect URL (previously this was the call argument).

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import ruby
    import codeql.ruby.frameworks.ActionController
    import codeql.ruby.Concepts

    predicate isRedirect(DataFlow::Node redirectLocation, GetHandlerMethod method) {
      exists(Http::Server::HttpRedirectResponse redirectCall |
        redirectCall.getRedirectLocation() = redirectLocation and
        redirectCall.asExpr().getExpr().getEnclosingMethod() = method
      )
    }
    ```
    </details>

1. [`params`](https://api.rubyonrails.org/v7.0.4/classes/ActionController/StrongParameters.html#method-i-params) is a method available on Rails controller classes. It returns a hash (specifically of type [`ActionController::Parameters`](https://guides.rubyonrails.org/action_controller_overview.html#parameters)) that has been instantiated (by Rails) with the parameters of the incoming HTTP request.

    These parameters are a source of remote user input. In the CodeQL standard library for Ruby, they are modelled by the `ParamsSource` class, which is a subclass of the more general `RemoteFlowSource` class.

    Define a new predicate `isSource(DataFlow::Node source)` that describes all **sources** of remote user input in the program.

    <details>
    <summary>Hint</summary>


    - Add `import codeql.ruby.dataflow.RemoteFlowSources`.
    - Use the `RemoteFlowSource` class, which is a type of `DataFlow::Node`.
    - Use the `instanceof` operator to assert that a particular value belongs to a particular class.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
    import codeql.ruby.dataflow.RemoteFlowSources

    predicate isSource(DataFlow::Node source) {
      source instanceof RemoteFlowSource
    }
    ```
    </details>


### Section 3: URL redirection <a id="section3"></a>

We have now identified (a) places in the program which can perform URL redirection within HTTP GET handlers and (b) places in the program which receive untrusted data. We now want to tie these two together to ask: does the untrusted data ever _flow_ to the potentially unsafe URL redirection call?

In program analysis we call this a _data flow_ or _taint tracking_ problem. Data flow helps us answer questions like: does this expression ever hold a value that originates from a particular other place in the program?

We can visualize the data flow problem as one of finding paths through a directed graph, where the nodes of the graph are elements in the program that have a value, and the edges represent the flow of data between those elements. If a path exists, then the data flows between those two nodes.

CodeQL for Ruby provides data flow analysis as part of the standard library. You can import the data flow library using `import ruby` (which in turn imports `codeql.ruby.DataFlow`), and you can import the taint tracking library using `import codeql.ruby.TaintTracking`. Data flow tracks the flow of the same precise values through the program. Taint tracking is less precise, and tracks the flow of values that may change slightly through the program. Both libraries model program elements using the `DataFlow::Node` CodeQL class. These nodes are separate and distinct from the AST (Abstract Syntax Tree) nodes, which represent the basic structure of the program. This allows greater flexibility in how data flow is modeled.

There are a small number of data flow node types – expression nodes and parameter nodes are most common. We have seen the `asExpr()` method to convert a `DataFlow::Node` into the corresponding control flow node and the `getExpr()` method to convert a control flow node into the corresponding AST node; there is also `asParameter()`.

In this section we will create a taint tracking query by populating this template:

```ql
/**
 * @name URL redirection
 * @kind problem
 * @id rb/url-redirection
 */
import ruby
import codeql.ruby.frameworks.ActionController
import codeql.ruby.Concepts
import codeql.ruby.dataflow.RemoteFlowSources
import codeql.ruby.TaintTracking

// TODO add previous class and predicate definitions here

class UrlRedirectionConfig extends TaintTracking::Configuration {
  UrlRedirectionConfig() { this = "UrlRedirectionConfig" }
  override predicate isSource(DataFlow::Node source) {
    /** TODO fill me in **/
  }
  override predicate isSink(DataFlow::Node sink) {
    /** TODO fill me in **/
  }
}

from UrlRedirectionConfig config, DataFlow::Node source, DataFlow::Node sink
where config.hasFlow(source, sink)
select sink, "Potential URL redirection"
```

1. Complete the `isSource` predicate, using the logic you wrote for [Section 2](#section2).

    <details>
    <summary>Solution</summary>

    ```ql
      override predicate isSource(DataFlow::Node source) {
        source instanceof RemoteFlowSource
      }
    ```
    </details>

1. Complete the `isSink` predicate, using the logic you started in [Section 1](#section1) and completed in  [Section 2](#section2). Here, redirect URLs are sinks.
    <details>
    <summary>Hint</summary>

    - Call the `isRedirect` predicate you defined earlier.
    - Use `_` when you don't care about the value of a particular parameter in a predicate call.

    </details>
    <details>
    <summary>Solution</summary>

    ```ql
      override predicate isSink(DataFlow::Node sink) {
        isRedirect(sink, _)
      }
    ```
    </details>

1. You can now run the completed query. You should find exactly one result.

    <details>
    <summary>Solution</summary>

    ```ql
    /**
     * @name URL redirection
     * @kind problem
     * @id rb/url-redirection
     */
    import ruby
    import codeql.ruby.frameworks.ActionController
    import codeql.ruby.Concepts
    import codeql.ruby.dataflow.RemoteFlowSources
    import codeql.ruby.TaintTracking

    class UrlRedirectionConfig extends TaintTracking::Configuration {
      UrlRedirectionConfig() { this = "UrlRedirectionConfig" }
      override predicate isSource(DataFlow::Node source) {
        source instanceof RemoteFlowSource
      }

      override predicate isSink(DataFlow::Node sink) {
        isRedirect(sink, _)
      }
    }

    from UrlRedirectionConfig config, DataFlow::Node source, DataFlow::Node sink
    where config.hasFlow(source, sink)
    select sink, "Potential URL redirection"
    ```
    </details>

1. For some results, it is easy to verify whether the results are valid, because both the source and sink may be in the same method in the code. However, for many data flow problems this is not the case, and the path from source to sink is not always obvious.

    We can update the query so that it not only reports the sink, but it also reports the source and the path to that source. This is done by converting the query to a _path problem_ query. There are five parts we will need to change:
    - Convert the `@kind` from `problem` to `path-problem`. This tells the CodeQL toolchain to interpret the results of this query as path results.
    - Add a new import `import DataFlow::PathGraph`, which will report the path data alongside the query results.
    - Change `source` and `sink` variables from `DataFlow::Node` to `DataFlow::PathNode`, to ensure that the nodes retain path information.
    - Use `hasFlowPath` instead of `hasFlow`.
    - Change the `select` clause to report the `source` and `sink` as the second and third columns. The toolchain combines this data with the path information from `PathGraph` to build the paths.

    Convert your previous query to a path-problem query. Run the query to see the paths in the results view. You should find exactly two results.

    <details>
    <summary>Solution</summary>

    ```ql
    /**
    * @name URL redirection
    * @kind path-problem
    * @id rb/url-redirection
    */
    import ruby
    import codeql.ruby.frameworks.ActionController
    import codeql.ruby.Concepts
    import codeql.ruby.dataflow.RemoteFlowSources
    import codeql.ruby.TaintTracking
    import DataFlow::PathGraph

    class GetHandlerMethod extends MethodBase {
      GetHandlerMethod() {
        this.(ActionControllerActionMethod).getARoute().getHttpMethod() = "get"
        or
        not exists(this.(ActionControllerActionMethod).getARoute()) and
        this = any(ActionControllerControllerClass c).getAMethod() and
        not this.getName().regexpMatch(".*(create|update|destroy).*")
      }
    }

    predicate isRedirect(DataFlow::Node redirectLocation, GetHandlerMethod method) {
      exists(Http::Server::HttpRedirectResponse redirectCall |
        redirectCall.getRedirectLocation() = redirectLocation and
        redirectCall.asExpr().getExpr().getEnclosingMethod() = method
      )
    }

    class UrlRedirectionConfig extends TaintTracking::Configuration {
      UrlRedirectionConfig() { this = "UrlRedirectionConfig" }

      override predicate isSource(DataFlow::Node source) {
        source instanceof RemoteFlowSource
      }
      override predicate isSink(DataFlow::Node sink) {
        isRedirect(sink, _)
      }
    }

    from UrlRedirectionConfig config, DataFlow::PathNode source, DataFlow::PathNode sink
    where config.hasFlowPath(source, sink)
    select sink, source, sink, "Potential URL redirection"
    ```
    </details>

For more information on how this potential vulnerability was identified early and fixed, please read [the discussion in this pull request](https://github.com/opf/openproject/pull/10708#discussion_r892299693). This potential problem never made it into the development branch or production code, thanks to the efforts of the project maintainers, and the codebase was also safe due to the use of Rails 7, which blocks open redirects by default. However, it is a good example to help us understand and detect more serious URL redirection vulnerabilities that may occur elsewhere.

## What's next?
- [CodeQL overview](https://codeql.github.com/docs/codeql-overview/)
- [CodeQL for Ruby](https://codeql.github.com/docs/codeql-language-guides/codeql-for-ruby/)
- [Analyzing data flow in Ruby](https://codeql.github.com/docs/codeql-language-guides/analyzing-data-flow-in-ruby/)
- [Using the CodeQL extension for VS Code](https://codeql.github.com/docs/codeql-for-visual-studio-code/)
- Try out the Capture-the-Flag challenges on the [GitHub Security Lab website](https://securitylab.github.com/ctf)!
- Read about more vulnerabilities found using CodeQL on the [GitHub Security Lab research blog](https://securitylab.github.com/research).
- Explore the [open-source CodeQL queries and libraries](https://github.com/github/codeql), and [learn how to contribute a new query](https://github.com/github/codeql/blob/main/CONTRIBUTING.md).
- [Configure CodeQL code scanning](https://docs.github.com/en/code-security/code-scanning) in your open-source repository.
