# Module description
# Exports a single anonymous class (internally named BrovBus)
# This class offers methods to 1) create a bus (zmq currently supported, events is next),
# 2) add subscribers and publishers to that bas.
# It also defines a standard "Publisher" class, that offer an abstraction layer
# between publishers and the bus' underlaying librairy, by exposing a standard 
# send(class, content) method.

# Dependencies
# zmq is required if 'zmq' provided as busType at object's creation.

# BrovBus class definition
# Objects of the BrovBus class expose those methods:
#  registerSubscriber(callback, filters)
#  registerPublisher()


class BrovBus
  @busType = undefined
  @busName = undefined
  
  constructor: (busType, busName, options) ->
    throw new Error 'brov-bus.constructor: busType argument is missing' if !busType?
    throw new Error 'brov-bus.constructor: busName argument is missing' if !busName?

    console.log "Instancing new Brov-Bus #{busName}"
    @busName=busName
    
    console.log "...Selecting bus type"
    console.log("......Options provided: #{JSON.stringify(options)}") if options?

    # If not specified, default type is 'zmq'
    switch busType
      when 'zmq', undefined
        # zmq is only instanciated if required
        @zmq = require('zmq')
        @busType = 'zmq'
        @zmqUri = "inproc://bluerovqueue"

        # load options if provided
        if options?
          @zmqUri = options["zmqUri"] if options["zmqUri"]?
        console.log "......(zmqUri set to #{@zmqUri})"

      when 'events'
        @busType = 'events'
        throw new Error("busType events - NOT IMPLEMENTED YET")

      else
        throw new Error 'brov-bus.constructor: unknown bus type (#{@busType})'

    console.log("......#{@busType} type bus is now setup")

    return
  # /constructor

  
  # registerSubscriber(callback, filters)
  #  async function that will bind a callback function to a subscriber on the bus.
  #    Arguments:
  #      callback(err, filter, message) --> function launched when a message matching the filters is received
  #      filters --> optional; string, or array of string.
  #          eg. ["FILTER1", "FILTER2", ...] - the Subscriber only receives messages of the 
  #                                              filter FILTER1 or FILTER2
  #          eg. "FILTER3" - the Subscriber only receives messages of the filter FILTER3
  #          eg. /omitted/ or undefined - the Subscriber will receive all messages sent to the bus
  #
  #    returns nothing
  registerSubscriber: (callback, filters) ->
    throw new Error "registerSubscriber: callback argument is missing" if !callback?
    
    console.log "Registering a new subscriber on #{@busName}, filters set to #{JSON.stringify(filters)}"
    
    switch @busType
      when 'zmq'
        # Create a new subscriber socket
        subscriber = @zmq.socket("sub")
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
        throw new Error("registerSubscriber / events - NOT IMPLEMENTED")
      
      else
        throw new Error("Internal error")
        
    return
  # /registerSubscriber
  
  
  # registerPublisher()
  #  returns an object that exposes the method
  #      send(filter, message)
  registerPublisher: () ->
    # Prototype of the object that will be returned
    # _publisher contains the publisher object provided by the choosen librairy
    # .send method takes two arguments (filter, message), and does whatever is required to send them through _publisher
    # both _publisher and .send(filter, message) are to be set by _setPublisher and _setSend respectively
    class Publisher
      @_publisher = undefined
      
      _setPublisher: (@_publisher) ->
      _setSend: (@send) ->
      
      @send: (filter, message) ->

    # Instanciate a new publisher (return value)
    publisher = new Publisher

    switch @busType
      when 'zmq'
        # Creates a standard ZMQ publisher and binds it to @zmqUri
        pub = @zmq.socket("pub")
        pub.bind(@zmqUri, -> (throw err if err?))
        
        # set _publisher and .send(filter, message) of the publisher object
        publisher._setPublisher pub
        publisher._setSend (filter, message) ->
          @_publisher.send "#{filter} #{message}"
        
      when 'events'
        throw new Error("registerSubscriber / events - NOT IMPLEMENTED")
        #pub = new (events.EventEmitter)
        #publisher._setPublisher pub
      
      else
        throw new Error("Internal error")

    return publisher
  # /registerPublisher


# Export anonymous prototype
module.exports = BrovBus
