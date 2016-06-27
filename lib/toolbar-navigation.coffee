###
  toolbar-navigation.coffee
  Copyright (c) 2016 Nokia

  Note:
  This file is part of the netconf package for the ATOM Text Editor.

  Licensed under the MIT license
  See LICENSE.md delivered with this project for more information.
###

{CompositeDisposable, TextEditor} = require 'atom'
ncclient = require './ncclient'
Status = require './statusbar-netconf'




class NavigationToolbar extends HTMLElement

  initialize: (@statusBar) ->
    @debugging = atom.config.get 'atom-netconf.debug.netconf', false
    atom.config.observe 'atom-netconf.debug.netconf', (value) => this.debugging = value
    console.debug '::initialize()' if @debugging

    # --- user-interface icons ------------------------------------------------
    @icon_prev = document.createElement('span')
    @icon_prev.classList.add('icon', 'icon-playback-rewind', 'active')
    @icon_prev.addEventListener('click', @do_go_previous.bind(this))

    @icon_next = document.createElement('span')
    @icon_next.classList.add('icon', 'icon-playback-fast-forward', 'active')
    @icon_next.addEventListener('click', @do_go_next.bind(this))

    # --- content and style of navigation toolbar -----------------------------
    @id = "toolbar://navigation"
    @classList.add('netconf', 'inline-block', 'toolbar', 'hidden')
    @style.maxWidth = 'none'
    @appendChild @icon_prev
    @appendChild @icon_next

    @statusBarItem = @statusBar.addLeftTile(priority: 100, item: this)

  destroy: =>
    console.debug '::destroy()' if @debugging
    @statusBarItem?.destroy()
    @icon_prev?.destroy()
    @icon_next?.destroy()

  register: (status_element) =>
    # must be from class Status
    @status = status_element

  # --- actions triggered by user ---------------------------------------------
  do_go_next: ->
    console.debug '::do_go_next()' if @debugging

    editor = atom.workspace.getActiveTextEditor()
    now = editor.getCursorBufferPosition().row
    nxt = editor.getLastBufferRow()
    editor.getLineDecorations().forEach (obj) ->
      pos = obj.getMarker().getStartBufferPosition().row
      nxt = pos if (pos < nxt) && (pos > now)
    editor.setCursorBufferPosition([nxt,0])
    @status.done()

  do_go_previous: ->
    console.debug '::do_go_previous()' if @debugging

    editor = atom.workspace.getActiveTextEditor()
    now = editor.getCursorBufferPosition().row
    prv = 0
    editor.getLineDecorations().forEach (obj) ->
      pos = obj.getMarker().getStartBufferPosition().row
      prv = pos if (pos > prv) && (pos < now) && obj.properties.class!="cursor-line"
    editor.setCursorBufferPosition([prv,0])
    @status.done()

  # --- update user-interface tasks -------------------------------------------
  tooltips: (@whatis) =>
    @whatis.add atom.tooltips.add(@icon_prev, {title: 'goto previous difference'})
    @whatis.add atom.tooltips.add(@icon_next, {title: 'goto next difference'})

  updateUI: (editor) =>
    if (editor instanceof TextEditor)
      if editor.getDecorations({class: 'added'}).length > 1
        @classList.remove('hidden')
      else if editor.getDecorations({class: 'modified'}).length > 1
        @classList.remove('hidden')
      else if editor.getDecorations({class: 'removed'}).length > 1
        @classList.remove('hidden')
      else
        @classList.add('hidden')
    else
      @classList.add('hidden')

module.exports = document.registerElement('toolbar-navigation', prototype: NavigationToolbar.prototype, extends: 'div')

# EOF
