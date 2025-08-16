from flask_sqlalchemy import SQLAlchemy
import os

data_points = []

def init_db(app):
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    if os.environ.get('FLASK_ENV') == 'production':
        # Use MySQL when in production
        # The config below is for the use with MySQL (though we are using SQLAlchemy)
        
        app.config['MYSQL_HOST'] = os.environ.get('MYSQL_HOST')
        app.config['MYSQL_USER'] = os.environ.get('MYSQL_USER')
        app.config['MYSQL_PASSWORD'] = os.environ.get('MYSQL_PASSWORD')
        app.config['MYSQL_DATABASE'] = os.environ.get('MYSQL_DATABASE')

        app.config['SQLALCHEMY_DATABASE_URI'] = f"mysql+pymysql://{app.config['MYSQL_USER']}:{app.config['MYSQL_PASSWORD']}@{app.config['MYSQL_HOST']}/{app.config['MYSQL_DATABASE']}"
    else:
        # Use SQLite for development
        app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///backend.sqlite3'
    
    return SQLAlchemy(app)
