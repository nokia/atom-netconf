###
  statusbar-netconf.coffee
  Copyright (c) 2016 Nokia

  Note:
  This file is part of the netconf package for the ATOM Text Editor.

  Licensed under the MIT license
  See LICENSE.md delivered with this project for more information.
###

{CompositeDisposable, TextEditor} = require 'atom'
xmltools = require './xmltools'

jsdiff = require 'diff'
path = require 'path'

class Status extends HTMLElement

  initialize: (@statusBar, @client) ->
    @debugging = atom.config.get 'atom-netconf.debug.netconf', false
    atom.config.observe 'atom-netconf.debug.netconf', (value) => this.debugging = value
    console.debug '::initialize()' if @debugging

    # --- member variables ----------------------------------------------------
    @xsltName = undefined
    @wlist = []   # list of warnings
    @nlist = []   # list of notifications

    # --- load audio-files ----------------------------------------------------
    pkgdir = atom.packages.resolvePackagePath('atom-netconf')
    @audio_connect    = new Audio(path.join(pkgdir, 'audio', 'connect.oga'))
    @audio_disconnect = new Audio(path.join(pkgdir, 'audio', 'disconnect.oga'))
    @audio_success    = new Audio(path.join(pkgdir, 'audio', 'success.oga'))
    @audio_click      = new Audio(path.join(pkgdir, 'audio', 'click.oga'))
    @audio_info       = new Audio(path.join(pkgdir, 'audio', 'info.oga'))
    @audio_event      = new Audio(path.join(pkgdir, 'audio', 'event.oga'))
    @audio_message    = new Audio(path.join(pkgdir, 'audio', 'message.oga'))
    @audio_warning    = new Audio(path.join(pkgdir, 'audio', 'warning.oga'))
    @audio_error      = new Audio(path.join(pkgdir, 'audio', 'error.oga'))
    @audio_critical   = new Audio(path.join(pkgdir, 'audio', 'critical.oga'))

    # --- user-interface icons ------------------------------------------------
    @info_connect = document.createElement('span')
    @info_connect.classList.add('icon', 'icon-terminal', 'subtle', 'hidden')

    @info_lock = document.createElement('span')
    @info_lock.classList.add('icon', 'icon-lock', 'info', 'hidden')

    @info_xslt = document.createElement('span')
    @info_xslt.classList.add('icon', 'icon-file-code', 'info', 'hidden')

    @info_busy = document.createElement('span')
    @info_busy.classList.add('loading', 'loading-spinner-tiny', 'busy', 'hidden')

    @info_msgs = document.createElement('span')
    @info_msgs.classList.add('icon', 'icon-comment', 'info', 'active', 'hidden')
    @info_msgs.addEventListener('click', @show_notifications.bind(this))

    # --- content and style of netconf statusbar ------------------------------
    @id = "statusbar://netconf"
    @classList.add('inline-block', 'statusbar')
    @style.maxWidth = 'none'
    @appendChild @info_busy
    @appendChild @info_connect
    @appendChild @info_lock
    @appendChild @info_xslt
    @appendChild @info_msgs

    @statusBarItem = @statusBar.addRightTile(priority: 200, item: this)

  register: (@client) =>
    @client.on 'warning',     @warning.bind(this)
    @client.on 'error',       @error.bind(this)
    @client.on 'rpc-ok',      @rpcOk.bind(this)
    @client.on 'rpc-error',   @rpcError.bind(this)
    @client.on 'rpc-timeout', @rpcTimeout.bind(this)
    @client.on 'ssh-banner',   @sshBanner.bind(this)
    @client.on 'ssh-greeting', @sshGreeting.bind(this)
    @client.on 'notification', @notification.bind(this)
    @client.on 'data', (size) => @info_connect.textContent=size
    @client.on 'connected', (hello) =>
      @info_connect.classList.remove('hidden')
      @info_busy.classList.add('hidden')
      @audio_connect.play() if atom.config.get 'atom-netconf.behavior.audio'
      if atom.config.get 'atom-netconf.behavior.sampleHello'
        setTimeout (=>@result("responses/hello.xml", hello, 1)), 1000
    @client.on 'end', =>
      @info_connect.classList.add('hidden')
      @info_busy.classList.add('hidden')
      if atom.config.get 'atom-netconf.behavior.audio'
        setTimeout (=> @audio_disconnect.play()), 1000
    @client.on 'idle', => @info_busy.classList.add('hidden')
    @client.on 'busy', => @info_busy.classList.remove('hidden')
    @client.on 'locked', @locked.bind(this)

  destroy: =>
    console.debug '::destroy()' if @debugging
    @statusBarItem?.destroy()
    @info_busy?.destroy()
    @info_connect?.destroy()
    @info_lock?.destroy()
    @info_xslt?.destroy()
    @info_msgs?.destroy()

  # --- actions triggered by user ---------------------------------------------
  show_notifications: =>
    console.debug '::show_notifications()' if @debugging

    current_pane = atom.workspace.getActivePane()
    current_editor = atom.workspace.getActiveTextEditor()

    if atom.config.get 'atom-netconf.behavior.resultUntitled'
      filename=""
    else
      filename="notifications.xml"

    p = atom.workspace.open("notifications.xml", {split:atom.config.get 'atom-netconf.behavior.splitPane', activatePane:false})
    Promise.resolve(p).then (editor) =>
      editor.shouldPromptToSave = ({windowCloseRequested}={}) -> false
      editor.setGrammar atom.grammars.grammarForScopeName 'text.xml'

      xmldom = document.implementation.createDocument('', '', null)
      root = xmldom.createElement('netconf-events')
      xmldom.appendChild root
      root.appendChild node.firstChild for node in @nlist

      editor.setText xmltools.prettify xmldom

      @nlist = []
      if not atom.config.get 'atom-netconf.behavior.resultFocus'
        current_pane.activate()
        current_pane.activateItem(current_editor)

    @info_msgs.classList.add('hidden')

  # --- support methods to execute diff comparing datastore -------------------
  get_word_differences: (startline, words, oldtxt, newtxt) ->
    diff = jsdiff.diffWordsWithSpace(oldtxt, newtxt)

    buffer = ""
    line = startline
    pos = 0

    idx = 0
    while idx < diff.length
      part = diff[idx++]

      if part.added
        mode = 'added'
      else if part.removed
        if (idx<diff.length) && diff[idx].added && atom.config.get 'atom-netconf.transactional.diffMod'
          # part modified, only display the new stuff
          part = diff[idx++]
          mode = 'modified'
        else
          mode = 'removed'
      else
        mode = 'unchanged'

      lines = part.value.split '\n'

      j = 0
      for txt in lines
        words.push [[[line+j, pos], [line+j, pos+txt.length]], mode] unless mode=='unchanged'
        if j++ < lines.length-1
          pos=0
        else
          pos+=txt.length

      line += lines.length-1
      buffer += part.value

    return buffer

  get_differences: (oldtxt, newtxt) ->
    diff = jsdiff.diffLines(oldtxt, newtxt)

    line1 = 0
    line2 = 0
    words = []
    lines = []
    buffer = ""

    idx = 0
    while idx < diff.length
      part = diff[idx++]
      line1 = line2

      if part.added
        mode = 'added'
      else if part.removed
        if (idx<diff.length) && diff[idx].added
          # part modified, only display the new stuff
          if atom.config.get 'atom-netconf.transactional.diffWords'
            wbuf = @get_word_differences(line1, words, part.value, diff[idx++].value)
            part.value = wbuf
            part.count = wbuf.split('\n').length-1
            mode = 'modified'
          else if atom.config.get 'atom-netconf.transactional.diffMod'
            part = diff[idx++]
            mode = 'modified'
          else
            mode = 'removed'
        else
          mode = 'removed'
      else
        mode = 'unchanged'

      line2 += part.count
      buffer += part.value
      lines.push [[[line1, 0], [line2, 0]], mode] unless mode=='unchanged'

    return [buffer, lines, words]

  # --- actions triggered by other classes ------------------------------------
  update_xslt: (filename) =>
    if filename!=undefined
      @info_xslt.classList.remove('hidden')
    else
      @info_xslt.classList.add('hidden')
    @xsltName = filename

  xslt_loaded: =>
    return @xsltName?

  toggle_lock: =>
    @info_lock.classList.toggle('hidden')

  is_unlocked: =>
    return @info_lock.classList.contains('hidden')

  result: (filename, content, foldLevel=undefined) =>
    console.debug '::result()' if @debugging
    current_pane = atom.workspace.getActivePane()
    current_editor = atom.workspace.getActiveTextEditor()

    filename="" if atom.config.get 'atom-netconf.behavior.resultUntitled'

    p = atom.workspace.open(filename, {split:atom.config.get 'atom-netconf.behavior.splitPane', activatePane:false})
    Promise.resolve(p).then (editor) =>
      editor.shouldPromptToSave = ({windowCloseRequested}={}) -> false
      editor.setGrammar atom.grammars.grammarForScopeName 'text.xml'
      # todo: for xslt transformation it might be that result is not XML

      editor.setText content
      editor.moveToTop()

      if filename != ""
        editor.getDecorations({type: 'block'}).forEach (obj) -> obj.getMarker().destroy()

      if atom.config.get 'atom-netconf.behavior.resultReadOnly'
        atom.views.getView(editor).removeAttribute('tabindex');
        editor.getDecorations({type: 'line', class: 'cursor-line'}).forEach (obj) -> obj.destroy()

      element = document.createElement('div')
      element.classList.add('title')
      marker = editor.markScreenPosition [editor.getLineCount(),0], {invalidate: 'never', persistent: true}
      editor.decorateMarker marker, {type: 'block', position: 'after', item: element}

      if atom.config.get('atom-netconf.behavior.xmlProcessor')=='minify'
        editor.setSoftWrapped(true)

      if foldLevel==undefined
        foldLevel =  atom.config.get 'netconf.behavior.xmlFoldLevel'
      if foldLevel>0
        editor.foldAllAtIndentLevel(foldLevel)

      if not atom.config.get 'atom-netconf.behavior.resultFocus'
        current_pane.activate()
        current_pane.activateItem(current_editor)

      @audio_event.play() if atom.config.get 'atom-netconf.behavior.audio'

  compare: (oldcfg, newcfg, foldLevel=undefined) =>
    console.debug '::compare()' if @debugging

    [buffer, lines, words] = @get_differences oldcfg, newcfg

    if oldcfg == newcfg
      @info("No changes contained in candidate datastore!")
    else
      @info(lines.length + " change(s) found in candidate datastore.")

    current_pane = atom.workspace.getActivePane()
    current_editor = atom.workspace.getActiveTextEditor()

    if atom.config.get 'atom-netconf.behavior.resultUntitled'
      filename = ""
    else
      filename = "responses/merge.xml"

    p = atom.workspace.open(filename, {split:atom.config.get 'atom-netconf.behavior.splitPane', activatePane:false})
    Promise.resolve(p).then (editor) =>
      editor.shouldPromptToSave = ({windowCloseRequested}={}) -> false
      editor.setGrammar atom.grammars.grammarForScopeName 'text.xml'

      editor.setText buffer
      editor.moveToTop()

      if filename != ""
        editor.getDecorations({type: 'block'}).forEach (obj) -> obj.getMarker().destroy()
        editor.getDecorations({class: 'added'}).forEach (obj) -> obj.getMarker().destroy()
        editor.getDecorations({class: 'modified'}).forEach (obj) -> obj.getMarker().destroy()
        editor.getDecorations({class: 'removed'}).forEach (obj) -> obj.getMarker().destroy()

      if atom.config.get 'atom-netconf.behavior.resultReadOnly'
        atom.views.getView(editor).removeAttribute('tabindex');
        editor.getDecorations({type: 'line', class: 'cursor-line'}).forEach (obj) -> obj.destroy()

      markers = []
      for line in lines
        marker = editor.markBufferRange line[0], {invalidate: 'never', persistent: true}
        editor.decorateMarker marker, {type: 'line-number', class: line[1]}
        editor.decorateMarker marker, {type: 'line', class: line[1]}
        markers.push marker

      for word in words
        marker = editor.markBufferRange word[0], {invalidate: 'never', persistent: true}
        editor.decorateMarker marker, {type: 'highlight', class: word[1]}
        markers.push marker

      element = document.createElement('div')
      element.classList.add('title')
      marker = editor.markScreenPosition [editor.getLineCount(),0], {invalidate: 'never', persistent: true}
      editor.decorateMarker marker, {type: 'block', position: 'after', item: element}

      if foldLevel?
       editor.foldAllAtIndentLevel(foldLevel)

      if not atom.config.get 'atom-netconf.behavior.resultFocus'
        current_pane.activate()
        current_pane.activateItem(current_editor)

      if atom.config.get 'atom-netconf.behavior.audio'
        setTimeout (=>@audio_event.play()), 1000

  done: =>
    @audio_click.play() if atom.config.get 'atom-netconf.behavior.audio'

  click: =>
    @audio_click.play()

  # --- event handlers --------------------------------------------------------

  notification: (xmldom) =>
    @nlist.push xmldom
    @info_msgs.classList.remove('hidden')
    @info_msgs.textContent = @nlist.length
    @audio_message.play() if atom.config.get 'atom-netconf.behavior.audio'

  info: (message, details) =>
    atom.notifications.addInfo(message, detail:details, dismissable: true)
    @audio_info.play() if atom.config.get 'atom-netconf.behavior.audio'

  warning: (message, details) =>
    atom.notifications.addWarning(message, detail:details, dismissable: true)
    @audio_warning.play() if atom.config.get 'atom-netconf.behavior.audio'

  error: (message, details) =>
    atom.notifications.addError(message, detail:details, dismissable: true)
    @audio_error.play() if atom.config.get 'atom-netconf.behavior.audio'

  rpcOk: (msgid) =>
    atom.notifications.addSuccess("netconf #{msgid}: ok", dismissable: false)
    @audio_success.play() if atom.config.get 'atom-netconf.behavior.audio'

  rpcError: (msgid, xmldom) =>
    if xmldom instanceof XMLDocument
      atom.notifications.addWarning("netconf #{msgid}: failed with rpc-error", detail: xmltools.rpc_error(xmldom), dismissable: true)
    @audio_warning.play() if atom.config.get 'atom-netconf.behavior.audio'

  sshBanner: (message) =>
    if atom.config.get 'atom-netconf.behavior.displayBanner'
      atom.notifications.addInfo('SSH Authentication Banner', detail:message, dismissable: false)
      @audio_info.play() if atom.config.get 'atom-netconf.behavior.audio'

  sshGreeting: (message) =>
    if atom.config.get 'atom-netconf.behavior.displayBanner'
      atom.notifications.addInfo('SSH Greeting', detail:message, dismissable: false)
      @audio_info.play() if atom.config.get 'atom-netconf.behavior.audio'

  rpcTimeout: (msgid) =>
    atom.notifications.addWarning("netconf #{msgid}: failed with timeout", dismissable: true)
    @audio_warning.play() if atom.config.get 'atom-netconf.behavior.audio'

  locked: (visible) =>
    if visible
      @info_lock.classList.remove('hidden')
    else
      @info_lock.classList.add('hidden')

  # --- update user-interface tasks -------------------------------------------
  tooltip_callback_xslt: =>
    return "#{@xsltName} loaded"

  tooltips: (@whatis) =>
    @whatis.add atom.tooltips.add(@info_connect, {title: 'Netconf session is connected'})
    @whatis.add atom.tooltips.add(@info_lock, {title: 'Candidate is locked'})
    @whatis.add atom.tooltips.add(@info_xslt, {title: @tooltip_callback_xslt.bind(this)})
    @whatis.add atom.tooltips.add(@info_busy, {title: 'loading...'})
    @whatis.add atom.tooltips.add(@info_msgs, {title: 'Notifications received'})

module.exports = document.registerElement('statusbar-netconf', prototype: Status.prototype, extends: 'div')

# EOF
