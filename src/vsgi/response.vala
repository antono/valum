using GLib;
using Soup;

namespace VSGI {
	/**
	 * Response representing a request resource.
	 *
	 * @since 0.0.1
	 */
	public abstract class Response : Object {

		/**
		 * Request to which this response is responding.
		 *
		 * @since 0.1
		 */
		public Request request { construct; get; }

		/**
		 * Raw stream used by the implementation.
		 *
		 * @since 0.2
		 */
		public OutputStream base_stream { construct; protected get; }

		/**
		 * Response status.
		 *
		 * @since 0.0.1
		 */
		public abstract uint status { get; set; }

		/**
		 * Response headers.
		 *
		 * @since 0.0.1
		 */
		public abstract MessageHeaders headers { get; }

		/**
		 * Response cookies.
		 *
		 * If set, the 'Set-Cookie' headers will be removed and replaced by
		 * the new values.
		 *
		 * @since 0.1
		 */
		public SList<Cookie> cookies {
			set {
				this.headers.remove ("Set-Cookie");

				foreach (var cookie in value) {
					this.headers.append ("Set-Cookie", cookie.to_set_cookie_header ());
				}
			}
		}

		private OutputStream? _body = null;

		/**
		 * Response body.
		 *
		 * On the first attempt to access the response body stream, the status
		 * line and headers will be written in the response stream. Subsequent
		 * accesses will remain the stream untouched.
		 *
		 * The provided stream is safe for transfer encoding and will filter
		 * the stream properly if it's chunked.
		 *
		 * @since 0.2
		 */
		public virtual OutputStream body {
			get {
				// body have been filtered or redirected
				if (this._body != null)
					return this._body;

				this.write_status_line ();

				this.write_headers ();

				this._body = this.base_stream;

				return this._body;
			}
			set {
				this._body = value;
			}
		}

		/**
		 * Write the HTTP status line in the response raw body.
		 *
		 * It is invoked once when the body is accessed for the first time.
		 *
		 * This must be invoked before any headers writing operations,
		 * preferably with the response status property and protocol
		 * version.
		 *
		 * @since 0.2
		 *
		 * @param status   response status code
		 * @param protocol HTTP protocol and version, eg. HTTP/1.1
		 */
		protected virtual ssize_t write_status_line () throws IOError {
			var status_line = "%s %u %s\r\n".printf (this.request.http_version == HTTPVersion.@1_0 ? "HTTP/1.0" : "HTTP/1.1",
			                                         status,
			                                         Status.get_phrase (status));
			return this.base_stream.write (status_line.data);
		}

		/**
		 * Write the headers in the response raw body.
		 *
		 * It is invoked once when the body is accessed for the first time.
		 *
		 * @since 0.2
		 *
		 * @param headers headers to write in the response stream
		 */
		protected virtual ssize_t write_headers () throws IOError {
			var headers = new StringBuilder ();

			// headers
			this.headers.foreach ((k, v) => {
				headers.append ("%s: %s\r\n".printf (k, v));
			});

			// newline preceeding the body
			headers.append ("\r\n");

			return this.base_stream.write (headers.str.data);
		}
	}
}
