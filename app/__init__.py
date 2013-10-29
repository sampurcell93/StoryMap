from flask import Flask
from flaskext.bcrypt import Bcrypt
from flask.ext.sqlalchemy import SQLAlchemy
app = Flask(__name__)
from sqlalchemy import create_engine
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://root@localhost/newsmaps'
db = SQLAlchemy(app)	
bcrypt = Bcrypt(app)
from app import views, models
