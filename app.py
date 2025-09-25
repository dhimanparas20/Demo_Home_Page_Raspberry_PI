import datetime

from flask import Flask, render_template, make_response, jsonify, request
from flask_restful import Api, Resource

# Initialize Flask app
app = Flask(__name__)
api = Api(app)


# Define a Resource for the index route
class Index(Resource):
    def get(self):
        print(f"Rendering index.html at : {datetime.datetime.now()} by ip: {request.remote_addr}")
        return make_response(render_template("index.html"))


@app.route("/ping")
def ping():
    print(f"Rendering ping at : {datetime.datetime.now()} by ip: {request.remote_addr}")
    return jsonify({"msg": "pong"}), 200


# Add the resource to the API
api.add_resource(Index, "/")

if __name__ == "__main__":
    app.run(debug=True, threaded=True, host="0.0.0.0", port=5000)
