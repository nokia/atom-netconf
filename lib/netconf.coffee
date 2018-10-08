###
  netconf.coffee
  Copyright (c) 2016 Nokia

  Note:
  This file is part of the netconf package for the ATOM Text Editor.

  Licensed under the MIT license
  See LICENSE.md delivered with this project for more information.
###

{CompositeDisposable} = require 'atom'
ncclient = require './ncclient'

NetconfToolbar = require './toolbar-netconf'
NavigationToolbar = require './toolbar-navigation'
CandidateToolbar = require './toolbar-candidate'
NokiaToolbar = require './toolbar-nokia'
StatusbarNetconf = require './statusbar-netconf'
XmlToolbar = require './toolbar-xml'

module.exports =
  config:
    server:
      title: 'Netconf Server'
      type: 'object'
      order: 1
      properties:
        host:
          title:   'Hostname'
          type:    'string'
          default: '127.0.0.1'

        port:
          title:   'TCP port'
          type:    'integer'
          default: 830

        username:
          title:   'Username'
          type:    'string'
          default: 'netconf'

        password:
          title:   'Password'
          type:    'string'
          default: ''
          description: "Password of the user. If empty, password authentication
          will be disabled."

        keysfile:
          title:   'Private Key File'
          type:    'string'
          default: ''
          description: "Complete path of the file containing private keys
          for SSHv2 authentication. On Linux and MacOS X you could use
          ~/.ssh2/id_rsa to access the registered private keys of the user.
          If empty, key authentication will be disabled."

        timeout:
          title:   'Netconf Timeout'
          type:    'integer'
          default: 300
          description : "Time to wait after an <rpc> message has been send,
          to receive an appropriate <rpc-reply> with the same message-id.
          Timeout is defined in seconds, default is 300 (5min).
          Please be aware that <get-config> on larger configurations might
          take time, so it is not recommended to use short timers."

        base11:
          title: 'base:1.1 (enable chunked-framing)'
          type : 'boolean'
          default : true

    behavior:
      title: 'Look and Feel'
      type: 'object'
      order: 2
      properties:
        audio :
          title: 'Enable Audio'
          type : 'boolean'
          default : true

        displayBanner :
          title: 'Display SSH Banner/Greeting'
          type : 'boolean'
          default : true
          description : "Display SSH Banner/Greeting as Notification"

        sampleHello :
          title: 'Sample Hello'
          type : 'boolean'
          default : true
          description : "Sample hello messages from netconf server into new
          XML file. Option to be enabled to check netconf capabilities
          announced."

        sampleError :
          title: 'Sample Error'
          type : 'boolean'
          default : false
          description : "Sample rpc-reply error messages from netconf server
          into new XML file."

        resultUntitled :
          title: 'Result: Untitled'
          type : 'boolean'
          default : false
          description : 'Store Results always in new XML file buffer. If
          option is not set, filenames are build from netconf msg-id.'

        resultFocus :
          title: 'Result: Focus'
          type : 'boolean'
          default : false
          description : 'Focus on the Pane/Editor which was used to store
          the XML result. If option is unchecked, focus will be restored
          after operation.'

        resultReadOnly :
          title: 'Result: Read-Only'
          type : 'boolean'
          default : false
          description : 'Text Editor for XML results will be blocked for
          editing.'

        enableTooltips :
          title: 'Enable Tooltips'
          type : 'boolean'
          default : true

        splitPane:
          title:   'Display Results'
          type:    'string'
          default: 'down'
          enum: ['default', 'right', 'down', 'left']

        xmlProcessor:
          title:   'XML Result Post Processing'
          type:    'string'
          default: 'prettify'
          enum: ['raw', 'minify', 'prettify']

        xmlFoldLevel:
          title:   'XML Result Folding'
          type:    'integer'
          default: 3
          description : "To be used in combination with prettify!"

    transactional:
      title: 'Transactional Options'
      type: 'object'
      order: 3
      properties:
        diffMod :
          title: 'Show Differences as Added, Removed or Modified'
          type: 'boolean'
          default: true
          description: "When enabled compare shows compact results. In case
          remove/added chunks are attached to each other, only the
          added part from candidate is display and marked as 'modified'.
          By disabling this option, both chunks are displayed and marked
          accordingly as 'added' and 'removed'."

        diffWords :
          title: 'Compare Differences Word by Word'
          type: 'boolean'
          default: true
          description: "Enable differences on words level for compare running
          vs candidate. When disabled comparision is on line level only."

    debug:
      title: 'Debug Options'
      type: 'object'
      order: 4
      properties:
        netconf:
          title: 'Enable Debug for Package'
          type : 'boolean'
          default : false

        _ncclient:
          title: 'Enable Debug for Netconf Module'
          type : 'boolean'
          default : false

        _ssh:
          title: 'Enable Debug for SSH Module'
          type : 'boolean'
          default : false

    environment:
      title: 'Environment'
      type: 'object'
      order: 5
      properties:
        workspace:
          title:   'Private Workspace'
          type:    'string'
          default: 'workspace_atom_netconf'

  activate: (state) ->
    # console.debug 'netconf::activate()'
    @subscriptions = new CompositeDisposable

    @client = new ncclient
    @status = new StatusbarNetconf
    @whatis = undefined

    @toolbars = []
    @toolbars.push new NetconfToolbar
    @toolbars.push new XmlToolbar
    @toolbars.push new NavigationToolbar
    @toolbars.push new CandidateToolbar
    @toolbars.push new NokiaToolbar

  consumeStatusBar: (atomStatusBar) ->
    # console.debug 'netconf::consumeStatusBar()'

    @status.initialize(atomStatusBar)
    @status.register(@client)

    # --- register toolbars ---------------------------------------------------
    @toolbars.forEach (toolbar) =>
      toolbar.initialize(atomStatusBar)
      toolbar.register(@client)
      toolbar.register(@status)

    # --- enable toolbars, icons and tooltips ---------------------------------
    @tooltips atom.config.get 'atom-netconf.behavior.enableTooltips'
    @updateUI atom.workspace.getActiveTextEditor()

    # --- register events -----------------------------------------------------
    atom.config.observe 'atom-netconf.behavior.enableTooltips', @tooltips.bind(this)
    atom.workspace.onDidChangeActivePaneItem @updateUI.bind(this)

    # --- register commands ---------------------------------------------------
    @subscriptions.add atom.commands.add 'atom-workspace', 'netconf:sendrpc':    => @toolbars[0].do_rpc_call()
    @subscriptions.add atom.commands.add 'atom-workspace', 'netconf:connect':    => @toolbars[0].do_connect()
    @subscriptions.add atom.commands.add 'atom-workspace', 'netconf:disconnect': => @toolbars[0].do_disconnect()
    @subscriptions.add atom.commands.add 'atom-workspace', 'netconf:smart_select': => @toolbars[1].do_smart_select()

  tooltips: (option) ->
    # console.debug 'netconf::tooltips()'
    if option
      if @whatis == undefined
        @whatis = new CompositeDisposable
        @status.tooltips(@whatis)
        @toolbars.forEach (toolbar) => toolbar.tooltips(@whatis)
    else
      if @whatis != undefined
        @whatis.dispose()
        @whatis = undefined

  updateUI: (editor)->
    # console.debug 'netconf::updateUI()'
    @toolbars.forEach (toolbar) => toolbar.updateUI(editor)

  deactivate: ->
    # console.debug 'netconf::deactivate()'
    @subscriptions.dispose()

  serialize: ->
    # console.debug 'netconf::serialize()'
