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

### 1.1 - Updates (2016 November 9th)
* add support for base:1.1 chunked framing
* uprade to version 0.5 of ssh2 library
* add configurable rpc-request timeout (default 5min)
* improved cleanup for netconf errors/disconnect
* add support for SSH Greeting/Banner

### 1.2 - Example Library Updates (10. November 2016)
* New examples added for RFC6022, RFC7895
  (ietf-netconf-monitoring, yang library)
* Updated Nokia SROS examples for 14.0.R5 compatibility

### 1.3 - Updates (2017 January-May)
* New examples added for OpenConfig (BGP)
* Support for certificate based authentication
* Bugfix for timeout behavior
* Workaround for JUNOS interworking (multiple rpc-errors)
* Improve interworking with Cisco (new sshlib)
* Show SSH security banner (new sshlib)
* Fixed deprecations from Atom 1.14

### 1.6 - Fixes (2018 April 26th)
* repair chunked framing bug
* repair behavior for active editor/pane
* new option to enable/disable chunked framing support
* new option to open results in the active pane
* improved shutdown for netconf session

### 1.7 - Examples (2018 September 4th)
* updated examples for Nokia SR OS 16.0

### 2.0 - Updates (2018 September 27th)
* added support for multiple NETCONF servers

### 2.2 - Updates (2018 October 15th)
* updated examples for OpenConfig to work with Nokia SR OS
* hardend behavior for multiple NETCONF servers
* support for shared settings, defaults to ~/workspace_atom_netconf
* please check servers.yaml file for servers configuration
* suppress result-windows, if the response is just <ok>

### 2.3 - Updates (2018 October 17th)
* introducing environment / templating

### 3.0 - Updates (2018 October 22nd)
* basic support for MacBookPro TouchBar

### 3.1 - Updates (2019 February 28th)
* basic support for Nokia 1830 PSS

### 3.1.2 - 2020 October 9th
* update dependencies to ssh2 version 8.9
* https://www.npmjs.com/package/ssh2/v/0.8.9

