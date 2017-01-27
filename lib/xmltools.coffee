###
  xmltools.coffee
  Copyright (c) 2016 Nokia

  Note:
  This file is part of the netconf package for the ATOM Text Editor.

  Licensed under the MIT license
  See LICENSE.md delivered with this project for more information.
###

module.exports =

class xmltools
  @xslt_prettify = """<?xml version="1.0" encoding="UTF-8"?>
    <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
      <xsl:output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>
      <xsl:strip-space elements="*"/>
      <xsl:template match="/">
        <xsl:copy-of select="."/>
      </xsl:template>
    </xsl:stylesheet>"""

  @xslt_minify = """<?xml version="1.0" encoding="UTF-8"?>
    <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
      <xsl:output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="no"/>
      <xsl:strip-space elements="*"/>
      <xsl:template match="/">
        <xsl:copy-of select="."/>
      </xsl:template>
    </xsl:stylesheet>"""

  @xslt_rpc_error = """<?xml version="1.0" encoding="UTF-8"?>
    <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
      <xsl:output method="xml" indent="yes"/>
      <xsl:strip-space elements="*"/>
      <xsl:template match="/">
        <rpc-errors>
          <xsl:copy-of xmlns:nc="urn:ietf:params:xml:ns:netconf:base:1.0" select="//nc:rpc-error"/>
        </rpc-errors>
      </xsl:template>
    </xsl:stylesheet>"""

  @xslt_data_node = """<?xml version="1.0" encoding="UTF-8"?>
    <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
      <xsl:output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>
      <xsl:strip-space elements="*"/>
      <xsl:template match="/">
        <xsl:copy-of xmlns:nc="urn:ietf:params:xml:ns:netconf:base:1.0" select="nc:rpc-reply/nc:data"/>
      </xsl:template>
    </xsl:stylesheet>"""

  @xslt_config_sros = """<?xml version="1.0" encoding="UTF-8"?>
    <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
      <xsl:output method="xml" version="1.0" encoding="utf-8" omit-xml-declaration="no" indent="yes"/>
      <xsl:strip-space elements="*"/>
      <xsl:template match="/">
        <xsl:copy-of xmlns:nc="urn:ietf:params:xml:ns:netconf:base:1.0" xmlns:sros="urn:nokia.com:sros:ns:yang:sr:conf" select="nc:rpc-reply/nc:data/sros:configure"/>
      </xsl:template>
    </xsl:stylesheet>"""

  @xslt_remove_ns = """<?xml version="1.0"?>
    <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
      <xsl:output indent="yes" method="xml" encoding="utf-8" omit-xml-declaration="yes"/>

      <xsl:template match="*">
        <xsl:element name="{local-name()}">
          <xsl:apply-templates select="@* | node()"/>
        </xsl:element>
      </xsl:template>

      <xsl:template match="@*">
        <xsl:attribute name="{local-name()}">
          <xsl:value-of select="."/>
        </xsl:attribute>
      </xsl:template>

      <xsl:template match="comment() | text() | processing-instruction()">
        <xsl:copy/>
      </xsl:template>
    </xsl:stylesheet>"""

  @format: (xslt, xmldoc) ->
    if xmldoc instanceof XMLDocument
      xmldom = xmldoc
    else
      xmldom = (new DOMParser).parseFromString xmldoc, "text/xml"
      return undefined if xmldom==null

    if (xslt instanceof XSLTProcessor)
      xsltprc = xslt
    else
      xsltdom = (new DOMParser).parseFromString xslt, "text/xml"
      return undefined if xsltdom==null
      xsltprc = new XSLTProcessor()
      xsltprc.importStylesheet xsltdom

    dom = xsltprc.transformToDocument(xmldom)
    return undefined if dom==null
    return ((new XMLSerializer).serializeToString dom).replace /\?\>\</, "?>\n<"

  @prettify: (xmldom) ->
    return @format(@xslt_prettify, xmldom)

  @minify: (xmldom) ->
    return @format(@xslt_minify, xmldom)

  @rpc_error: (xmldom) ->
    return @format(@xslt_rpc_error, xmldom)

  @data_node: (xmldom) ->
    return @format(@xslt_data_node, xmldom)

  @sros_config: (xmldom) ->
    return @format(@xslt_config_sros, xmldom)

  @remove_ns: (xmldom) ->
    return @format(@xslt_remove_ns, xmldom)

# EOF
