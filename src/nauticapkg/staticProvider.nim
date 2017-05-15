import asyncdispatch, asynchttpserver, asyncnet
import os, rawsockets, streams, strtabs, times
import logging, request, response

type
  StaticProvider* = ref object
    root: string

proc newStaticProvider*(root: string): StaticProvider =
  new result
  result.root = expandFilename(root)

proc serve*(provider: StaticProvider, req: request.Request,
            res: Response): Future[void] =
  var fullPath = joinPath(provider.root, req.url.path)

  if not existsFile(fullPath): return

  if extractFilename(fullPath)[0] == '.':
    return res.respond(Http403, $Http403)

  try:
    var fileInfo = getFileInfo(fullPath)
    var lastModified = fileInfo.lastWriteTime.getGMTime

    var ifModifiedSince = req.headers["if-modified-since"]
    if ifModifiedSince.len > 0 and
       parse(ifModifiedSince, "ddd',' dd MMM yyyy HH:mm:ss ZZZ").toTime >= lastModified.toTime:
      return res.respond(Http304, "")

    res.status(Http200)
    res.addHeader("Last-Modified",
                  format(lastModified,
                         "ddd',' dd MMM yyyy HH:mm:ss 'UTC'"))
    res.addHeader("Content-Length", $fileInfo.size)

    let strm = newFileStream(fullPath, fmRead)
    defer: close(strm)

    while true:
      let line = readStr(strm, 32 * 1024)
      if line.len == 0: break
      asyncCheck res.send(line)

  except:
    logger.error("nautica", "Error: ", getCurrentExceptionMsg())
    return res.respond(Http403, $Http403)
