from app import app, models, db, lm, login_serializer
from flask.ext.login import login_user, logout_user, current_user, login_required
import json
from flask.ext.api import status
from flask import Flask,redirect,request,render_template, g
from mailer import send_email
from string import Template
from flaskext.bcrypt import Bcrypt
import os,binascii
from collections import namedtuple


bcrypt = Bcrypt(app)

@app.route("/preferences", methods=["GET"])
def getUserPrefs():
    id = str(getattr(current_user, "id"));
    sql = "select * from preferences where user_id = " + id
    result = db.engine.execute(sql)
    Record = namedtuple('Record', result.keys())
    records = [Record(*r) for r in result.fetchall()]
    if len(records) > 0:
        return json.dumps(records[0].__dict__);
    else:
        return "{}";

# Using url params instead of querystring because Gmail filters out querystrings
@app.route('/validate/<string:key>/<string:email>', methods=["GET"])
def renderValidateView(key, email):
    print key, email
    user = models.Users.query.filter_by(email=email, account_validation_token=key).first()
    if user is not None:
        user.active = 1;
        db.session.commit()
        return render_template("validate.html", email=email, token=key, base_dir=app.config.get("base_dir"));
    else:
        return render_template("validate.html", error=True);    

@app.route('/forgot', methods=["POST"])
def generateForgotPasswordEmail(): 
    email = request.form.get("email")
    user = models.Users.query.filter_by(email=email).first()
    if user is not None:
        message = Template(getPasswordResetMessage());
        send_email(["spurcell93@gmail.com"], "News That Moves: Password Reset Link", message.substitute({
            "port": app.config.get("port"),
            "token": getattr(user, "reset_password_token"),
            "email": email,
            "url": app.config.get("url")
        }));
    else:
        return "fuk"
    return email

@app.route("/forgot/<string:key>/<string:email>", methods=["GET"])
def renderPasswordResetView(key, email):
    user = models.Users.query.filter_by(email=email, reset_password_token = key).first()
    if user is None: 
        return render_template("forgot.html", error=1)
    else:
        return render_template("forgot.html", email=email, token=token)

@app.route("/resetPassword", methods = ["POST"])
def resetPassword():
    email = request.form.get("email")
    token = str(request.form.get("token"))
    password = request.form.get("password")
    print token, email
    user = models.Users.query.filter_by(email=email, reset_password_token = token).first()
    if user is None: 
        return '{"error": "Bad token-email combination"}', status.HTTP_417_EXPECTATION_FAILED
    else:
        # Update password
        user.password = bcrypt.generate_password_hash(password);
        # Token used; generate new token. 
        user.reset_password_token = binascii.b2a_hex(os.urandom(15));
        db.session.commit();
        return '{"updated":true}', status.HTTP_200_OK


def getPasswordResetMessage():
    return 'Follow this link to reset your password. <a href="http://$url:$port/forgot/$token/$email" title="Reset Password">Reset</a>'

def getValidationMessage():
    return  'Here\'s your account validation link! Click this to confirm your account. <a title="Validation Link" href="$url:$port/validate/$token/$email">Validate</a>'