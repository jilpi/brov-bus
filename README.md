#brov-bus#
##Project##
Part of the "brov" project.

We are developping a submarine "ROV" (remotely operated vehicule) based on
[BlueRobotics' BlueROV][bluerov].

The main application can be found [here][brov-app].

##Description##
Node.js module, offering an anonynous "publisher-subscriber" communication bus.

Communication through the bus can be performed by "registering" listeners, by providing
a callback, and "getting" publisher objects.

##Installation##
To install the latest version directly from github:

```bash
npm install https://github.com/jilpi/brov-bus/archive/master.tar.gz
```

TODO: Publish the package on npmjs.org.

If you don't have it already, you should also have ZeroMQ 3 or 4 installed on your system.

On Debian / Raspbian / Ubuntu:
```bash
sudo apt-get install libzmq3-dev
```

##Usage##
```coffee
# //usage.js
Bus = require('@jilpi/brov-bus')

# Create a new bus
bus = new Bus 'zmq'

# Create and bind a publisher
publisher = bus.getPublisher()

# Create and bind a subscriber
subscriberCallback = (err, filter, message)->
  return if err?
  console.log "Message received! Contains: #{message} (filter was: #{filter})"

bus.registerSubscriber subscriberCallback

publisher.send("FOO", "BAR")
```
```bash
$ node usage.js
Message received! Contains: BAR (filter was: FOO)
```

##Principle##
The BrovBus class creates a bus using an underlying library, and expose methods to
bind publishers / subscribers to that bus.

It also defines a standard Publisher class, that offer an abstraction layer
between publishers and the bus' underlying librairy, by exposing a standard 
send(class, content) method. Different underlying librairy will expose different
Publisher class.

##Supported libraries##
Currently, BrovBus supports:

* [ZeroMQ][zmq]

Under development:

* [events][events]

##Documentation##
Documentation is generated automatically with [codo][codo] and can be found in the
/doc folder of the repository.

You can also check it online [here][doc] thanks to [Rawgit][rawgit].


[codo]: https://github.com/coffeedoc/codo
[zmq]: http://zeromq.org/
[events]: https://nodejs.org/api/events.html
[bluerov]: http://docs.bluerobotics.com/bluerov/
[brov-app]: https://github.com/jilpi/brov-app
[doc]: https://cdn.rawgit.com/jilpi/brov-bus/master/doc/index.html
[rawgit]: http://www.rawgit.com/
