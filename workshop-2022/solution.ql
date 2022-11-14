/**
 * @name URL redirection
 * @kind path-problem
 * @id rb/workshop/url-redirection
 */
import ruby
import codeql.ruby.frameworks.ActionController
import codeql.ruby.Concepts
import codeql.ruby.dataflow.RemoteFlowSources
import codeql.ruby.TaintTracking
import DataFlow::PathGraph

/**
 * Holds if `redirectLocation` is the target of a URL redirect call
 * within a Rails application and `method` is the HTTP request handler
 * method enclosing the call.
 */
predicate isRedirect(DataFlow::Node redirectLocation, GetHandlerMethod method) {
  exists(Http::Server::HttpRedirectResponse redirectCall |
    redirectCall.getRedirectLocation() = redirectLocation and
    redirectCall.asExpr().getExpr().getEnclosingMethod() = method
  )
}

/**
 * A method in a Rails `ActionController` subclass that is likely
 * to be the target of a route handler for an HTTP `GET` request.
 */
class GetHandlerMethod extends Ast::MethodBase {
  GetHandlerMethod() {
    this.(ActionControllerActionMethod).getARoute().getHttpMethod() = "get"
    or
    not exists(this.(ActionControllerActionMethod).getARoute()) and
    exists(ActionControllerControllerClass c | this = c.getAMethod()) and
    not this.getName().regexpMatch(".*(create|update|destroy|delete).*")
  }
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
select sink, source, sink, "Potential URL redirection from $@", source, "this source"