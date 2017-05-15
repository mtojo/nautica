import asynchttpserver, asyncdispatch, re, strtabs, strutils
import logging, request, response

type
  Method* {.pure.} = enum
    Any = "*",
    Delete = "delete",
    Get = "get",
    Post = "post",
    Put = "put"

  Router*[T] = ref object
    staticRoutes: seq[tuple[reqMethod, path: string, value: T]]
    routes: seq[tuple[reqMethod: string, pattern: Regex, value: T, names: seq[string]]]

proc newRouter*[T](): Router[T] =
  new result
  newSeq result.staticRoutes, 0
  newSeq result.routes, 0

proc connect[T](router: Router[T], reqMethod: string, pattern: Regex, value: T,
                names: seq[string] = nil) =
  router.routes.add((reqMethod, pattern, value, names))

proc connect*[T](router: Router[T], reqMethod: Method, pattern: string, value: T) =
  logger.info("nautica", "Connect: $1 $2", reqMethod, pattern)

  # Statically path specialization
  if pattern.find(':') == -1:
    router.staticRoutes.add(($reqMethod, pattern, value))
    return

  # Compile pattern
  var components, names: seq[string]
  newSeq components, 0
  newSeq names, 0
  for component in pattern.split('/'):
    if component[0] == ':':
      components.add("([^\\/]+)")
      names.add(component.substr(1))
    else:
      components.add(escapeRe(component))
  router.connect($reqMethod, re.re("^" & components.join("\\/") & "\\/?$"), value, names)

proc connect*[T](router: Router[T], reqMethod: Method, pattern: Regex, value: T) =
  logger.info("nautica", "Connect: $1 (Regex)", reqMethod)
  router.connect($reqMethod, pattern, value)

proc handle[T](router: Router[T], reqMethod, path: string): tuple[value: T, params: StringTableRef] =
  logger.debug("nautica", "Route: $1 $2", reqMethod, path)

  for route in router.staticRoutes:
    if (route.reqMethod == "*" or reqMethod == route.reqMethod) and
       path == route.path:
      return (route.value, nil)

  var matches: array[MaxSubpatterns, string]
  for route in router.routes:
    if (route.reqMethod == "*" or reqMethod == route.reqMethod) and
       path.match(route.pattern, matches):
      var params = newStringTable()
      if route.names == nil:
        for i in 0..matches.len - 1:
          strtabs.`[]=`(params, $i, matches[i])
      else:
        for i in 0..route.names.len - 1:
          strtabs.`[]=`(params, route.names[i], matches[i])
      return (route.value, params)

proc handle*[T](router: Router[T], reqMethod: Method, path: string): tuple[value: T, params: StringTableRef] =
  router.handle($reqMethod, path)

proc handle*[T](router: Router[T], req: request.Request): tuple[value: T, params: StringTableRef] =
  router.handle($req.reqMethod, req.url.path)
