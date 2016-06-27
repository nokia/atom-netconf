###
  toolbar-xml.coffee
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

InputView = require './views/input-view'

class XmlToolbar extends HTMLElement

  initialize: (@statusBar) ->
    @debugging = atom.config.get 'atom-netconf.debug.netconf', false
    atom.config.observe 'atom-netconf.debug.netconf', (value) => this.debugging = value
    console.debug '::initialize()' if @debugging

    # --- member variables ----------------------------------------------------
    @xsltProcessor = undefined

    # --- user-interface icons ------------------------------------------------
    @icon_xslt = document.createElement('span')
    @icon_xslt.classList.add('icon', 'icon-code', 'active')
    @icon_xslt.addEventListener('click', @do_load_xslt.bind(this))
    @icon_xslt.addEventListener('contextmenu', @do_unload_xslt.bind(this))

    @icon_apply = document.createElement('span')
    @icon_apply.classList.add('icon', 'icon-gear', 'active')
    @icon_apply.addEventListener('click', @do_exec_xslt.bind(this))
    @icon_apply.addEventListener('contextmenu', @do_unload_xslt.bind(this))

    @icon_apply_csv = document.createElement('span')
    @icon_apply_csv.classList.add('icon', 'icon-gear', 'active')
    @icon_apply_csv.addEventListener('click', @do_xslt_to_csv.bind(this))
    @icon_apply_csv.addEventListener('contextmenu', @do_unload_xslt.bind(this))

    @icon_pretty = document.createElement('span')
    @icon_pretty.classList.add('icon', 'icon-alignment-unalign', 'active')
    @icon_pretty.addEventListener('click', @do_prettify.bind(this))

    @icon_xpath = document.createElement('span')
    @icon_xpath.classList.add('icon', 'icon-alignment-align', 'active')
    @icon_xpath.addEventListener('click', @do_exec_xpath.bind(this))

    # --- content and style of xml toolbar ------------------------------------
    @id = "toolbar://xml"
    @classList.add('netconf', 'inline-block', 'toolbar', 'hidden')
    @style.maxWidth = 'none'
    @appendChild @icon_xslt
    @appendChild @icon_apply
    @appendChild @icon_apply_csv
    @appendChild @icon_pretty
    @appendChild @icon_xpath

    @statusBarItem = @statusBar.addLeftTile(priority: 100, item: this)

  destroy: =>
    console.debug '::destroy()' if @debugging
    @statusBarItem?.destroy()
    @icon_xslt?.destroy()
    @icon_apply?.destroy()
    @icon_apply_csv?.destroy()
    @icon_pretty?.destroy()
    @icon_xpath?.destroy()

  register: (object) =>
    if (object instanceof Status)
      @status = object
    else if (object instanceof ncclient)
      @client = object

  # --- actions triggered by user ---------------------------------------------
  do_xslt_to_csv: =>
    console.debug '::do_xslt_to_csv()' if @debugging

    if not @status.xslt_loaded()
      console.log "need to load XSLT before applied" if @debugging
      @status.error("Need to load XSLT before apply")
      return

    editor = atom.workspace.getActiveTextEditor()
    filetype = editor.getGrammar().scopeName
    filepath = editor.getPath()
    file_ext = path.extname(filepath)
    filebase = path.basename(filepath, file_ext)

    # --- Create XML-DOM from CSV ---
    columns = editor.lineTextForBufferRow(0).split(',')
    xmldom = document.implementation.createDocument('', '', null)
    root = xmldom.createElement('csv-data')
    xmldom.appendChild root
    row=1
    while row<editor.getLastBufferRow()
      values = editor.lineTextForBufferRow(row).split(',')
      node = xmldom.createElement(filebase)
      node.setAttribute('index', "#{row++}")
      root.appendChild node
      col=0
      while col<values.length
        if values[col]!=''
          property =  xmldom.createElement(columns[col])
          property.appendChild xmldom.createTextNode(values[col])
          node.appendChild property
        col++

    # --- Apply XSLT ---
    result = xmltools.format(@xsltProcessor, xmldom)
    if result != undefined
      @status.result "responses/xslt-result.xml", result, 0
    else
      @status.error("Apply XSLT to XML failed")

  do_exec_xslt: =>
    console.debug '::do_exec_xslt()' if @debugging

    if not @status.xslt_loaded()
      console.log "need to load XSLT before applied" if @debugging
      @status.error("Need to load XSLT before apply")
      return

    editor = atom.workspace.getActiveTextEditor()
    result = xmltools.format(@xsltProcessor, editor.getText())

    if result != undefined
      @status.result "responses/xslt-result.xml", result, 0
    else
      @status.error("Apply XSLT to XML failed")

  do_load_xslt: =>
    console.debug '::do_load_xslt()' if @debugging
    editor = atom.workspace.getActiveTextEditor()
    xsltdom = (new DOMParser).parseFromString editor.getText(), "text/xml"
    if xsltdom!=null
      @xsltProcessor = new XSLTProcessor() if @xsltProcessor == undefined
      @xsltProcessor.importStylesheet xsltdom
      @status.update_xslt(editor.getTitle())
      @status.done()
    else
      @status.error("Failure while importing XSLT", details:"malformed xml document")

  do_unload_xslt: =>
    console.debug '::do_unload_xslt()' if @debugging
    @status.update_xslt(undefined)
    @status.done()

  do_prettify: ->
    console.debug '::do_prettify()' if @debugging
    editor = atom.workspace.getActiveTextEditor()
    filetype = editor.getGrammar().scopeName
    if filetype in ['text.plain.null-grammar', 'text.plain', 'text.xml', 'text.xml.xsl']
      xmldom = (new DOMParser).parseFromString editor.getText(), "text/xml"
      editor.setText xmltools.prettify xmldom
      editor.setSoftWrapped(false)
      @status.done()

  # do_exec_xpath2: =>
  #   OtherView = require './views/other-view'
  #
  #   getXPath = new OtherView()
  #   getXPath.setCaption 'Enter XPATH expression:'
  #   getXPath.setDefault @get_xpath(ignoreNS=true)
  #   getXPath.show()
  #   getXPath.onConfirm (xpath) =>
  #     console.log getXPath.getValue()

  do_exec_xpath: =>
    console.debug '::do_exec_xpath()' if @debugging
    # @status.info("XML xpath not yet implemented!")

    getXPath = new InputView()
    getXPath.setCaption 'Enter XPATH expression:'
    getXPath.setDefault @get_xpath(ignoreNS=true)
    getXPath.show()
    getXPath.onConfirm (xpath) =>
      editor = atom.workspace.getActiveTextEditor()
      xmldom = (new DOMParser).parseFromString editor.getText(), "text/xml"
      xsltdom = (new DOMParser).parseFromString xmltools.xslt_remove_ns, "text/xml"

      if xmldom==null or xsltdom==null
        @status.warning("Parser Error for XML")
        return

      xsltprc = new XSLTProcessor()
      xsltprc.importStylesheet xsltdom
      xmldoc = xsltprc.transformToDocument(xmldom)

      elements = []
      headers = []

      # Evaluate XPATH Statement

      try
        items = document.evaluate(xpath, xmldoc, null, XPathResult.UNORDERED_NODE_ITERATOR_TYPE, null)
      catch e
        @status.error('XSLT Execution Error', "'#{xpath}' is not a valid XPATH expression.")
        console.log e
        return

      # XMLDOM HELP
      # nodeType
      #  1 ELEMENT_NODE
      #  3 TEXT_NODE
      # attributes / methods
      #  node.firstChild
      #  node.lastChild
      #  node.hasChildNodes()
      #  node.childNodes
      #  node.children[0]

      # Generate CSV from XPATH Result
      enableEmptyPresence = false
      while item=items.iterateNext()
        attr = {}
        ncnt = {}
        for node in item.childNodes
          if ncnt[node.localName]?
            ncnt[node.localName] += 1
            nodeName = node.localName + "[#{ncnt[node.localName]}]"
          else
            ncnt[node.localName] = 1
            nodeName = node.localName

          if node.nodeType==1 and node.childNodes.length==0 and enableEmptyPresence
            attr[nodeName] = "(present)"
            headers.push nodeName if nodeName not in headers

          if node.nodeType==1 and node.childNodes.length==1 and node.firstChild.nodeType==3
            if /^\s*$/.test(node.textContent)
              if enableEmptyPresence
                attr[nodeName] = "(present)"
                headers.push nodeName if nodeName not in headers
            else
              attr[nodeName] = node.textContent
              headers.push nodeName if nodeName not in headers

          if node.nodeType==1 and node.childNodes.length>1
            ccnt = {}
            for child in node.childNodes
              if ccnt[child.localName]?
                ccnt[child.localName] += 1
                childName = nodeName + '/' + child.localName + "[#{ccnt[child.localName]}]"
              else
                ccnt[child.localName] = 1
                childName = nodeName + '/' + child.localName

              if child.nodeType==1 and child.childNodes.length==0 and enableEmptyPresence
                attr[childName] = "(present)"
                headers.push childName if childName not in headers

              if child.nodeType==1 and child.childNodes.length==1 and child.firstChild.nodeType==3
                if /^\s*$/.test(child.textContent)
                  if enableEmptyPresence
                    attr[childName] = "(present)"
                    headers.push childName if childName not in headers
                else
                  attr[childName] = child.textContent
                  headers.push childName if childName not in headers

        elements.push attr if Object.keys(attr).length > 0

      if elements.length == 0
        @status.error("XPATH result is empty")
        return

      if headers.length == 0
        @status.error("XPATH does not match a table")
        return

      result = headers.join(',') + '\n'
      for obj in elements
        tmp = []
        for col in headers
          if obj[col]?
            tmp.push obj[col]
          else
            tmp.push ""
        result += tmp.join(',') + '\n'

      p = atom.workspace.open()
      Promise.resolve(p).then (editor) =>
        editor.shouldPromptToSave = ({windowCloseRequested}={}) -> false
        editor.setText result
        editor.moveToTop()

  get_node_xpath: (node) ->
    xpath=""
    while node and node.nodeType==1
      # xpath = "/" + node.tagName + xpath
      # xpath = "/" + node.localName + xpath
      xpath = "/*[local-name()='" + node.localName + "']" + xpath
      node = node.parentNode
    return xpath

  get_xpath: (ignoreNS=false) ->
    editor = atom.workspace.getActiveTextEditor()
    buf  = editor.getBuffer().getText()
    end  = editor.getBuffer().characterIndexForPosition(editor.getCursorBufferPosition())-1
    size = buf.length

    pos = 0
    tags = []
    while (pos <= end)
      if (buf[pos]=='<') and (pos < size-5)
        if buf[pos+1]=="!" and buf[pos+2]=="-" and buf[pos+3]=="-"
          # skip <!-- -->
          pos += 5
          pos++ while pos<size and buf[pos-2]!="-" or buf[pos-1]!="-" or buf[pos]!=">"
          pos++
        else if buf[pos+1]=="?"
          # skip <? ... ?>
          pos += 3
          pos++ while buf[pos-1]!="?" or buf[pos]!=">"
          pos++
        else if buf[pos+1]=='/'
          # </tag> found
          pos += 2
          pos++ while buf[pos]!='>'
          tags.pop() if pos<=end
          pos++
        else
          # <tag/> or <tag> found
          pos +=1
          len = 0
          while buf[pos+len] not in ['\t', '\n', '\r', ' ', '/', '>']
            len++
            if buf[pos+len]==':' and ignoreNS
              pos += len+1
              len = 0
          tag = buf.substring(pos, pos+len)
          pos += len
          pos++ while buf[pos]!='>'

          tags.push(tag) if (buf[pos-1]!='/') or (pos>end)
          pos++
      else
        pos++

    xpath = '/' + tags.join('/')
    return xpath




  do_smart_select: ->
    console.debug '::do_smart_select()' if @debugging

    # todo:
    #   selection of quoted text 'xxx' or "xxx"
    #   selection of text values <tag>xxx</tag>
    #   handling of <![CDATA[...]]>
    #   processing of special characters
    #     in text, attributes, comments, cdata, processing instructions

    editor = atom.workspace.getActiveTextEditor()
    buffer = editor.getBuffer()

    buf  = buffer.getText()
    pos1 = buffer.characterIndexForPosition(editor.getCursorBufferPosition())-1
    size = buf.length

    level = 1
    while (level > 0) and (pos1 >= 0)
      if (buf[pos1]=='>') and (pos1 > 5)

        if buf[pos1-1]=="-" and buf[pos1-2]=="-"
          # find matching <!-- -->
          pos1 -= 4
          pos1-- while pos1>0 and (buf[pos1]!="<" or buf[pos1+1]!="!" or buf[pos1+2]!="-" or buf[pos1+3]!="-")
          pos1--
        else if buf[pos1-1]=="?"
          # find matching <? ... ?>
          pos1 -= 3
          pos1-- while pos1>0 and (buf[pos1]!="<" or buf[pos1+1]!="?")
          pos1--
        else if buf[pos1-1]=='/'
          # find matching <tag/>
          pos1 -= 3
          pos1-- while pos1>0 and buf[pos1]!='<'
          pos1--
        else
          pos1 -= 3
          pos1-- while pos1>0 and buf[pos1]!='<'
          if buf[pos1+1]=='/'
            level += 1
          else
            level -= 1
          pos1--
      else if level==1 and (buf[pos1]=='<') and (buf[pos1+1]!='/')
        pos1--
        break
      else
        pos1--

    pos1++
    pos2=pos1

    level = 0
    while (pos2 < size)
      if (buf[pos2]=='<') and (pos2 < size-5)

        if buf[pos2+1]=="!" and buf[pos2+2]=="-" and buf[pos2+3]=="-"
          # <!-- --> found, skip to start
          pos2 += 5
          pos2++ while pos2<size and buf[pos2-2]!="-" or buf[pos2-1]!="-" or buf[pos2]!=">"
          pos2++
        else if buf[pos2+1]=="?"
          # <? ... ?> found, skip to start
          pos2 += 3
          pos2++ while buf[pos2-1]!="?" or buf[pos2]!=">"
          pos2++
        else if buf[pos2+1]=='/'
          # </tag> found
          pos2 += 2
          pos2++ while buf[pos2]!='>'
          pos2++
          level -= 1
        else
          # <tag/> or <tag> found
          pos2 += 2
          pos2++ while buf[pos2]!='>'
          level++ if buf[pos2-1]!='/'
          pos2++

        break if level==0
      else
        pos2++

    # console.log buf.substring(pos1, pos2)
    x1=buffer.positionForCharacterIndex(pos1)
    x2=buffer.positionForCharacterIndex(pos2)

    editor.setSelectedBufferRange([x1, x2])


  # --- update user-interface tasks -------------------------------------------
  tooltips: (@whatis) =>
    @whatis.add atom.tooltips.add(@icon_xslt, {title: 'Import XSLT'})
    @whatis.add atom.tooltips.add(@icon_apply, {title: 'Apply XSLT to XML'})
    @whatis.add atom.tooltips.add(@icon_apply_csv, {title: 'Apply XSLT to CSV'})
    @whatis.add atom.tooltips.add(@icon_pretty, {title: 'Prettify XML'})
    @whatis.add atom.tooltips.add(@icon_xpath, {title: "Execute XPATH"})

  updateUI: (editor) =>
    if editor instanceof TextEditor
      editor = atom.workspace.getActiveTextEditor()
      filetype = editor.getGrammar().scopeName
      filepath = editor.getPath()
      file_ext = path.extname(filepath)
      filebase = path.basename(filepath, file_ext)

      console.log filetype
      console.log file_ext
      if filetype in ['text.xml.xsl']
        @classList.remove('hidden')
        @icon_xslt.classList.remove('hidden')
        @icon_apply.classList.add('hidden')
        @icon_apply_csv.classList.add('hidden')
        @icon_pretty.classList.remove('hidden')
        @icon_xpath.classList.add('hidden')
      else if filetype in ['text.xml']
        @classList.remove('hidden')
        @icon_xslt.classList.add('hidden')
        if @status.xslt_loaded()
          @icon_apply.classList.remove('hidden')
        else
          @icon_apply.classList.add('hidden')
        @icon_apply_csv.classList.add('hidden')
        @icon_pretty.classList.remove('hidden')
        @icon_xpath.classList.remove('hidden')
      else if filetype in ['text.plain.null-grammar', 'text.plain'] and file_ext in ['.csv'] and @status.xslt_loaded()
        @classList.remove('hidden')
        @icon_xslt.classList.add('hidden')
        @icon_apply.classList.add('hidden')
        @icon_apply_csv.classList.remove('hidden')
        @icon_pretty.classList.add('hidden')
        @icon_xpath.classList.add('hidden')
      else
        # other filetype then xml, csv, text
        @classList.add('hidden')
    else
      # this is no text editor
      @classList.add('hidden')

module.exports = document.registerElement('toolbar-xml', prototype: XmlToolbar.prototype, extends: 'div')

# EOF
