###
Abstraction layer between the Publisher using the bus and the underlying library.

@author Jean-Laurent Picard <jean.laurent.picard at gmail>
###
class Publisher
  get = (props) => @::__defineGetter__ name, getter for name, getter of props
  #set = (props) => @::__defineSetter__ name, setter for name, setter of props
  
  # @property [Object] contains the publisher instance provided by the underlying messaging librairy
  _publisher: {}
  
  # @property [Object] contains the messaging librairy instance. 
  _messagingLibrary: {}

  ###
  Takes the intended message and corresponding filter, and sends then to the bus using the selected underlying library.

  Defined by {BrovBus.getPublisher}

@abstract 
  @param filter [string] Filter sent together with the message
  @param message [String] The message itself
  ###
  _send: (filter, message) ->


  # @property [Function] Getter and setter for the _send(filter, message) function
  get send: -> @_send

###
The class create a bus using an underlying library (zmq currently supported, 
events is next), and expose methods to  bind publishers / subscribers to that
bus. It also defines a standard {Publisher} class, that offer an abstraction layer
between publishers and the bus' underlying librairy, by exposing a standard 
send(class, content) method. Different underlying librairy will expose different
{Publisher} class.

@author Jean-Laurent Picard <jean.laurent.picard at gmail>
###
module.exports = class BrovBus
  # @property [Object] Underlying librariy. 'zmq' by default.
  busType: ''
  # @property [Object] May be used in the logs. 'BrovBus_defaultName' by default.
  busName: ''
  
  ###
  @example Create a bus using zmq as the underlying librairy
    bus = new BrovBus('zmq', 'ZmqBus', {zmqUri: 'inprocess://communicationBus'})
 
  @param busType [String] Underlying librariy. Only 'zmq' is valid. 'zmq' by default.
  @param busName [String] May be used in the logs. 'BrovBus_defaultName' by default.
  @param options [Object] Different busType may take different options.
  @option options zmqUri [String] uri used by zmq's socket.bind(uri, callback) function (eg. "inprocess://name",
    "tcp://127.0.0.1:5000", "icp:///tmp/feed", etc.)
  ###
  constructor: (@busType = 'zmq', @busName = 'BrovBus_defaultName', options = {}) ->
    console.log "Instancing new Brov-Bus (#{@busName})"
    
    console.log "...Selecting bus type"
    console.log("......Options provided: #{JSON.stringify(options)}") if options?

    # Set @_messagingLibrary and other instance variables as necessary
    switch @busType
      when 'zmq'
        # zmq is only instantiated if required
        @_messagingLibrary = require('zmq')

        @zmqUri = "inproc://bluerovqueue"
        @zmqUri = options["zmqUri"] if options["zmqUri"]?
        console.log "......(zmqUri set to #{@zmqUri})"

      when 'events'
        @_messagingLibrary = require('events')
        #throw new Error("busType events - NOT IMPLEMENTED YET")

      else
        throw new Error 'brov-bus.constructor: unknown bus type (#{@busType})'

    console.log("......#{@busType} type bus is now setup")

    return
  # /constructor

  ###
  @overload registerSubscriber(callback, filters)
    Binds a callback function to a subscriber on the bus. The callback is called only if the message's filter 
    matches one of those provided in an Array as argument.
    @param callback [Function] callback(Error, filter[String], message[String])
    @param filters [Array<String>] filter eg. ["FILTER1", "FILTER2", ...]

  @overload registerSubscriber(callback, filter)
    Binds a callback function to a subscriber on the bus. The callback is called only if the message's filter 
    matches the filter provided as argument.
    @param callback [Function] callback(Error, filter[String], message[String])
    @param filter [String] filter eg. "FILTER3". NB: if set to undefined: the Subscriber will receive all messages sent to the bus
  ###
  registerSubscriber: (callback, filters) ->
    throw new Error "registerSubscriber: callback argument is missing" if !callback?
    
    console.log "Registering a new subscriber on #{@busName}, filters set to #{JSON.stringify(filters)}"
    
    switch @busType
      when 'zmq'
        # Create a new subscriber socket
        subscriber = @_messagingLibrary.socket("sub")
        # Connect to the specified URI
        subscriber.connect(@zmqUri)
        
        if !filters?
          # If no filters provided, listen to all
          # (necessary; if no filter is specified, zmq subscribers listen to nothing)
          subscriber.subscribe('')
        else
          # Otherwise, apply corresponding filters
          subscriber.subscribe filter for filter in filters

        #zmqcallback(msg)
        # Defines a callback suitable for zmq's subscriber .on aync method.
        # It parses the msg and calls the callback provbided in argument, following BrovBus API.
        zmqcallback = (msg) ->
          err = null
          splittedMsg = msg.toString().split(' ')
          err = new Error "(BrovBus.registerSubscriber - zmqcallback) - incorrect zmq message (no space or empty)" if splittedMsg.length < 2
          filter = splittedMsg[0]
          message = splittedMsg.slice(1).join(' ')
          callback(err, filter, message)
        
        # register Subscriber with Async callback
        subscriber.on('message', zmqcallback)
        
      when 'events'
        #throw new Error("registerSubscriber / events - NOT IMPLEMENTED")
        # Create a new subscriber socket
        subscriber = @_messagingLibrary.
        
      else
        throw new Error("Internal error")
        
    return
  # /registerSubscriber
  
  
  ###
  Returns a Publisher object that exposes the method send(filter, message). The send method will
  be overchared depending on the selected underlying messaging librairy (see [BrovBus] class)
  
  @return [Publisher] Class offering an abstraction layer to the underlying messaging librairy
  ###
  getPublisher: () ->
    # Instanciate a new publisher (return value)
    publisher = new Publisher

    switch @busType
      when 'zmq'
        # Creates a standard ZMQ publisher and binds it to @zmqUri
        zmqPub = @_messagingLibrary.socket("pub")
        zmqPub.bind(@zmqUri, -> (throw err if err?))
        
        # set _publisher and .send(filter, message) of the publisher object
        publisher._publisher = zmqPub

        publisher._send = (filter, message) ->
          @_publisher.send "#{filter} #{message}"
        
      when 'events'
        throw new Error("registerSubscriber / events - NOT IMPLEMENTED")
        #pub = new (events.EventEmitter)
        #publisher._setPublisher pub
      
      else
        throw new Error("Unknown bus type (#{@busType})")

    return publisher
  # /registerPublisher