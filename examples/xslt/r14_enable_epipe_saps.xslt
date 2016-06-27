<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml" indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="/">
    <nc:rpc xmlns:nc="urn:ietf:params:xml:ns:netconf:base:1.0" message-id="r14_enable_saps">
      <nc:edit-config>
        <nc:target><nc:candidate/></nc:target>
        <nc:config>
          <configure xmlns="urn:nokia.com:sros:ns:yang:sr:conf">
            <service xmlns="urn:nokia.com:sros:ns:yang:sr:conf-service">
              <xsl:for-each xmlns:svc="urn:nokia.com:sros:ns:yang:sr:conf-service" select="//svc:service/svc:epipe[svc:sap/svc:shutdown='true']">
                <epipe>
                  <service-id><xsl:value-of select="svc:service-id"/></service-id>
                  <xsl:for-each select="./svc:sap[svc:shutdown='true']">
                    <sap>
                      <sap-id><xsl:value-of select="svc:sap-id"/></sap-id>
                      <shutdown operation="merge">false</shutdown>
                    </sap>
                  </xsl:for-each>
                </epipe>
              </xsl:for-each>
            </service>
          </configure>
        </nc:config>
      </nc:edit-config>
    </nc:rpc>
  </xsl:template>
</xsl:stylesheet>
