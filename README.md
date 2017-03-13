Valum Web micro-framework
=========================

[![Build Status](https://travis-ci.org/valum-framework/valum.svg?branch=master)](https://travis-ci.org/valum-framework/valum)
[![Documentation Status](https://readthedocs.org/projects/valum-framework/badge/?version=latest)](https://readthedocs.org/projects/valum-framework/?badge=latest)
[![codecov.io](https://codecov.io/github/valum-framework/valum/coverage.svg?branch=master)](https://codecov.io/github/valum-framework/valum?branch=master)

Valum is a Web micro-framework entirely written in the
[Vala](https://wiki.gnome.org/Projects/Vala) programming language.

```vala
using Valum;
using Valum.ContentNegotiation;
using VSGI;

var app = new Router ();

app.use (basic ());
app.use (accept ("text/plain"));
app.use (accept_charset ("UTF-8"));

app.get ("/", (req, res) => {
    return res.extend_utf8 ("Hello world!");
});

Server.@new ("http", handler: app).run ({"app", "--forks=4"});
```


Installation
------------

The installation process is fully documented in the
[user documentation](http://valum-framework.readthedocs.org/en/latest/installation.html).


Features
--------

 - powerful routing mechanism to write expressive Web services:
    - helpers and flags (i.e. `Method.GET | Method.POST`) for common HTTP methods
    - scoping
    - rule system supporting typed parameters, group, optional and wildcard
    - regular expression with capture extraction
    - automatic `HEAD` and `OPTIONS`
    - subrouting
    - status codes through error domains (i.e. `throw new Redirection.PERMANENT ("http://example.com/");`
    - filtering by composition
    - context to hold states
 - middlewares for subdomains, server-sent events, content negotiation and much more
 - written upon VSGI, an abstraction layer for various protocols:
     - fast, asynchronous and elegant
     - streaming-first API
     - listen on multiple interfaces (e.g. port, UNIX socket, file descriptor)
       with tight [GIO](https://developer.gnome.org/gio/stable/) integration
     - support [libsoup-2.4 built-in HTTP server](https://wiki.gnome.org/Projects/libsoup), CGI,
       [FastCGI](http://www.fastcgi.com/drupal/) and [SCGI](https://python.ca/scgi/) out of the box
     - support plugin for custom server implementation
     - `fork` to scale on multi-core architecture
     - cushion for parsing CLI, logging and running a Web application
 - extensively documented at [docs.valum-framework.org](http://docs.valum-framework.org/en/latest/)


Contributing
------------

Valum is built by the community under the [LGPL](https://www.gnu.org/licenses/lgpl.html)
license, so anyone can use or contribute to the framework.

 1. fork repository
 2. pick one task from TODO.md or [GitHub issues](https://github.com/antono/valum/issues)
 3. let us know what you will do (or attempt!)
 4. code
 5. make a pull request of your amazing changes
 6. let everyone enjoy :)

We use [semantic versionning](http://semver.org/), so make sure that your
changes

 * does not alter api in bugfix release
 * does not break api in minor release
 * breaks api in major (we like it that way!)


Discussions and help
--------------------

You can get help with Valum from different sources:

 - mailing list: [vala-list](https://mail.gnome.org/mailman/listinfo/vala-list).
 - IRC channel: #vala and #valum at irc.gimp.net
 - [Google+ page for Vala](https://plus.google.com/115393489934129239313/)
 - issues on [GitHub](https://github.com/antono/valum/issues) with the
   `question` label
