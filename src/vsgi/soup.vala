using Soup;

/**
 * Soup implementation of VSGI.
 *
 * @since 0.1
 */
namespace VSGI.Soup {

	/**
	 * Soup Request
	 */
	class Request : VSGI.Request {

		private HashTable<string, string>? _query;

		public override HTTPVersion http_version { get { return this.message.http_version; } }

		public Message message { construct; get; }

		public override string method { owned get { return this.message.method ; } }

		public override URI uri { get { return this.message.uri; } }

		public override HashTable<string, string>? query { get { return this._query; } }

		public override MessageHeaders headers {
			get {
				return this.message.request_headers;
			}
		}

		public Request (Message msg, InputStream body, HashTable<string, string>? query) {
			Object (message: msg, body: body);
			this._query = query;
		}
	}

	/**
	 * Soup Response
	 */
	class Response : VSGI.Response {

		public Message message { construct; get; }

		public override uint status {
			get { return this.message.status_code; }
			set { this.message.set_status (value); }
		}

		public override MessageHeaders headers {
			get { return this.message.response_headers; }
		}

		private OutputStream? _body = null;

		public override OutputStream body {
			get {
				// body have been filtered or redirected
				if (this._body != null)
					return this._body;

				if (this.headers_written)
					return this.base_stream;

				if (!this.status_line_written) {
					this.write_status_line ();
					this.status_line_written = true;
				}

				if (!this.headers_written) {
					this.write_headers ();
					this.headers_written = true;
				}

#if SOUP_2_50
				// filter the stream properly
				if (this.headers.get_encoding () == Encoding.CHUNKED) {
					this._body = new ConverterOutputStream (this.base_stream, new ChunkedConverter ());
					return this._body;
				}
#endif

				return this.base_stream;
			}
			set {
				this._body = value;
			}
		}

		public Response (Request req, Message msg, OutputStream base_stream) {
			Object (request: req, message: msg, base_stream: base_stream);
		}
	}

	/**
	 * Implementation of VSGI.Server based on Soup.Server.
	 *
	 * @since 0.1
	 */
	public class Server : VSGI.Server {

		/**
		 * @since 0.1
		 */
		public global::Soup.Server server { construct; get; }

		/**
		 * {@inheritDoc}
		 */
		public Server (VSGI.Application application) {
#if SOUP_2_48
			var server = new global::Soup.Server (global::Soup.SERVER_SERVER_HEADER, "Valum");
#else
			var server = new global::Soup.Server (global::Soup.SERVER_SERVER_HEADER, "Valum",
						                           global::Soup.SERVER_PORT, 3003);
#endif

			Object (application: application, flags: ApplicationFlags.HANDLES_COMMAND_LINE, server: server);

#if GIO_2_42
			this.add_main_option ("port", 'p', 0, OptionArg.INT, "port used to serve the HTTP server", "3003");
			this.add_main_option ("timeout", 't', 0, OptionArg.INT, "inactivity timeout in ms", "0");
#endif
		}

		public override int command_line (ApplicationCommandLine command_line) {
#if GIO_2_40
			var options = command_line.get_options_dict ();
			var port    = options.contains ("port") ? options.lookup_value ("port", VariantType.INT32).get_int32 () : 3003;
			var timeout = options.contains ("timeout") ? options.lookup_value ("timeout", VariantType.INT32).get_int32 () : 0;
#else
			var port    = 3003;
			var timeout = 0;
#endif

			this.hold ();

#if SOUP_2_48
			this.server.listen_all (port, 0);
#endif

			this.set_inactivity_timeout (timeout);

			// register a catch-all handler
			this.server.add_handler (null, (server, msg, path, query, client) => {
				this.hold ();

				var input_stream  = new MemoryInputStream.from_data (msg.request_body.data, null);

#if SOUP_2_50
				var connection = client.steal_connection ();
				var output_stream = connection.output_stream;
#else
				var output_stream = new MemoryOutputStream (msg.response_body.data, realloc, free);
#endif

				var req = new Request (msg, input_stream, query);
				var res = new Response (req, msg, output_stream);

				res.end.connect_after (() => {
#if SOUP_2_50
					connection.close_async (Priority.DEFAULT, null, () => {
						message ("%s: %u %s %s", get_application_id (), res.status, res.request.method, res.request.uri.get_path ());
						this.release ();
					});
#else
					msg.response_body.complete ();
					message ("%s: %u %s %s", get_application_id (), res.status, res.request.method, res.request.uri.get_path ());
					this.release ();
#endif
				});

				this.application.handle (req, res);
			});

#if SOUP_2_48
			foreach (var uri in this.server.get_uris ()) {
				message ("listening on %s://%s:%u", uri.scheme, uri.host, uri.port);
			}
#else
			this.server.run_async ();
			message ("listening on http://0.0.0.0:%u", this.server.port);
#endif

			// keep alive if timeout is 0
			if (this.get_inactivity_timeout () > 0)
				this.release ();

			return 0; // continue processing
		}
	}
}
