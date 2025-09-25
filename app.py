import datetime

from flask import Flask, render_template, make_response
from flask_restful import Api, Resource

# Initialize Flask app
app = Flask(__name__)
api = Api(app)


# Define a Resource for the index route
class Index(Resource):
    def get(self):
        print(f"Rendering index.html at datetime: {datetime.datetime.now()}")
        return make_response(render_template("index.html"))


@app.route("/ping")
def ping():
    return make_response("pong", 200)


# Add the resource to the API
api.add_resource(Index, "/")

if __name__ == "__main__":
    app.run(debug=True, threaded=True, host="0.0.0.0", port=5001)
