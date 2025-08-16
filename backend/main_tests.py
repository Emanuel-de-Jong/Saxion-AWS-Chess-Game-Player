import unittest
import os
from flask import Flask
from flask_testing import TestCase
from app import db, get_points, add_point, clear_points
from database import init_db

class GamesTest(TestCase):
    
    def create_app(self):
        self.delete_db()
        app = Flask(__name__)
        init_db(app)
        app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///testing.sqlite3'
        return app


    def setUp(self):
        db.create_all()


    def tearDown(self):
        db.session.remove()
        db.drop_all()
        self.delete_db()


    def delete_db(self):
        try:
            os.remove("testing.sqlite3")
        except FileNotFoundError:
            pass


    def test_get(self):
        points = get_points()
        self.assertEqual(points, [], "Should be an empty list")


    def test_add(self):
        # Test values
        feature_type = 'Game'
        fields = {'Player': 'Test'}
        moves = "1. e4"
        expected = [{'id': 1, 'type': feature_type, 'field': {'id': 1, 'fields': fields, 'type': 'Dict'}, 'moves': moves}]
        
        # Call add 
        add_point(feature_type, fields, moves)
        points = get_points()
        
        # Validate response
        self.assertEqual(len(points), 1, "Should be a list of 1")
        self.assertEqual(points, expected, "Should be the expected list")
        

    def test_clear(self):
        # Call clear 
        clear_points()

        # Validate response
        points = get_points()
        self.assertEqual(points, [], "Should be an empty list")


if __name__ == '__main__':
    log_file = 'test_results.txt'
    with open(log_file, "w") as f:
       runner = unittest.TextTestRunner(f)
       unittest.main(testRunner=runner)
