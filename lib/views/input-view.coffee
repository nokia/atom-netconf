###
  input-view.coffee
  Copyright (c) 2016 Nokia

  Note:
  This file is part of the netconf package for the ATOM Text Editor.

  Licensed under the MIT license
  See LICENSE.md delivered with this project for more information.
###

{Emitter, CompositeDisposable, TextEditor} = require 'atom'

module.exports =
  class InputView

    constructor: ->
      @view = document.createElement('div')
      @title = document.createElement('div')
      @editor = atom.workspace.buildTextEditor(mini: true)

      @view.appendChild @title
      @view.appendChild atom.views.getView(@editor)

      @panel = atom.workspace.addModalPanel item: @view, visible: false

      @emitter = new Emitter
      @subscriptions = new CompositeDisposable

      @subscriptions.add atom.commands.add 'atom-workspace', 'core:confirm': =>
        @emitter.emit 'on-confirm', @editor.getText().trim()
        @hide()

      @subscriptions.add atom.commands.add 'atom-workspace', 'core:cancel': =>
        @emitter.emit 'on-cancel'
        @hide()

    destroy: =>
      @subscriptions.dispose()
      @emitter.dispose()
      delete @editor
      delete @title
      delete @view

    onConfirm: (callback) =>
      @emitter.on 'on-confirm', callback

    onCancel: (callback) =>
      @emitter.on 'on-cancel', callback

    hide: ->
      @panel.hide()
      @destroy()

    show: ->
      @panel.show()
      atom.views.getView(@editor).focus()

    setCaption: (description) =>
      @title.textContent = description

    setDefault: (text) =>
      @editor.setText text
      @editor.selectAll()

    getValue: =>
      return @editor.getText().trim()

# EOF
