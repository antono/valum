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

using Valum;
using Valum.ContentNegotiation;
using VSGI;

var app = new Router ();

var openweathermap = new Soup.Session ();

openweathermap.prefetch_dns ("api.openweathermap.org", null, null);

openweathermap.authenticate.connect ((msg, auth) => {
    auth.authenticate ("client_id", "secret_id");
});

app.use (basic ());
app.use (accept ("text/html"));

app.get ("/", (req, res, next, ctx) => {
	openweathermap.send_async.begin (new Soup.Message ("GET", "http://api.openweathermap.org/data/2.5/weather?q=Montreal&units=metric"),
	                                 null,
	                                 (obj, result) => {
		var parser = new Json.Parser ();

		try {
			parser.load_from_stream (openweathermap.send_async.end (result));

			var _main = parser.get_root ().get_object ().get_object_member ("main");

			res.expand_utf8 ("""
			<h1>Weather in Montreal</h1>
			<dl>
			  <dt>Humidity</dt><dd>%s</dd>
			  <dt>Pressure</dt><dd>%shPa</dd>
			  <dt>Temperature</dt><dd>%s°C</dd>
			  <dt>Max</dt><dd>%s°C</dd>
			  <dt>Min</dt><dd>%s°C</dd>
			</dl>
			""".printf (_main.get_string_member ("humidity"),
						_main.get_string_member ("pressure"),
						_main.get_string_member ("temp"),
						_main.get_string_member ("temp_max"),
						_main.get_string_member ("temp_min")), null);
		} catch (Error err) {
			critical (err.message);
			return;
		}
	});
	return true;
});

Server.@new ("http", handler: app).run ();
