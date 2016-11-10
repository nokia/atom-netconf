<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml" indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="/">
    <nc:rpc xmlns:nc="urn:ietf:params:xml:ns:netconf:base:1.0" message-id="create epipes">
      <nc:edit-config>
        <nc:target><nc:candidate/></nc:target>
        <nc:config>
          <configure xmlns="urn:nokia.com:sros:ns:yang:sr:conf">
            <service>
              <xsl:for-each select="/*/*">
                <epipe operation="merge">
                  <customer>1</customer>
                  <service-id><xsl:value-of select="id"/></service-id>
                  <service-name><xsl:value-of select="svcname"/></service-name>
                  <description><xsl:value-of select="description"/></description>
                  <shutdown>false</shutdown>
                  <sap>
                    <sap-id><xsl:value-of select="sap1"/></sap-id>
                    <shutdown>false</shutdown>
                  </sap>
                  <sap>
                    <sap-id><xsl:value-of select="sap2"/></sap-id>
                    <shutdown>false</shutdown>
                  </sap>
                </epipe>
              </xsl:for-each>
            </service>
          </configure>
        </nc:config>
      </nc:edit-config>
    </nc:rpc>
  </xsl:template>
</xsl:stylesheet>
