#About cococahub

cocoahub is a simple web server written in Objective-C that serves two purposes:

* Relay HTTP requests received on your Mac server to standalone HTTP requests handlers ( more commonly called CGIs) written in Objective-C .
* Automatically build and install HTTP custom CGI's on your Mac server when a change notification/service hook from GitHub is received.

It's built on top of [CocoaHTTPServer](https://github.com/robbiehanson/CocoaHTTPServer) using [CocoaPods](http://cocoapods.org). It also handles your custom CGI's written with CocoaPods nicely.

# Motivation

I'm bad when it comes to writing code in any of the modern scripting languages (e.g. Python, Ruby, JavaScript). It's not only my poor knowledge of these languages, but also my little understanding of the respective software stacks required to deploy them, that makes me feel powerless.

My goal with cocoahub is to come up with something simple to install and maintain, that helps me stay in control of my web apps. Since cocoahub is almost entirely Cocoa-based, I feel at home and in charge.

# Features

##Automatic deployment with GitHub

cocoahub will automatically build and deploy your projects hosted on GitHub, once a change notification from GitHub is received. Here is what's required for this feature to work:

* your CGI's code needs to be hosted on GitHub
* your project's sources need to be checked out on your server in cocoahub's source directory (see configuration)
* configure your project's setting on repo to send notification on your server's public IP via its GitHub listening port (see configuration) 


## CocoaPods support

If you are using CocoaPods in your HTTP request handlers, cocoahub will update the configured CocoaPods when building your CGI. A working CocoaPods installation is required on your server.

# Server Requirements

* Xcode (tested with 4.6 and later)
* OS X 10.7 or later
* two open ports that are reachable from the internet (one is for receiving HTTP requests and dispatching them to installed CGIs, the other is for listening to change notifications from GitHub)(see configuration)
* if you are using CocoaPods in your CGIs or if you want to compile the cocoahub server from source, you need a working CocoaPods installation

# Installing

* checkout the cocoahub sources on your server
* run the 'pod install' command
* run '.\build+run.sh' to start the server

# Configuring cocoahub

Right now there are only 4 settings that can be configured. You can place a 'cocahub.conf' file next to your cocoahub binary and specify them:

```
# the directory you you have your CGIs checked out in
repoDir: ~/source

# the directory where the built CGIs are copied to and launched from
cgiDir: ~/cgi-bin

# the port on which the server accepts incoming http requests for your CGIs
httpPort: 3002

# the port on which the server waits for incoming change notifications from GitHub
githubPort: 3001
```

If no 'cocahub.conf' is found, the default values shown above will be used.

# Adding CGIs to your cocoahub setup

So the documentation at [CHCGI] https://github.com/iwascoding/CHCGI for more details. There is also a sample CGI implementation available [here](https://github.com/iwascoding/cocoahubSampleCGI).


# How dispatching HTTP Request works

Right now the dispatch logic is quite simple: The name of the first path component of the requested URL has to match the name of an installed CGI.


# Limitations

* Cocoahub hasn't seen any production use so far. Consider it alpha quality, and use it carefully.
* Communication between cocoahub and CGIs happens through Common gateway interface (and right now it's now even fully supported). If you are a looking for maximum performance, please consider adding FastCGI or XPC channels.  


# Contributing

Contributions are more then welcome. For starters, just search for 'TODO' in the source code.

# License

cocoahub is licensed under the MIT license, which is reproduced in its entirety here:

>Copyright (c) 2013 iwascoding GmbH
>
>Permission is hereby granted, free of charge, to any person obtaining a copy
>of this software and associated documentation files (the "Software"), to deal
>in the Software without restriction, including without limitation the rights
>to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
>copies of the Software, and to permit persons to whom the Software is
>furnished to do so, subject to the following conditions:
>
>The above copyright notice and this permission notice shall be included in
>all copies or substantial portions of the Software.
>
>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
>IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
>FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
>AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
>LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
>OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
>THE SOFTWARE., EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.