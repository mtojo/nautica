import asyncdispatch, asynchttpserver, asyncnet, parseopt2, rawsockets

import nauticapkg/logging
import nauticapkg/request
import nauticapkg/response
import nauticapkg/router
import nauticapkg/staticProvider

export asyncdispatch
export asynchttpserver.HttpCode
export rawsockets

export request
export response

#
# Constants
#

const version* = "0.1.0"

#
# Types
#

type
  Action* = proc (req: request.Request, res: Response): Future[void] {.closure,gcsafe.}

  App* = ref object
    server: AsyncHttpServer
    router: Router[Action]
    actions: seq[Action]

#
# Application
#

proc newApp*(reuseAddr = true): App =
  logger.info("nautica", "Powered by Nautica $1", version)
  new result
  result.server = newAsyncHttpServer(reuseAddr)
  result.router = newRouter[Action]()
  newSeq result.actions, 0

proc use*(app: App, action: Action) =
  app.actions.add(action)

proc all*[T](app: App, pattern: T, action: Action) =
  app.router.connect(Method.Any, pattern, action)

proc get*[T](app: App, pattern: T, action: Action) =
  app.router.connect(Method.Get, pattern, action)

proc post*[T](app: App, pattern: T, action: Action) =
  app.router.connect(Method.Post, pattern, action)

proc put*[T](app: App, pattern: T, action: Action) =
  app.router.connect(Method.Put, pattern, action)

proc delete*[T](app: App, pattern: T, action: Action) =
  app.router.connect(Method.Delete, pattern, action)

proc handleRequest(app: App, asyncReq: asynchttpserver.Request): Future[void] =
  logger.debug("nautica", "handleRequest: $1", $asyncReq.url.path)
  var req = newRequest(asyncReq)
  var res = newResponse(asyncReq)
  for action in app.actions:
    var f = action(req, res)
    if f != nil:
      asyncCheck f
    if res.isClosed:
      return
  var c = app.router.handle(req)
  if c.value != nil:
    req.params = c.params
    return c.value(req, res)
  else:
    return res.respond(Http404, $Http404)

proc serve*(app: App, port: Port, address = "") {.async.} =
  var server = newAsyncHttpServer()
  proc cb(req: asynchttpserver.Request) {.async.} =
    await app.handleRequest(req)
  logger.info("nautica", "Server running at http://127.0.0.1:$1/", $port)
  asyncCheck server.serve(port, cb, address)

#
# Middlewares
#

proc staticProvider*(dir: string): Action =
  var provider = newStaticProvider(dir)
  return proc (req: request.Request, res: Response): Future[void] =
    return provider.serve(req, res)

proc xPoweredBy*(req: request.Request, res: Response): Future[void] {.procvar.} =
  res.addHeader("X-Powered-By", "Nautica " & version)

#
# Simple static server
#

when not defined(test) and isMainModule:
  proc writeHelp =
    echo "nautica [dir]"

  proc writeVersion =
    echo "Nautica ", version

  proc serve(dir: string) =
    var app = newApp()
    app.use(xPoweredBy)
    app.use(staticProvider(dir))
    asyncCheck app.serve(Port(3000))
    runForever()

  proc main =
    var dir = ""
    for kind, key, val in getopt():
      case kind
      of cmdArgument:
        dir = key
      of cmdLongOption, cmdShortOption:
        case key
        of "help", "h":
          writeHelp()
          return
        of "version", "v":
          writeVersion()
          return
      of cmdEnd: assert(false)
    if dir != "":
      serve(dir)
    else:
      writeHelp()

  main()
