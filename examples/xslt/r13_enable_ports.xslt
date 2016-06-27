<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/">
    <nc:rpc xmlns:nc="urn:ietf:params:xml:ns:netconf:base:1.0" message-id="r13_enable_ports">
      <nc:edit-config>
        <nc:target><nc:running/></nc:target>
        <nc:config>
          <configure xmlns="urn:alcatel-lucent.com:sros:ns:yang:conf-r13">
            <xsl:for-each xmlns:sros="urn:alcatel-lucent.com:sros:ns:yang:conf-r13" select="//sros:port[sros:shutdown='true']">
              <port>
                <port-id><xsl:value-of select="sros:port-id"/></port-id>
                <shutdown operation="merge">false</shutdown>
              </port>
            </xsl:for-each>
          </configure>
        </nc:config>
      </nc:edit-config>
    </nc:rpc>
  </xsl:template>
</xsl:stylesheet>
