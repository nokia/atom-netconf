## Netconf for ATOM

### 1.0.0 - Initial Release (27th June 2016)
* NETCONF client implementation using end-of-message framing
* Session authentication by username/password
* Establish/terminate NETCONF session (needed for transactions)
* Shortcuts for NETCONF transactions (lock, validate, discard, commit)
* Ability to compare running datastore against candidate
* Extensions to access Nokia SROS data models
* Embedded XML/XSLT/CSV tools
* NETCONF example library

Enhanced Features (beta):
* Receive NETCONF event notifications
* Smart XML TAG Selection using CTRL-SHIFT-A
* Generate CSV Table from XML using interactive XPATH

### 1.1.0 - Updates (9th November 2016)
* add support for base:1.1 chunked framing
* uprade to version 0.5 of ssh2 library
* add configurable rpc-request timeout
* improved cleanup for netconf errors/disconnect
