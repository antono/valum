Quickstart
==========

Assuming that Valum is built and installed correctly (view :doc:`installation`
for more details), you are ready to create your first application!

Unless you installed Valum with ``--prefix=/usr``, you might have to export
``PKG_CONFIG_PATH`` and ``LD_LIBRARY_PATH``.

.. code-block:: bash

    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
    export LD_LIBRARY_PATH=/usr/local/lib

Some distributions store 64-bit libraries in a separate folder, typically
``lib64``.

Simple 'Hello world!' application
---------------------------------

You can use this sample application and project structure as a basis. The full
`valum-framework/example`_ is available on GitHub and is kept up-to-date with
the latest changes in the framework.

.. _valum-framework/example: https://github.com/valum-framework/example

.. code:: vala

    using Valum;
    using VSGI.HTTP;

    var app = new Router ();

    app.get("", (req, res) => {
        res.body.write_all ("Hello world!".data, null);
    });

    new Server (app.handle).run ({"app", "--port", "3003"});

Typically, the ``run`` function contains CLI argument to make runtime the
parametrizable.

It is suggested to use the following structure for your project, but you can do
pretty much what you think is the best for your needs.

::

    build/
    src/
        app.vala

Building manually
-----------------

Building manually by invoking ``valac`` requires that you specifically link
against the shared library. Eventually, Valum will be distributed in standard
locations, so this wont be necessary.

.. code-block:: bash

    valac --pkg=valum --pkg=vsgi-http --vapidir=vapi
          -X -I/usr/local/include/valum -X -lvalum # compiler options
          src/app.vala
          -o build/app

    # if installed in default location /usr
    valac --pkg=valum --pkg=vsgi-http --vapidir=vapi src/app.vala -o build/app

Building with waf
-----------------

It is preferable to use a build system like `waf`_ to automate all this
process. Get a release of ``waf`` and copy this file under the name ``wscript``
at the root of your project.

.. _waf: https://code.google.com/p/waf/

.. code-block:: python

    #!/usr/bin/env python

    def options(cfg):
        cfg.load('compiler_c')

    def configure(cfg):
        cfg.load('compiler_c vala')
        cfg.check_cfg(package='valum', uselib_store='VALUM', args='--libs --cflags')
        cfg.check_cfg(package='vsgi-http', uselib_store='VSGI_HTTP', args='--libs --cflags')

    def build(bld):
        bld.load('vala')
        bld.program(
            packages = ['valum', 'vsgi-http'],
            target    = 'app',
            source    = 'src/app.vala',
            use       = 'VALUM VSGI_HTTP')

You should now be able to build by issuing the following commands:

.. code-block:: bash

    ./waf configure
    ./waf build

Running the example
-------------------

VSGI produces process-based applications that are either self-hosted or able to
communicate with a HTTP server according to a standardized protocol.

The :doc:`vsgi/http/soup` implementation is self-hosting, so you just have to
run it and point your browser at http://127.0.0.1:3003 to see the result.

.. code-block:: bash

    ./build/app
