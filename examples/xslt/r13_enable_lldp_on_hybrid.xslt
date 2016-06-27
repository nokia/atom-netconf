<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/">
    <nc:rpc xmlns:nc="urn:ietf:params:xml:ns:netconf:base:1.0" message-id="r13_enable_ports">
      <nc:edit-config>
        <nc:target><nc:running/></nc:target>
        <nc:config>
          <configure xmlns="urn:alcatel-lucent.com:sros:ns:yang:conf-r13">
            <xsl:for-each xmlns:sros="urn:alcatel-lucent.com:sros:ns:yang:conf-r13" select="//sros:port[sros:ethernet/sros:mode/sros:access-network-hybrid='hybrid']">
              <port>
                <port-id><xsl:value-of select="sros:port-id"/></port-id>
                <ethernet>
                  <lldp operation="merge">
                    <dest-mac>
                      <dest-mac-id>nearest-bridge</dest-mac-id>
                      <admin-status>
                        <admin-status-id>tx-rx</admin-status-id>
                      </admin-status>
                      <notification>true</notification>
                      <tx-tlvs>
                        <port-desc>true</port-desc>
                      </tx-tlvs>
                      <tx-mgmt-address>
                        <system>true</system>
                      </tx-mgmt-address>
                    </dest-mac>
                  </lldp>
                </ethernet>
              </port>
            </xsl:for-each>
          </configure>
        </nc:config>
      </nc:edit-config>
    </nc:rpc>
  </xsl:template>
</xsl:stylesheet>
