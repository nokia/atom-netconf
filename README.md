## Netconf for ATOM

This package provides a simplistic graphical user-interface for learning and
testing the NETCONF protocol. This software contains a NETCONF client, which
runs against a NETCONF server, such as NOKIA 7750 Service Routers.

In the current implementation this NETCONF client is using NETCONF over
SSHv2 with either password or key-based authentication as described in
[RFC 6242](https://tools.ietf.org/html/rfc6242).

Both base:1.0 *end-of-message framing* and base:1.1 *chunked-framing* are
both supported. Authentication supports username with password or
certificate.

![Netconf Package](https://raw.githubusercontent.com/nokia/atom-netconf/master/screenshot.png)

To use this package, it is required to specify connection details in the
package settings. All features are accessible from toolbars which are added
to the ATOM statusbar. A limited feature-set is accessible from the ATOM
menubar and context menus.

If you need to deal with multiple NETCONF servers, connection details can be
specified in a YAML file called server.yaml. This will add a selection list
of servers to the toolbar.

**Copyright (c) 2016-2018**  
![NOKIA](https://raw.githubusercontent.com/nokia/atom-netconf/master/logo-tiny.png)


## License

This project is licensed under the MIT license - see the [LICENSE](https://github.com/nokia/atom-netconf/blob/master/LICENSE).