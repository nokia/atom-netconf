> **Warning**
> 
> In July 2022 GitHub announced to sunset Atom, the text editor for software
> development that the company introduced in 2011.
> Since December 2022 the Atom repository and all other repositories remaining
> to the Atom organization have been archived and will no longer be maintained.
> While pre-built Atom binaries can still be downloaded, Atom package management
> has stopped working and there are no security updates anymore.
> 
> With more than 5000 downloads *atom-netconf* has been the open-source editor
> integration of choice for the NetDevOps community to practical learn about
> the NETCONF protocol, validate NETCONF server implementations, reproduce
> NETCONF callflows and to build custom automation use-cases. As part of our
> committment supporting the NetDevOps community, we are planning to add
> NETCONF support for Visual Studio Code.

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

## License

This project is licensed under the MIT license - see the [LICENSE](https://github.com/nokia/atom-netconf/blob/master/LICENSE).

**Copyright (c) 2016-2021**  
![NOKIA](https://raw.githubusercontent.com/nokia/atom-netconf/master/logo-tiny.png)
