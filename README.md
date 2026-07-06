# ImageTrans_wsServer

ImageTrans websocket server written in B4J.

It receives image translation requests and calls an ImageTrans instance connected via WebSocket to do the heavy processing.

It can be used with [ImageTrans_chrome_extension](https://github.com/xulihang/ImageTrans_chrome_extension) to translate images on websites.

The [image-translation-server](https://github.com/xulihang/image-translation-server) is written in Python and provides the same set of APIs. However, it starts ImageTrans via command line instead of using WebSocket to connect to a running instance.


