<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml" indent="yes"/>
  <xsl:strip-space elements="*"/>
  <xsl:template match="/">
    <nc:rpc xmlns:nc="urn:ietf:params:xml:ns:netconf:base:1.0" message-id="create interfaces">
      <nc:edit-config>
        <nc:target><nc:running/></nc:target>
        <nc:config>
          <configure xmlns="urn:alcatel-lucent.com:sros:ns:yang:conf-r13">
            <router>
              <router-instance>Base</router-instance>
              <xsl:for-each select="/*/*"><!-- alternative select="//*[@csvidx]" -->
                <interface>
                  <interface-name><xsl:value-of select="ifName"/></interface-name>
                  <address>
                    <ip-address-mask><xsl:value-of select="ipAddress"/></ip-address-mask>
                  </address>
                  <xsl:if test="ifDescription!=''">
                    <description>
                      <long-description-string><xsl:value-of select="ifDescription"/></long-description-string>
                    </description>
                  </xsl:if>
                  <port>
                    <port-name><xsl:value-of select="port"/></port-name>
                  </port>
                  <xsl:if test="ipv6Address!=''">
                    <ipv6>
                      <address>
                        <ipv6-address-prefix-length><xsl:value-of select="ipv6Address"/></ipv6-address-prefix-length>
                      </address>
                    </ipv6>
                  </xsl:if>
                  <shutdown>false</shutdown>
                </interface>
              </xsl:for-each>
            </router>
          </configure>
        </nc:config>
      </nc:edit-config>
    </nc:rpc>
  </xsl:template>
</xsl:stylesheet>
