class FileSource extends EventEmitter
    constructor: (@file) ->
        if not window.FileReader
            return @emit 'error', 'This browser does not have FileReader support.'
        
        @offset = 0
        @length = @file.size
        @chunkSize = 1 << 20
            
    start: ->
        @reader = new FileReader
        
        @reader.onload = (e) =>
            buf = new Buffer(new Uint8Array(e.target.result))
            @offset += buf.length
        
            @emit 'data', buf
            @emit 'progress', @offset / @length * 100
        
            @loop() if @offset < @length
        
        @reader.onloadend = =>
            @emit 'end' if @offset >= @length
        
        @reader.onerror = (e) =>
            @emit 'error', e
        
        @reader.onprogress = (e) =>
            @emit 'progress', (@offset + e.loaded) / @length * 100
        
        @loop()
        
    loop: ->
        slice = if @file.webkitSlice then 'webkitSlice' else 'mozSlice'
        endPos = Math.min(@offset + @chunkSize, @length)
        
        blob = @file[slice](@offset, endPos)
        @reader.readAsArrayBuffer(blob)
        
    pause: ->
        @reader?.abort()
        
    reset: ->
        @pause()
        @offset = 0