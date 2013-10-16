from flask import Flask
from flask.ext.sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://root:root@localhost/newsmaps?unix_socket=/Applications/MAMP/tmp/mysql/mysql.sock'
db = SQLAlchemy(app)	
from app import views, models
