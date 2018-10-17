###
  toolbar-netconf.coffee
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

path = require 'path'
fs = require 'fs'
os = require 'os'
jinja = require 'jinja-js'
yaml = require 'js-yaml'

class NetconfToolbar extends HTMLElement

  initialize: (@statusBar) ->
    @debugging = atom.config.get 'atom-netconf.debug.netconf', false
    atom.config.observe 'atom-netconf.debug.netconf', (value) => this.debugging = value
    console.debug '::initialize()' if @debugging

    # --- read server settings  -----------------------------------------------
    @pkgpath = atom.packages.resolvePackagePath('atom-netconf')
    @wspath = path.join(os.homedir(), atom.config.get('atom-netconf.environment.workspace'))

    if not fs.existsSync(@wspath)
      fs.mkdirSync @wspath
      fs.mkdirSync path.join(@wspath, 'library')
      fs.mkdirSync path.join(@wspath, 'host_vars')
      fs.copyFileSync path.join(@pkgpath, 'servers.yaml'), path.join(@wspath, 'servers.yaml')
      fs.copyFileSync path.join(@pkgpath, 'servers.example.yaml'), path.join(@wspath, 'servers.example.yaml')

      fs.closeSync fs.openSync(path.join(@wspath, 'environment.yaml'), 'w')
      fs.closeSync fs.openSync(path.join(@wspath, 'host_vars', 'default.yaml'), 'w')

    try
      filename = path.join(@wspath, 'servers.yaml')
      settings = fs.readFileSync(filename).toString('utf-8')
      @servers = yaml.load(settings)
    catch e
      console.debug 'servers.yaml not found! Using single NETCONF server as per atom-netconf settings.' if @debugging
      @servers = {}

    # --- user-interface icons ------------------------------------------------
    @icon_idle = document.createElement('span')
    @icon_idle.classList.add('icon', 'icon-terminal', 'active')
    @icon_idle.addEventListener 'click', @do_connect.bind(this)

    @icon_connected = document.createElement('span')
    @icon_connected.classList.add('icon', 'icon-terminal', 'active', 'success', 'hidden')
    @icon_connected.addEventListener 'click', @do_disconnect.bind(this)

    @link_netconf_rpc = document.createElement('span')
    @link_netconf_rpc.classList.add('wide')
    @link_netconf_rpc.textContent = "netconf"
    @link_netconf_rpc.addEventListener('click', @do_rpc_call.bind(this))

    @select_server = document.createElement('select')
    @select_server.setAttribute('size', '1')

    addServerSelect = false
    for server of @servers
      textNode = document.createTextNode(server)
      option = document.createElement('option')
      option.setAttribute("value", server)
      option.appendChild(textNode)
      @select_server.appendChild(option)
      if server!="default"
        addServerSelect = true

    @icons = document.createElement('span')
    @icons.classList.add('hidden')

    @icon_pkg_settings = document.createElement('span')
    @icon_pkg_settings.classList.add('icon', 'icon-settings', 'active')
    @icon_pkg_settings.addEventListener('click', @do_settings.bind(this))

    @icon_examples = document.createElement('span')
    @icon_examples.classList.add('icon', 'icon-link-external', 'active')
    @icon_examples.addEventListener('click', @do_examples.bind(this))

    @icon_mute = document.createElement('span')
    @icon_mute.classList.add('icon', 'icon-unmute', 'active', 'hidden')
    @icon_mute.addEventListener('click', @do_mute.bind(this))

    @icon_unmute = document.createElement('span')
    @icon_unmute.classList.add('icon', 'icon-mute', 'active', 'hidden')
    @icon_unmute.addEventListener('click', @do_unmute.bind(this))

    # --- content and style of netconf toolbar --------------------------------
    @id = "toolbar://netconf"
    @classList.add('netconf', 'inline-block', 'toolbar')
    @style.maxWidth = 'none'
    @appendChild @icon_idle
    @appendChild @icon_connected
    @appendChild @link_netconf_rpc
    if addServerSelect
      @appendChild @select_server
    @appendChild @icons
    @icons.appendChild @icon_pkg_settings
    @icons.appendChild @icon_examples
    @icons.appendChild @icon_mute
    @icons.appendChild @icon_unmute

    atom.config.observe 'atom-netconf.behavior.audio', @audio.bind(this)
    @statusBarItem = @statusBar.addLeftTile(priority: 100, item: this)

    @addEventListener 'mouseover', =>@icons.classList.remove('hidden')
    @addEventListener 'mouseover', =>@select_server.classList.remove('hidden')
    @addEventListener 'mouseout', =>@icons.classList.add('hidden')
    @addEventListener 'mouseout', =>@select_server.classList.add('hidden')


  register: (object) =>
    console.debug '::register()' if @debugging
    if (object instanceof Status)
      @status = object
    else if (object instanceof ncclient)
      @client = object

      # Event Listeners for @client object
      @client.on 'error', (msg) =>
        if @client?.isConnected()
          @client.close()

        @icon_idle.classList.add('error')
        setTimeout (=> @icon_idle.classList.remove('error')), 5000

      @client.on 'rpc-error', (msgid, xmldom) =>
        if atom.config.get 'atom-netconf.behavior.sampleError'
          if xmldom instanceof XMLDocument
            @status.result "failures/#{msgid}.xml", xmltools.prettify(xmldom), 0

      @client.on 'end', =>
        @icon_idle.classList.remove('hidden')
        @icon_connected.classList.add('hidden')
        @select_server.removeAttribute('disabled');

      @client.on 'connected', callback = (hello) =>
        @icon_idle.classList.add('hidden')
        @icon_connected.classList.remove('hidden')
        @select_server.setAttribute('disabled', '');

  destroy: =>
    console.debug '::destroy()' if @debugging
    @statusBarItem?.destroy()
    @icon_idle?.destroy()
    @icon_connected?.destroy()
    @link_netconf_rpc?.destroy()
    @icon_pkg_settings?.destroy()
    @icon_examples?.destroy()
    @icon_mute?.destroy()
    @icon_unmute?.destroy()

  # --- actions triggered by user ---------------------------------------------
  do_connect: =>
    console.debug '::do_connect()' if @debugging
    if @client?.isConnected()
      @status.warning('Already connected!')
    else
      if @select_server.value == "default"
        host = atom.config.get 'atom-netconf.server.host'
        port = atom.config.get 'atom-netconf.server.port'
        username = atom.config.get 'atom-netconf.server.username'
        password = atom.config.get 'atom-netconf.server.password'
        keysfile = atom.config.get 'atom-netconf.server.keysfile'
      else
        host = @servers[@select_server.value].host
        port = @servers[@select_server.value].port
        username = @servers[@select_server.value].username
        password = @servers[@select_server.value].password
        keysfile = @servers[@select_server.value].keyfile

      if password != ""
        # if password is provided, use password auth
        @client.connect "netconf://#{username}:#{password}@#{host}:#{port}/"
      else if keysfile != ""
        # if keysfile is provided, use private key auth
        @client.loadkeyfile(keysfile)
        @client.connect "netconf://#{username}@#{host}:#{port}/"
      else
        # neither password nor keysfile has been provided, use 'none' auth
        @client.connect "netconf://#{username}@#{host}:#{port}/"

  do_disconnect: =>
    console.debug "::do_disconnect()" if @debugging
    if @client?.isConnected()
      @client.disconnect (msg) =>
        @client.close()
        @icon_idle.classList.remove('hidden')
        @icon_connected.classList.add('hidden')
        @select_server.removeAttribute('disabled');
    else
      @status.warning('Already disconnected!')

  do_rpc_call: =>
    console.debug "::do_rpc_call()" if @debugging

    editor = atom.workspace.getActiveTextEditor()
    if (editor instanceof TextEditor)
      filetype = editor.getGrammar().scopeName

      if filetype in ['text.plain.null-grammar', 'text.plain', 'text.xml']
        if (path.extname(editor.getPath()) == ".j2")
          try
            varfile = path.join(path.dirname(editor.getPath()), 'vars.yaml')
            buf = fs.readFileSync(varfile).toString('utf-8')
            vars = yaml.load(buf)
          catch err
            @status.warning('Error loading vars file!', varfile) if @debugging
            vars = {}

          try
            envfile = path.join(@wspath, 'environment.yaml')
            buf = fs.readFileSync(envfile).toString('utf-8')
            vars['env'] = yaml.load(buf)
          catch err
            @status.warning('Error loading environment file!', envfile) if @debugging

          if @servers[@select_server.value]?.hostvars
            try
              hostfile = path.join(@wspath, @servers[@select_server.value].hostvars)
              buf = fs.readFileSync(hostfile).toString('utf-8')
              vars['host'] = yaml.load(buf)
            catch err
              @status.warning('Error loading host-vars file!', hostfile)

          try
            template = editor.getText()
            xmlrpc = jinja.render(template, vars).toString('utf-8')
          catch err
            @status.warning('Error executing Jinja2 template!')
            xmlrpc = undefined
        else
          xmlrpc = editor.getText()

        if xmlrpc!=undefined
          timeout = atom.config.get 'atom-netconf.server.timeout'
          @client.rpc xmlrpc, 'default', timeout, (msgid, msg) =>
            @status.result "responses/#{msgid}.xml", msg
      else
        @status.warning('Can only process XML or plain text')
    else
      @status.warning('Need to open XML file first')

  do_settings: =>
    console.debug "::do_settings()" if @debugging
    # This does not work if Settings view is already open
    # todo: check with atom, or close Settings before open()
    atom.workspace.open 'atom://config/packages/atom-netconf'
    @status.done()

  do_examples: =>
    console.debug "::do_examples()" if @debugging
    atom.project.addPath path.join(@pkgpath, 'examples')
    atom.project.addPath @wspath
    @status.done()

  do_mute: =>
    console.debug "::do_mute()" if @debugging
    atom.config.set 'atom-netconf.behavior.audio', false

  do_unmute: =>
    console.debug "::do_unmute()" if @debugging
    atom.config.set 'atom-netconf.behavior.audio', true

  audio: (option) =>
    if option
      @icon_mute.classList.remove('hidden')
      @icon_unmute.classList.add('hidden')
    else
      @icon_mute.classList.add('hidden')
      @icon_unmute.classList.remove('hidden')
    @status?.click()

  # --- update user-interface tasks -------------------------------------------
  tooltips: (@whatis) =>
    @whatis.add atom.tooltips.add(@icon_idle, {title: 'Connect to Netconf Server'})
    @whatis.add atom.tooltips.add(@icon_connected, {title: 'Disconnect from Netconf Server'})
    @whatis.add atom.tooltips.add(@link_netconf_rpc, {title: 'Send Netconf RPC'})
    @whatis.add atom.tooltips.add(@icon_pkg_settings, {title: 'Settings for ATOM netconf package'})
    @whatis.add atom.tooltips.add(@icon_examples, {title: 'Netconf Example Library'})

  updateUI: (editor) =>
    if editor instanceof TextEditor && editor.getGrammar().scopeName in ['text.plain.null-grammar', 'text.plain', 'text.xml', 'text.xml.xsl']
      @link_netconf_rpc.classList.add('active')
    else
      @link_netconf_rpc.classList.remove('active')

module.exports = document.registerElement('toolbar-netconf', prototype: NetconfToolbar.prototype, extends: 'div')

# EOF
