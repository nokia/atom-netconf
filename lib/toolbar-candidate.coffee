###
  toolbar-candidate.coffee
  Copyright (c) 2016 Nokia

  Note:
  This file is part of the netconf package for the ATOM Text Editor.

  Licensed under the MIT license
  See LICENSE.md delivered with this project for more information.
###

{CompositeDisposable, TextEditor} = require 'atom'
ncclient = require './ncclient'
Status = require './statusbar-netconf'




class CandidateToolbar extends HTMLElement

  initialize: (@statusBar) ->
    @debugging = atom.config.get 'atom-netconf.debug.netconf', false
    atom.config.observe 'atom-netconf.debug.netconf', (value) => this.debugging = value
    console.debug '::initialize()' if @debugging

    # --- user-interface icons ------------------------------------------------
    @icon_lock = document.createElement('span')
    @icon_lock.classList.add('icon', 'icon-key', 'active')
    @icon_lock.addEventListener('click', @do_lock.bind(this))

    @icon_validate = document.createElement('span')
    @icon_validate.classList.add('icon', 'icon-checklist', 'active')
    @icon_validate.addEventListener('click', @do_validate.bind(this))

    @icon_discard = document.createElement('span')
    @icon_discard.classList.add('icon', 'icon-circle-slash', 'active')
    @icon_discard.addEventListener('click', @do_discard.bind(this))

    @icon_commit = document.createElement('span')
    @icon_commit.classList.add('icon', 'icon-check', 'active')
    @icon_commit.addEventListener('click', @do_commit.bind(this))

    @icon_compare = document.createElement('span')
    @icon_compare.classList.add('icon', 'icon-versions', 'active')
    @icon_compare.addEventListener('click', @do_compare.bind(this))

    # --- content and style of candidate toolbar ------------------------------
    @id = "toolbar://candidate"
    @classList.add('netconf', 'inline-block', 'toolbar', 'hidden')
    @style.maxWidth = 'none'
    @appendChild @icon_lock
    @appendChild @icon_validate
    @appendChild @icon_discard
    @appendChild @icon_commit
    @appendChild @icon_compare

    @statusBarItem = @statusBar.addLeftTile(priority: 100, item: this)

  register: (object) =>
    if (object instanceof Status)
      @status = object
    else if (object instanceof ncclient)
      @client = object
      @client.on 'end', =>
        @classList.add('hidden')
        @icon_validate.classList.add('hidden')
      @client.on 'error', =>
        @classList.add('hidden')
        @icon_validate.classList.add('hidden')
      @client.on 'support:candidate', => @classList.remove('hidden')
      @client.on 'support:validate', => @icon_validate.classList.remove('hidden')

  destroy: =>
    console.debug '::destroy()' if @debugging
    @statusBarItem?.destroy()
    @icon_lock?.destroy()
    @icon_validate?.destroy()
    @icon_discard?.destroy()
    @icon_commit?.destroy()
    @icon_compare?.destroy()

  # --- actions triggered by user ---------------------------------------------
  do_lock: =>
    console.debug "::do_lock()" if @debugging
    if @client?.isLocked()
      @client.unlock()
    else
      @client.lock()

  do_validate: =>
    console.debug "::do_validate()" if @debugging
    @client.validate()

  do_discard: =>
    console.debug "::do_discard()" if @debugging
    @client.discard()

  do_commit: =>
    console.debug "::do_commit()" if @debugging
    @client.commit()

  do_compare: =>
    console.debug '::do_compare()' if @debugging

    if @client.isNokiaSROS
      xmlreq = """<?xml version="1.0" encoding="UTF-8"?>
        <rpc message-id="get-config running" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
          <get-config>
            <source><running/></source>
            <filter type="subtree">
              <configure xmlns="urn:nokia.com:sros:ns:yang:sr:conf" />
            </filter>
          </get-config>
        </rpc>"""
    else
      xmlreq = """<?xml version="1.0" encoding="UTF-8"?>
        <rpc message-id="get-config running" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
          <get-config>
            <source><running/></source>
          </get-config>
        </rpc>"""

    @client.rpc xmlreq, 'data', (id, running) =>
      if @client.isNokiaSROS
        xmlreq = """<?xml version="1.0" encoding="UTF-8"?>
          <rpc message-id="get-config candidate" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
            <get-config>
              <source><candidate/></source>
              <filter type="subtree">
                <configure xmlns="urn:nokia.com:sros:ns:yang:sr:conf" />
              </filter>
            </get-config>
          </rpc>"""
      else
        xmlreq = """<?xml version="1.0" encoding="UTF-8"?>
          <rpc message-id="get-config candidate" xmlns="urn:ietf:params:xml:ns:netconf:base:1.0">
            <get-config>
              <source><candidate/></source>
            </get-config>
          </rpc>"""

      @client.rpc xmlreq, 'data', (id, candidate) =>
        foldLevel =  atom.config.get 'atom-netconf.behavior.xmlFoldLevel'
        @status.compare running, candidate, foldLevel-1

  # --- update user-interface tasks -------------------------------------------
  tooltips: (@whatis) =>
    @whatis.add atom.tooltips.add(@icon_lock, {title: '(Un-)Lock &lt;candidate&gt;'})
    @whatis.add atom.tooltips.add(@icon_validate, {title: 'Validate &lt;candidate&gt;'})
    @whatis.add atom.tooltips.add(@icon_discard, {title: 'Discard changes'})
    @whatis.add atom.tooltips.add(@icon_commit, {title: 'Commit changes'})
    @whatis.add atom.tooltips.add(@icon_compare, {title: 'Compare &lt;running&gt; vs &lt;candidate&gt;'})

  updateUI: (editor) =>
    # nothing to do for candidate toolbar

module.exports = document.registerElement('toolbar-candidate', prototype: CandidateToolbar.prototype, extends: 'div')

# EOF
