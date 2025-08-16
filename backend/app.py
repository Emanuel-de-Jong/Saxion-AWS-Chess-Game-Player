from flask import Flask, request, jsonify
from flask_cors import CORS
from database import init_db
import json, itertools

app = Flask(__name__)
cors = CORS(app)
db = init_db(app)


class DataPoint(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    type = db.Column(db.String(80), nullable=False)
    moves = db.Column(db.String(9999))

    field_id = db.Column(db.Integer, db.ForeignKey('field.id'), nullable=False)
    field = db.relationship('Field', backref=db.backref('data_point', lazy=True))

    def as_dict(self):
        """This method returns the data as a dictionary for JSON serialization."""
        return {
            "id": self.id,
            "type": self.type,
            "field": self.field.as_dict(),
            "moves": self.moves
        }


class Field(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    type = db.Column(db.String(80), nullable=False)

    # Store the key/value pairs as a string and use a getter and setter to
    # convert them.
    _fields = db.Column(db.String(9999), nullable=False)

    @property
    def fields(self):
        lst = [x for x in self._fields.split('|')]
        return dict(zip(lst[::2], lst[1::2]))
    @fields.setter
    def fields(self, value):
        self._fields = '|'.join(list(itertools.chain.from_iterable(value.items())))
        print(self._fields)

    def as_dict(self):
        """This method returns the data as a dictionary for JSON serialization."""
        return {
            "id": self.id,
            "type": self.type,
            "fields": self.fields
        }


@app.route("/games", methods=["GET", "POST", "DELETE"])
def points():
    if request.method=='GET':
        return jsonify({
            "host" : request.host,
            "message": "Successfully connected to the backend.",
            "points": get_points()
        })
    elif request.method=='POST':
        data = json.loads(request.data, strict=False)
        try:
            add_point(
                data["type"],
                data["fields"],
                data["moves"]
            )
            return jsonify({
                "host" : request.host,
                "message": "Data point successfully saved."
            })
        except:
            return jsonify({
                "host" : request.host,
                "message": "Error saving data point."
            })
    elif request.method=='DELETE':
        try:
            clear_points() 
            return jsonify({
                "host" :request.host,
                "message": "All data points successfully cleared."
            })
        except:
            return jsonify({
                "host" : request.host,
                "message": "All data points successfully cleared."
            })
    else:
        return jsonify({
            "host" : request.host,
            "message": "Unsupported HTTP method"
        })


def get_points():
    return [dp.as_dict() for dp in DataPoint.query.all()]


def add_point(feature_type, fields, moves):
    f = Field(
        type = 'Dict',
        fields = fields
    )
    dp = DataPoint(type = feature_type, field = f, moves = moves)
    db.session.add(dp)
    db.session.commit()


def clear_points():
    DataPoint.query.delete()
    Field.query.delete()
    db.session.commit() 
    


@app.route("/")
def index():
    return jsonify({
        "host" : request.host,
        "message": "Successfully connected to the backend."
    })


if __name__ == '__main__':
    db.create_all()
    app.run(host='0.0.0.0', port=5001)
    
