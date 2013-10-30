import os
import psycopg2
import urlparse
from flask import Flask
from flaskext.bcrypt import Bcrypt
from flask.ext.sqlalchemy import SQLAlchemy
from flask.ext.login import LoginManager
from datetime import timedelta
from itsdangerous import URLSafeTimedSerializer
app = Flask(__name__)
from sqlalchemy import create_engine
url = 'mysql://root@localhost/newsmaps'
try:
    url = os.environ['DATABASE_URL']
except:
    print "local"
app.config['SQLALCHEMY_DATABASE_URI'] = url
app.secret_key = "THISISASUPERSECRETKEY"
app.config["REMEMBER_COOKIE_DURATION"] = timedelta(days=14)
login_serializer = URLSafeTimedSerializer(app.secret_key)
db = SQLAlchemy(app)
bcrypt = Bcrypt(app)
lm = LoginManager()
lm.init_app(app)
lm.login_view = "/"
from app import views, models
