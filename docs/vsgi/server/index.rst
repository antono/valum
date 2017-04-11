Server
======

Server provide HTTP technologies integrations under a common interface.

.. toctree::

    http
    cgi
    fastcgi
    scgi

Server implementations are dynamically loaded using :valadoc:`gmodule-2.0/GLib.Module`.
It makes it possible to define its own implementation if necessary.

To load an implementation, use the ``Server.new`` factory, which can receive
GObject-style arguments as well.

::

    var cgi_server = Server.new ("cgi");

    if (cgi_server == null) {
        assert_not_reached ();
    }

    cgi_server.set_application_callback ((req, res) => {
        return res.expand_utf8 ("Hello world!");
    });

Custom implementation
---------------------

For more flexibility, the ``ServerModule`` class allow a more fine-grained
control for loading a server implementation. If non-null, the ``directory``
property will be used to retrieve the implementation from the given path
instead of standard locations.

The computed path of the shared library is available from ``path`` property,
which can be used for debugging purposes.

The shared library name must conform to ``vsgi-<name>`` with the appropriate
prefix and extension. For instance, on GNU/Linux, the :doc:`cgi` module is
stored in ``${prefix}/${libdir}/vsgi-0.3/servers/libvsgi-cgi.so``.

::

    var directory  = "/usr/lib64/vsgi-0.3/servers";
    var cgi_module = new ServerModule (directory, "cgi");

    if (!cgi_module.load ()) {
        error ("could not load 'cgi' from '%s'", cgi_module.path);
    }

    var server = Object.new (cgi_module.server_type);

Unloading a module is not necessary: once initially loaded, a use count is kept
so that it can be loaded on need or unloaded if not used.

.. warning::

    Since a ``ServerModule`` cannot be disposed (see :valadoc:`gobject-2.0/GLib.TypeModule`),
    one must be careful of how its reference is being handled. For instance,
    ``Server.new`` keeps track of requested implementations and persist them
    forever.

Mixing direct usages of ``ServerModule`` and ``Server.@new`` (and the likes) is
not recommended and will result in undefined behaviours if an implementation is
loaded more than once.

Parameters
----------

Each server implementation expose its own set of parameters via GObject
properties which are passed using the provided static constructors:

::

    var https_server = Server.new ("http", https: true);

More details on available parameters are presented in implementation-specific
documents.

Listening
---------

Once initialized, a server can be made ready to listen with ``listen`` and
``listen_socket``. Implementations typically support listening from an
arbitrary number of interfaces.

If the provided parameters are not supported, a :valadoc:`gio-2.0/GLib.IOError.NOT_SUPPORTED`
will be raised.

The ``listen`` call is designed to make the server listen on a :valadoc:`gio-2.0/GLib.SocketAddress`
such as :valadoc:`gio-2.0/GLib.InetSocketAddress` and :valadoc:`gio-2.0/GLib.UnixSocketAddress`.

::

    server.listen (new InetSocketAddress (new InetAddress.loopback (SocketFamily.IPV4), 3003));

It's also possible to pass ``null`` such that the default interface for the
implementation will be used.

::

    server.listen (); // default is 'null'

The ``listen_socket`` call make the server listen on an existing socket or file
descriptor if passed through `GLib.Socket.from_fd`_.

.. _GLib.Socket.from_fd:

::

    server.listen_socket (new Socket.from_fd (0));

Serving
-------

Once ready, either call ``Server.run`` or launch a :valadoc:`glib-2.0/GLib.MainLoop`
to start serving incoming requests:

::

    using GLib;
    using VSGI;

    var server = Server.new ("http");

    server.listen (new InetSocketAddress (new InetAddress (SocketFamily.IPV4), 3003));

    new MainLoop ().run (); // or server.run ();

Forking
-------

To achieve optimal performances on a multi-core architecture, VSGI support
forking at the server level.

.. warning::

    Keep in mind that the ``fork`` system call will actually copy the whole
    process: no resources (e.g. lock, memory) can be shared unless
    inter-process communication is used.

The ``Server.fork`` call is used for that purpose:

::

    using GLib;
    using VSGI;

    var server = Server.new ("http");

    server.listen (new InetSocketAddress (new InetAddress.loopback (SocketFamily.IPV4), 3003));

    server.fork ();

    new MainLoop ().run ();

It is recommended to fork only through that call since implementations such as
:doc:`cgi` are not guaranteed to support it and will gently fallback on doing
nothing.

Application
-----------

The ``VSGI.Application`` class provide a nice cushion around ``Server`` that
deals with pretty logging and CLI argument parsing. The ``Server.run`` function
is a shorthand to create and run an application.

::

    using VSGI;

    public int main (string[] args) {
        var server = Server.new ("http");
        return new Application (server).run (args);
    }

CLI
~~~

The following options are made available:

+-----------------------+-----------+---------------------------------------+
| Option                | Default   | Description                           |
+=======================+===========+=======================================+
| ``--forks``           | none      | number of forks to create             |
+-----------------------+-----------+---------------------------------------+
| ``--log-writer``      | none      | log writer to use                     |
+-----------------------+-----------+---------------------------------------+
| ``--address``         | none      | listen on each addresses              |
+-----------------------+-----------+---------------------------------------+
| ``--port``            | none      | listen on each ports, '0' for random  |
+-----------------------+-----------+---------------------------------------+
| ``--socket``          | none      | listen on each UNIX socket paths      |
+-----------------------+-----------+---------------------------------------+
| ``--any``             | disabled  | listen on any address instead of only |
|                       |           | from the loopback interface           |
+-----------------------+-----------+---------------------------------------+
| ``--ipv4-only``       | disabled  | listen only to IPv4 interfaces        |
+-----------------------+-----------+---------------------------------------+
| ``--ipv6-only``       | disabled  | listen only on IPv6 interfaces        |
+-----------------------+-----------+---------------------------------------+
| ``--file-descriptor`` | none      | listen on each file descriptors       |
+-----------------------+-----------+---------------------------------------+

The ``--log-writer`` flag allow one to chose among various log writer
implementations:

-   ``standard-streams``
-   ``journald``
-   ``default``

If no choice is made, no specific log writer is attached.

If none of ``--address``, ``--port``, ``--socket`` nor ``--file-descriptor``
flags are provided, it will fallback on the default listening interface for the
implementation.

The ``--address`` flag uses :valadoc:`gio-2.0/GLib.NetworkAddress.parse` under
the hood, which properly interpret IPv4 and IPv6 addresses. It will also
resolve domains and parse ports. If no port is provided, a random one will be
used.

The default when ``--port`` is provided is to listen on both IPv4 and IPv6
interfaces, or just IPv4 if IPv6 is not supported.

Use the ``--help`` flag to obtain more information about available options.
