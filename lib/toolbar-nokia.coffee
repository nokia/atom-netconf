###
  toolbar-nokia.coffee
  Copyright (c) 2016 Nokia

  Note:
  This file is part of the netconf package for the ATOM Text Editor.

  Licensed under the MIT license
  See LICENSE.md delivered with this project for more information.
###

{CompositeDisposable, TextEditor} = require 'atom'
ncclient = require './ncclient'
Status = require './statusbar-netconf'

xmltools = require './xmltools'


class NokiaToolbar extends HTMLElement

  initialize: (@statusBar) ->
    @debugging = atom.config.get 'atom-netconf.debug.netconf', false
    atom.config.observe 'atom-netconf.debug.netconf', (value) => this.debugging = value
    console.debug '::initialize()' if @debugging

    # --- user-interface icons ------------------------------------------------
    @info_toolbar1 = document.createElement('b')
    @info_toolbar1.textContent = 'SR'

    @info_toolbar2 = document.createElement('span')
    @info_toolbar2.textContent = 'OS  '
    @info_toolbar2.style.whiteSpace = 'pre'

    @icons = document.createElement('span')
    @icons.classList.add('hidden')

    @get_running = document.createElement('span')
    @get_running.classList.add('icon', 'icon-file-directory', 'active')
    @get_running.addEventListener('click', @do_get_running.bind(this))

    @get_candidate = document.createElement('span')
    @get_candidate.classList.add('icon', 'icon-file-submodule', 'active')
    @get_candidate.addEventListener('click', @do_get_candidate.bind(this))

    @check_cfg = document.createElement('span')
    @check_cfg.classList.add('icon', 'icon-checklist', 'active')
    @check_cfg.addEventListener('click', @do_check.bind(this))

    @edit_cfg = document.createElement('span')
    @edit_cfg.classList.add('icon', 'icon-pencil', 'active')
    @edit_cfg.addEventListener('click', @do_edit.bind(this))

    # --- content and style of netconf toolbar --------------------------------
    @id = "toolbar://nokia"
    @classList.add('netconf', 'inline-block', 'toolbar', 'hidden')
    @style.maxWidth = 'none'
    @appendChild @info_toolbar1
    @appendChild @info_toolbar2
    @appendChild @icons
    @icons.appendChild @get_running
    @icons.appendChild @get_candidate
    @icons.appendChild @check_cfg
    @icons.appendChild @edit_cfg

    @statusBarItem = @statusBar.addLeftTile(priority: 100, item: this)

    @addEventListener 'mouseover', =>@icons.classList.remove('hidden')
    @addEventListener 'mouseout', =>@icons.classList.add('hidden')

  register: (object) =>
    console.debug '::register()' if @debugging
    if (object instanceof Status)
      @status = object
    else if (object instanceof ncclient)
      @client = object
      @client.on 'end', => @classList.add('hidden')
      @client.on 'Nokia SROS', => @classList.remove('hidden')

  destroy: =>
    console.debug '::destroy()' if @debugging
    @statusBarItem?.destroy()
    @info_toolbar1?.destroy()
    @info_toolbar2?.destroy()
    @get_running?.destroy()
    @get_candidate?.destroy()
    @check_cfg?.destroy()
    @edit_cfg?.destroy()

  # --- actions triggered by user ---------------------------------------------
  do_get_running: =>
    console.debug '::do_get_running()' if @debugging
    xmlreq = """<?xml version="1.0" encoding="UTF-8"?>
      <rpc message-id="get-config running" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
        <get-config>
          <source><running/></source>
          <filter type="subtree">
            <configure xmlns="urn:nokia.com:sros:ns:yang:sr:conf" />
          </filter>
        </get-config>
      </rpc>"""

    timeout = atom.config.get 'atom-netconf.server.timeout'
    @client.rpc xmlreq, 'sros', timeout, (msgid, msg) =>
      foldLevel =  atom.config.get 'atom-netconf.behavior.xmlFoldLevel'
      @status.result "responses/running.xml", msg, foldLevel-2

  do_get_candidate: =>
    console.debug '::do_get_candidate()' if @debugging
    xmlreq = """<?xml version="1.0" encoding="UTF-8"?>
      <rpc message-id="get-config candidate" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
        <get-config>
          <source><candidate/></source>
          <filter type="subtree">
            <configure xmlns="urn:nokia.com:sros:ns:yang:sr:conf" />
          </filter>
        </get-config>
      </rpc>"""

    timeout = atom.config.get 'atom-netconf.server.timeout'
    @client.rpc xmlreq, 'sros', timeout, (msgid, msg) =>
      foldLevel =  atom.config.get 'atom-netconf.behavior.xmlFoldLevel'
      @status.result "responses/candidate.xml", msg, foldLevel-2

  do_check: =>
    console.debug '::do_check()' if @debugging
    editor = atom.workspace.getActiveTextEditor()

    xmldom = (new DOMParser).parseFromString editor.getText(), "text/xml"
    if xmldom==null
      @status.warning('XML-Parser Error!', 'Failed to parse TextEditor content.')
      return

    nodes = xmldom.getElementsByTagNameNS('urn:nokia.com:sros:ns:yang:sr:conf', 'configure')
    if nodes.length == 0
      @status.warning('Netconf Error!', '<configure xmlns="urn:nokia.com:sros:ns:yang:sr:conf"/> not found.')
      return

    doc = document.implementation.createDocument('urn:ietf:params:xml:ns:netconf:base:1.0', '', null)
    rpc = doc.createElementNS('urn:ietf:params:xml:ns:netconf:base:1.0', 'rpc')
    rpc.setAttribute('message-id', 'validate')
    action = doc.createElement('validate')
    source = doc.createElement('source')
    config = doc.createElement('config')
    config.appendChild nodes[0] while nodes.length > 0  # add <configure> node(s)
    source.appendChild config   # add <config> node
    action.appendChild source   # add <source> node
    rpc.appendChild action      # add <validate> node
    doc.appendChild rpc         # add <rpc> node
    xmlreq = xmltools.prettify(doc)

    timeout = atom.config.get 'atom-netconf.server.timeout'
    @client.rpc xmlreq, 'sros', timeout, (msgid, msg) =>
      console.log "successfully validated" if @debugging

  do_edit: =>
    console.debug '::do_edit()' if @debugging
    editor = atom.workspace.getActiveTextEditor()

    xmldom = (new DOMParser).parseFromString editor.getText(), "text/xml"
    if xmldom==null
      @status.warning('XML-Parser Error!', 'Failed to parse TextEditor content.')
      return

    nodes = xmldom.getElementsByTagNameNS('urn:nokia.com:sros:ns:yang:sr:conf', 'configure')
    if nodes.length == 0
      @status.warning('Netconf Error!', '<configure xmlns="urn:nokia.com:sros:ns:yang:sr:conf"/> not found.')
      return

    doc = document.implementation.createDocument('urn:ietf:params:xml:ns:netconf:base:1.0', '', null)
    rpc = doc.createElementNS('urn:ietf:params:xml:ns:netconf:base:1.0', 'rpc')
    rpc.setAttribute('message-id', 'edit-config')
    action = doc.createElement('edit-config')
    target = doc.createElement('target')
    datastore = doc.createElement('candidate')
    config = doc.createElement('config')
    config.appendChild nodes[0] while nodes.length > 0  # add <configure> node(s)
    target.appendChild datastore # add <candidate> node
    action.appendChild target    # add <target> node
    action.appendChild config    # add <config> node
    rpc.appendChild action       # add <edit-config> node
    doc.appendChild rpc          # add <rpc> node
    xmlreq = xmltools.prettify(doc)

    timeout = atom.config.get 'atom-netconf.server.timeout'
    @client.rpc xmlreq, 'sros', timeout, (msgid, msg) =>
      console.log "edit-config was successful" if @debugging

  # --- update user-interface tasks -------------------------------------------
  tooltips: (@whatis) =>
    @whatis.add atom.tooltips.add(@get_running,   {title: 'SROS: get-config &lt;running&gt;'})
    @whatis.add atom.tooltips.add(@get_candidate, {title: 'SROS: get-config &lt;candidate&gt;'})
    @whatis.add atom.tooltips.add(@check_cfg,     {title: 'SROS: validate'})
    @whatis.add atom.tooltips.add(@edit_cfg,      {title: 'SROS: edit-config &lt;candidate&gt;'})

  updateUI: (editor) =>
    if editor instanceof TextEditor && editor.getGrammar().scopeName in ['text.plain.null-grammar', 'text.plain', 'text.xml']
      @edit_cfg.classList.remove('hidden')
      @check_cfg.classList.remove('hidden')
    else
      @edit_cfg.classList.add('hidden')
      @check_cfg.classList.add('hidden')

module.exports = document.registerElement('toolbar-nokia', prototype: NokiaToolbar.prototype, extends: 'div')

# EOF
