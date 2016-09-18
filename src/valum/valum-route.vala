/*
 * This file is part of Valum.
 *
 * Valum is free software: you can redistribute it and/or modify it under the
 * terms of the GNU Lesser General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) any
 * later version.
 *
 * Valum is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Valum.  If not, see <http://www.gnu.org/licenses/>.
 */

using GLib;
using VSGI;

namespace Valum {

	/**
	 * Route provides a {@link Valum.MatcherCallback} and {@link Valum.HandlerCallback} to
	 * respectively match and handle a {@link VSGI.Request} and
	 * {@link VSGI.Response}.
	 *
	 * Route can be declared using the rule system, a regular expression or an
	 * arbitrary request-matching callback.
	 *
	 * @since 0.0.1
	 */
	public abstract class Route : Object {

		/**
		 * HTTP method this is matching or 'null' if it does apply.
		 *
		 * @since 0.2
		 */
		public Method method { construct; get; }

		/**
		 * Matches the given request and populate its parameters on success.
         *
		 * @since 0.0.1
		 */
		public abstract bool match (Request req, Context ctx);

		/**
		 * Apply the handler on the request and response.
		 *
		 * @since 0.0.1
		 *
		 * @return the return value of the callback if set, otherwise 'false'
		 */
		public abstract bool fire (Request req, Response res, NextCallback next, Context ctx) throws Success,
		                                                                                             Redirection,
		                                                                                             ClientError,
		                                                                                             ServerError,
		                                                                                             Error;

		/**
		 * Reverse the route into an URL.
		 *
		 * @since 0.3
		 *
		 * @param params parameters which are typically extract from the
		 *               {@link VSGI.Request.uri} property
		 *
		 * @return the corresponding URL if supported, otherwise 'null'
		 */
		public abstract string to_url_from_hash (HashTable<string, string>? @params = null);

		/**
		 * Reverse the route into an URL by building from a varidic arguments
		 * list.
		 *
		 * @since 0.3
		 */
		public string to_url_from_valist (va_list list) {
			var hash = new HashTable<string, string> (str_hash, str_equal);
			// potential compiler bug here: SEGFAULT if 'var' is used instead of 'unowned string'
			for (unowned string key = list.arg<string> (), val = list.arg<string> ();
			     key != null && val != null;
			     key = list.arg<string> (), val = list.arg<string> ()) {
				hash.insert (key, val);
			}
			return to_url_from_hash (hash);
		}

		/**
		 * Reverse the route into an URL using varidic arguments.
		 *
		 * Arguments alternate between keys and values, all assumed to be
		 * {@link string}.
		 *
		 * @since 0.3
		 */
		public string to_url (...) {
			return to_url_from_valist (va_list ());
		}
	}
}
