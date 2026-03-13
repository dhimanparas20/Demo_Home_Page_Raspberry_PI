import datetime
import time

from flask import Flask, render_template, make_response, jsonify, request
from flask_restful import Api, Resource
from werkzeug.middleware.proxy_fix import ProxyFix

# Initialize Flask app
app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1)
api = Api(app)


# Define a Resource for the index route
class Index(Resource):
    def get(self):
        t0 = time.perf_counter()
        ip = request.remote_addr
        print(f"Rendering index.html at : {datetime.datetime.now()} by ip: {ip}")
        resp = make_response(render_template("index.html"))
        dt_ms = (time.perf_counter() - t0) * 1000
        print(f"Rendered index.html in {dt_ms:.1f}ms for ip: {ip}")
        return resp


@app.route("/ping")
def ping():
    t0 = time.perf_counter()
    ip = request.remote_addr
    print(f"Rendering ping at : {datetime.datetime.now()} by ip: {ip}")
    resp = jsonify({"msg": "pong"}), 200
    dt_ms = (time.perf_counter() - t0) * 1000
    print(f"Rendered ping in {dt_ms:.1f}ms for ip: {ip}")
    return resp


# Add the resource to the API
api.add_resource(Index, "/")

if __name__ == "__main__":
    app.run(debug=True, threaded=True, host="0.0.0.0", port=5000)
