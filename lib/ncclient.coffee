###
  ncclient.coffee
  Copyright (c) 2016 Nokia

  Note:
  This file is part of the netconf package for the ATOM Text Editor.

  Licensed under the MIT license
  See LICENSE.md delivered with this project for more information.
###

{EventEmitter} = require 'events'
ssh2 = require 'ssh2'
url    = require 'url'
xmltools = require './xmltools'

module.exports =
class ncclient extends EventEmitter

  constructor: ->
    @debugging = atom.config.get 'atom-netconf.debug._ncclient', false
    atom.config.observe 'atom-netconf.debug._ncclient', @updateDebug.bind(this)
    console.debug '::constructor()' if @debugging

    @callbacks = {}
    @formating = {}

    @connected = false
    @nokiaSROS = false
    @locked = false

    @ncs = undefined
    @ssh = undefined

  debugSSH: ->
    if atom.config.get 'atom-netconf.debug._ssh', false
      console.debug.apply(console, arguments)

  updateDebug: (newValue) =>
    console.log "netconf debug enabled" if newValue
    console.log "netconf debug disabled" unless newValue
    @debugging = newValue

  msgHandler: (ncstream, msg) =>
    console.debug "::msgHandler()" if @debugging

    xmldom = (new DOMParser).parseFromString msg, "text/xml"
    if xmldom==null
      @emit 'warning', 'netconf error: xml parser failed with rpc-reply received', msg

    else if xmldom.firstElementChild.localName == "hello"
      console.log "hello message received" if @debugging
      ncstream.write '<?xml version="1.0" encoding="UTF-8"?>\n'
      ncstream.write '<hello xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">\n'
      ncstream.write '  <capabilities>\n'
      ncstream.write '    <capability>urn:ietf:params:netconf:base:1.0</capability>\n'
      ncstream.write '  </capabilities>\n'
      ncstream.write '</hello>\n'
      ncstream.write ']]>]]>'
      @connected = true

      @nokiaSROS = false
      for capability in xmldom.getElementsByTagName('capability')
        if capability.firstChild.data.startsWith("urn:nokia.com:sros:ns:yang:sr:conf?")
          @nokiaSROS = true
          @emit 'Nokia SROS'

        if capability.firstChild.data.startsWith("urn:ietf:params:netconf:capability:validate:1")
          @emit 'support:validate'

        if capability.firstChild.data == 'urn:ietf:params:netconf:capability:candidate:1.0'
          @emit 'support:candidate'

      mode = atom.config.get 'atom-netconf.behavior.xmlProcessor'
      if mode == 'prettify'
        @emit 'connected', xmltools.prettify(xmldom)
      else if mode == 'minify'
        @emit 'connected', xmltools.minify(xmldom)
      else
        @emit 'connected', msg

    else if xmldom.firstElementChild.localName == "rpc-reply"
      console.log "rpc-reply message received" if @debugging
      msgid = xmldom.firstElementChild.getAttribute('message-id')
      if (msgid)
        success = false

        if xmldom.firstElementChild.childElementCount == 1
          if xmldom.firstElementChild.firstElementChild.localName == "ok"
            @emit 'rpc-ok', msgid
            success = true
          else if xmldom.firstElementChild.firstElementChild.localName == "rpc-error"
            @emit 'rpc-error', msgid, xmldom
          else
            @emit 'rpc-success', msgid, xmldom
            success = true
        else
          @emit 'warning', "netconf #{msgid}: failed with malformed rpc-reply", msg

        if @callbacks[msgid]?
          console.log "callback found for message-id=#{msgid}" if @debugging
          if success
            mode = atom.config.get 'atom-netconf.behavior.xmlProcessor'
            if @formating[msgid] == 'prettify'
              @callbacks[msgid] msgid, xmltools.prettify(xmldom)
            else if @formating[msgid] == 'minify'
              @callbacks[msgid] msgid, xmltools.minify(xmldom)
            else if @formating[msgid] == 'data'
              @callbacks[msgid] msgid, xmltools.data_node(xmldom)
            else if @formating[msgid] == 'sros'
              @callbacks[msgid] msgid, xmltools.sros_config(xmldom)
            else
              @callbacks[msgid] msgid, msg

          delete @callbacks[msgid]
          delete @formating[msgid]

        @emit 'idle' if (Object.getOwnPropertyNames(@callbacks).length == 0)
      else
        @emit 'warning', 'netconf error: rpc-reply w/o message-id received', msg

    else if xmldom.firstElementChild.localName == "notification"
      console.log "notification message received" if @debugging
      @emit 'notification', xmldom

    else
      # current version of ncclient only support hello, rpc-reply and notification
      @emit 'warning', 'netconf error: unsupported message received', msg

  # --- ncclient public methods ----------------------------------------------

  connect: (uri) =>
    console.debug "::connect(#{uri})" if @debugging

    # usage:
    # client.connect 'netconf://netconf:netconf@localhost:8300/'

    @emit 'busy'

    @ssh = new ssh2.Client
    @callbacks = {}
    @formating = {}

    @ssh.on 'error', (err) =>
      @emit 'error', 'ssh error', err.toString()

    @ssh.on 'connect', ->
      console.log "ssh connect" if @debugging

    @ssh.on 'timeout', =>
      console.log "ssh timeout" if @debugging

    @ssh.on 'close', =>
      console.log "ssh close" if @debugging
      @connected = false
      @locked = false
      @emit 'locked', false
      @emit 'end'

    @ssh.on 'end', =>
      console.log "ssh end" if @debugging

    @ssh.on 'ready', =>
      @ssh.subsys 'netconf', (err, ncstream) =>
        if err
          @emit 'error', 'ssh error', err.toString()
          return

        @ncs = ncstream
        @buffer = ""
        @bytes = 0

        ncstream.on 'error', (error) =>
          console.log "netconf connection error: #{error}" if @debugging

        ncstream.on 'close', =>
          console.log "netconf connection closed" if @debugging

        ncstream.on 'data', (data) =>
          @buffer += data.toString('utf-8')
          @bytes += data.length
          if @bytes > 100000000
            @emit 'data', "#{@bytes>>20}MB"
          else
            @emit 'data', "#{@bytes>>10}KB"

          while @buffer.match("]]>]]>")
            parts = @buffer.split("]]>]]>")
            msg = parts.shift()
            @buffer = parts.join("]]>]]>")
            @msgHandler(ncstream, msg)

    {protocol, hostname, port, auth} = url.parse(uri)
    username = auth.split(':')[0]
    password = auth.split(':')[1]

    @ssh.connect
      host:     hostname
      port:     port
      username: username
      password: password
      debug:    @debugSSH

  rpc: (request, format='default', callback) =>
    console.debug "::rpc()" if @debugging

    if @connected
      if typeof request is 'string'
        parser = new DOMParser()
        reqDOM = parser.parseFromString request, "text/xml"
        nodeName = reqDOM.firstElementChild.localName
        if (nodeName == 'rpc')
          msgid = reqDOM.firstElementChild.getAttribute('message-id')
          if (msgid)
            if @callbacks[msgid]?
              @emit 'warning', 'netconf error', 'message-id is already in-use'
            else
              @emit 'busy'
              @callbacks[msgid] = callback
              if format=='default'
                @formating[msgid] = atom.config.get 'atom-netconf.behavior.xmlProcessor'
              else
                @formating[msgid] = format
              @ncs.write request
              @ncs.write "]]>]]>"
          else
            @emit 'warning', 'netconf error', 'rpc-request requires message-id attribute'
        else
          @emit 'warning', 'netconf error: rpc required', "unsupported netconf operation #{nodeName}"
      else
        console.error 'ncclient only supports rpc-requests using type string'
    else
      @emit 'error', 'netconf error', 'Need to connect netconf client first.'

  disconnect: (callback) =>
    console.debug "::disconnect()" if @debugging
    if @connected
      @emit 'busy'
      @callbacks['disconnect'] = => @ssh.end()
      @formating['disconnect'] = 'none'
      @ncs.write '<?xml version="1.0" encoding="UTF-8"?>\n'
      @ncs.write '<rpc message-id="disconnect" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0"><close-session/></rpc>'
      @ncs.write "]]>]]>"
    else
      @emit 'warning', 'netconf disconnect failed', 'already disconnected'

  lock: =>
    console.debug "::lock()" if @debugging
    if @connected
      if not @locked
        xmlrpc = """<?xml version="1.0" encoding="UTF-8"?><rpc message-id="lock" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0"><lock><target><candidate/></target></lock></rpc>"""
        @rpc xmlrpc, 'default',  =>
          @emit 'locked', true
          @locked = true
      else
        @emit 'warning', 'netconf lock failed', 'already locked'
    else
      @emit 'warning', 'netconf lock failed', 'need to connect first'

  unlock: =>
    console.debug "::unlock()" if @debugging
    if @connected
      if @locked
        xmlrpc = """<?xml version="1.0" encoding="UTF-8"?><rpc message-id="unlock" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0"><unlock><target><candidate/></target></unlock></rpc>"""
        @rpc xmlrpc, 'default', =>
          @emit 'locked', false
          @locked = false
      else
        @emit 'warning', 'netconf unlock failed', 'already locked'
    else
      @emit 'warning', 'netconf unlock failed', 'need to connect first'

  commit: =>
    console.debug "::commit()" if @debugging
    if @connected
      xmlrpc = """<?xml version="1.0" encoding="UTF-8"?><rpc message-id="commit" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0"><commit/></rpc>"""
      @rpc xmlrpc, 'default', => @emit 'committed'

  discard: =>
    console.debug "::discard()" if @debugging
    if @connected
      xmlrpc = """<?xml version="1.0" encoding="UTF-8"?><rpc message-id="discard" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0"><discard-changes/></rpc>"""
      @rpc xmlrpc, 'default', => @emit 'discarded'

  validate: =>
    console.debug "::validate()" if @debugging
    if @connected
      xmlrpc = """<?xml version="1.0" encoding="UTF-8"?><rpc message-id="validate" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0"><validate><source><candidate/></source></validate></rpc>"""
      @rpc xmlrpc, 'default', => @emit 'validated'

  close: =>
    console.debug "::close()" if @debugging
    @ssh.end()

  isNokiaSROS: =>
    return @nokiaSROS

  isConnected: =>
    return @connected

  isLocked: =>
    return @locked

# EOF
