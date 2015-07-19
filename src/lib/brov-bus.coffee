# Dependencies

#Define the BrovBus class
#  Objects of the BrovBus class expose those methods:
#    registerSubscriber(callback, filters)
#      callback(msg) --> function launched when a message matching the filters is received
#      filters --> ["FILTER1", "FILTER2"] - if set, the Subscriber will only receive messages starting with FILTER1 or FILTER2
#      returns nothing
#    registerPublisher()
#      returns an object that exposes the method
#        send(class, content)

class BrovBus
  @busType = undefined
  @busName = undefined
  
  constructor: (busType, busName, options) ->
    if !busType?
      throw new Error 'brov-bus.constructor: busType argument is missing'
    if !busName?
      throw new Error 'brov-bus.constructor: busName argument is missing'

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

  registerSubscriber: (callback, filters) ->
    if !callback?
      throw new Error "registerSubscriber: callback argument is missing"
    
    console.log "Registering a new subscriber on #{@busName}, filters set to #{JSON.stringify(filters)}"
    
    switch @busType
      when 'zmq'
        # Create a new subscriber socket
        subscriber = @zmq.socket("sub")
        # Connect to the specified URI
        subscriber.connect(@zmqUri)
        
        if !filters?
          # If no filters provided, listen to all
          subscriber.subscribe('')
        else
          # Otherwise, apply corresponding filters
          subscriber.subscribe filter for filter in filters
        
        # register Subscriber with Async callback
        subscriber.on('message', callback)
        
      when 'events'
        throw new Error("registerSubscriber / events - NOT IMPLEMENTED")
      
      else
        throw new Error("Internal error")
        
    return
  # /registerSubscriber
  
  
  # registerPublisher
  #   returns a Publisher object that exposes a .send(msg) method.
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
        pub = new (events.EventEmitter)
        publisher._setPublisher pub
      
      else
        throw new Error("Internal error")

    return publisher
  # /registerPublisher


module.exports = BrovBus
