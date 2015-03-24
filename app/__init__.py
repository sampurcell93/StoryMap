import os
from flask import Flask
from flaskext.bcrypt import Bcrypt
from flask.ext.sqlalchemy import SQLAlchemy
from flask.ext.login import LoginManager
from datetime import timedelta
from itsdangerous import URLSafeTimedSerializer
app = Flask(__name__)
from sqlalchemy import create_engine
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://root@127.0.0.1/atfstorymap'
# app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql://b556f79bd1c6a3:e3aab6da@us-cdbr-east-04.cleardb.com/heroku_478003e9c167242'
app.secret_key = "THISISASUPERSECRETKEY"
app.config["port"] = int(os.environ.get('PORT', 6379));
app.config["REMEMBER_COOKIE_DURATION"] = timedelta(days=14)
app.config["base_dir"] = "/"
app.config["url"] = "http://127.0.0.1"
app.config['REDIS_QUEUE_KEY'] = 'my_queue'
login_serializer = URLSafeTimedSerializer(app.secret_key)
db = SQLAlchemy(app)
bcrypt = Bcrypt(app)
lm = LoginManager()
lm.init_app(app)
lm.login_view = "/"
from app import views, models, news, crons
