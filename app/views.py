from dateutil import parser
from flask.ext.api import status
import datetime
from pprint import pprint
from app import app, models, db, lm, login_serializer, users, mailer
from models import queries_has_stories
import datetime
import traceback
import time
import flask
from flaskext.bcrypt import Bcrypt
from flask_oauth import OAuth
from flask import Flask,redirect,request,render_template, g
import time
import oauth2
import oauth.oauth as oauth
import urllib
import urllib2
import httplib2
import json
import pytz
import os,binascii
from sqlalchemy import exc
from sqlalchemy.exc import IntegrityError, InvalidRequestError
from sqlalchemy import select
from flask.ext.login import login_user, logout_user, current_user, login_required
from app.mailer import send_email
from string import Template

port = app.config.get("port");

bcrypt = Bcrypt(app)

dthandler = lambda obj: obj.isoformat() if isinstance(obj, datetime.datetime)  or isinstance(obj, datetime.date) else None
def _json_object_hook(d): 
    return namedtuple('X', d.keys())(*d.values())
def json2obj(data): 
    return json.loads(data, object_hook=_json_object_hook)

def tryConnection (applyfun): 
    try:
        return applyfun()
    except exc.SQLAlchemyError:
        print "yeah operational error, db disconnected"
        db.session.rollback()
        return applyfun()

def to_json_list(results, is_query=False):
    output = []
    for result in results:
        row = {}
        for col in result.__table__.columns:
            row[col.name] = getattr(result, col.name)
        if is_query:
            for story in result.stories:
                row2 = {}
                for col in story.__table__.columns:
                    row2[col.name] = getattr(story, col.name)
                row['stories'] = row2
            for user in result.users:
                row3 = {}
                for col in user.__table__.columns:
                    row3[col.name] = getattr(user, col.name)
                row['users'] = row3
        else:
            for query in result.queries:
                row2 = {}
                for col in query.__table__.columns:
                    row2[col.name] = getattr(query, col.name)
                row['queries'] = row2
        output.append(row)
    return output


def to_json(result, is_query=False):
    output = {}
    for col in result.__table__.columns:
        output[col.name] = getattr(result, col.name)
    if is_query:
        output['stories'] = []
        output['users'] = []
        for story in result.stories:
            row2 = {}
            for col in story.__table__.columns:
                row2[col.name] = getattr(story, col.name)
            output['stories'].append(row2)
        for user in result.users:
            row3 = {}
            for col in user.__table__.columns:
                row3[col.name] = getattr(user, col.name)
            output['users'].append(row3)
    else:
        output['queries'] = []
        for query in result.queries:
            row2 = {}
            for col in query.__table__.columns:
                row2[col.name] = getattr(query, col.name)
            output['queries'].append(row2)
    return output


class QueryManager():
    def createStory(self, title=None, publication=None, date=None, author=None, url=None,
                    lat=None, lng=None, content=None, query_id=None, aggregator='Yahoo', location=''):
        if title is None:
            title = request.json.get('title')
            content = request.json.get('content')
            publication = request.json.get('publisher')
            date = request.json.get('date');
            if date is not None:
                date = parser.parse(date).strftime('%Y-%m-%d %H:%M:%S')
            url = request.json.get('url')
            lat = request.json.get('lat')
            lng = request.json.get('lng')
            location = request.json.get('location')
            aggregator = request.json.get('aggregator')
            query_id = request.json.get('query_id')
        try:
            story = tryConnection(lambda: models.Stories(
                title=title, publisher=publication, date=date,
                url=url, lat=lat, lng=lng, content=content, 
                aggregator=aggregator, location=location))
            db.session.add(story)
            try: db.session.commit()
            except InvalidRequestError as e: 
                db.session.rollback()
                db.session.commit()
            # except Exception as e: db.session.rollback()
            # except Exception: return json.dumps({"duplicate": True}
            if query_id is not None:
                print "story has been created: now adding to query #"
                print query_id
                print " and the story has the id " 
                print story.id
                self.addStoryToQuery(story.id, query_id)
            return json.dumps({"id": story.id})
        except IntegrityError as e:
            db.session.flush()
            # db.session.rollback()
            return json.dumps({"duplicate": True})

    def addAllStoriesToQuery(self, stories, queryid):
        if stories is None: return True
        for story in stories:
            self.addStoryToQuery(story['id'],queryid)
        return True

    def addStoryToQuery(self, story_id, query_id):
        print "Adding story now - at start"
        story = tryConnection(lambda: models.Stories.query.get(story_id))
        if story is None:
            return 'Story does not exist\n'
        query = models.Queries.query.get(query_id)
        if query is None:
            return 'Query does not exist\n'
        story.queries.append(query)
        print "successfully added story to query"
        db.session.commit()
        print "session committed"
        return True
    def getQueryByTitle(self, title):
        query = tryConnection(lambda: models.Queries.query.filter_by(title = title).all())
        if not query:
            return json.dumps({"exists": False})
        return self.getQueryById(query[0].id)
    def getQueryById(self, identifier):
        digit = False
        try:
            digit = identifier.isdigit()
        except Exception: 
            digit = True
        if digit is True:
            query = tryConnection(lambda: models.Queries.query.get(identifier))
            if (query is None):
                return json.dumps({"exists": False})
            return json.dumps(to_json(query, True), default=dthandler)
        else:
            return self.getQueryByTitle(identifier)
    def getStoryCountForQuery(self, title):
        query = tryConnection(lambda: models.Queries.query.filter_by(title = title).first())
        if not query:
            return {"exists": False}
        else:
            id = query.id
            sql = "select count(*) from queries_has_stories where queries_id = " + str(id)
            result = db.engine.execute(sql)
            for row in result:
                return row[0];
    def doesQueryExist(self, title):
        query = tryConnection(lambda: models.Queries.query.filter_by(title = title).all())
        if not query:
            return json.dumps({"exists": False})
        return json.dumps({"id": query[0].id, "exists": True});

    def updateQueryRetrievalTime(self, identifier):
        query = tryConnection(lambda: models.Queries.query.get(identifier))
        query.last_query = datetime.datetime.now();
        db.session.commit()
        return True

manager = QueryManager()

def getTokenizedQueries():
    queries = tryConnection(lambda: models.Queries.query.all())
    tokens = []
    if queries is not None:
        for query in queries: 
            tokens.append({
                "val": query.title,
                "tokens": [query.title]
            })
    return tokens

## User Interfaces ##
@app.route('/')
def index():
    if current_user.is_authenticated():
        return redirect("./map")
    return render_template("login.html", error=request.args.get('error'), args=request.args, success=request.args.get("success"))

@app.errorhandler(404)
def page_not_found(e):
    return render_template("404.html")

@app.route("/map")
@login_required
def map(): 
    queries = getTokenizedQueries();
    user = models.Users.query.get(getattr(current_user, "id"));
    return render_template("mapv2.html", user=json.dumps({
        "id": getattr(current_user, "id"),
        "username": getattr(current_user, "email"),
        "last_login": getattr(current_user, "last_login")
    }, default=dthandler), 
    tokens=json.dumps(queries, default=dthandler), 
    preferences= users.getUserPrefs(),
    saved_queries=json.dumps(to_json(user), default=dthandler));
#######################
## User REST Methods ##
#######################

# Get all users ##

# @app.route('/users', methods=['GET'])
# @login_required
# def users():
#     users = tryConnection(lambda: models.Users.query.all())
#     return flask.jsonify(users=to_json_list(users))

# Get one user by their id ##


@app.route('/user', methods=['GET'])
@login_required
def getUser():
    user = models.Users.query.get(getattr(current_user, "id"));
    if(user is None):
        return 'User does not exist'
    del user.password
    return flask.jsonify(user=to_json(user))

# Delete user ##


@app.route('/users', methods=['DELETE'])
@login_required
def deleteUser():
    id = request.args.get('id')
    user = tryConnection(lambda: models.Users.query.get(id))
    db.session.delete(user)
    db.session.commit()
    return 'User successfully deleted'

# Deactivate account ##
@app.route('/deactive', methods=['POST'])
def deactiveUser():
    user_id = request.args.get('user_id')
    user = tryConnection(lambda: models.Users.query.get(user_id))
    user.active = models.INACTIVE
    db.session.commit()
    return 'User successfully deactivated\n'

# Create new user ##
@app.route('/users', methods=['POST'])
def createUser():
    try:
        username = request.form['email']
        password = request.form['password']
        email = request.form['email']
        validation_token = binascii.b2a_hex(os.urandom(15))
        # first_name = request.form['first_name']
        # last_name = request.form['last_name']
        # The db only accepts a certain pass length
        user = tryConnection(lambda: models.Users(
            username=username, email=email, first_name="",
            last_name="", password=bcrypt.generate_password_hash(password),
            last_login=datetime.datetime.now(), account_validation_token=validation_token))
        db.session.add(user)
        db.session.commit()
        message = Template(users.getValidationMessage())
        send_email(["spurcell93@gmail.com"], "Welcome to the NewsMap!", message.substitute({
            "port": port,
            "token": validation_token,
            "email": email,
            "url" : app.config.get("url")
        }));
        return redirect("./?success=0");
    except IntegrityError as e:
        db.session.flush()
        # error = {'error_code': e.orig[0], 'error_string': e.orig[1]}
        return redirect("./?error=2&username=" + username + "&email=" + email)
    except Exception as e:
        db.session.flush()
        raise e

# User login ##
@lm.user_loader
def load_user(userid):
    return tryConnection(lambda: models.Users.query.get(userid))
 
@lm.token_loader
def load_token(token):
    max_age = app.config["REMEMBER_COOKIE_DURATION"].total_seconds()
 
    #Decrypt the Security Token, data = [username, hashpass]
    data = login_serializer.loads(token, max_age=max_age)
 
    #Find the User
    user = models.Users.query.get(data[0])
 
    #Check Password and return user or None
    if user and data[1] == user.password:
        return user
    return None


@app.route('/login', methods=['POST'])
def login():
    username = request.form['username']
    password = request.form['password']
    print username
    print password
    user = tryConnection(lambda: models.Users.query.filter_by(username=username).all()[0])
    if user is None:
        return redirect("./?error=0");
    if not bcrypt.check_password_hash(getattr(user, 'password'), password):
        return redirect("./?error=1");
    if getattr(user, "active") == 0:
        return redirect("./?error=3");
    user.last_login = datetime.datetime.now()
    db.session.commit()
    login_user(user, remember=True)
    return redirect("./map")

@app.route('/logout', methods=['GET'])
def logout():
    logout_user()
    return redirect("./")

# User 'liked' a query ##
@app.route('/favorite', methods=['POST'])
@login_required
def favorite():
    try:
        user_id = getattr(current_user, "id");
        query_id = request.form.get('query_id')
        if query_id is None:
            query_id = json.loads(createQuery(request.form.get("name"))).get("id");
        user = models.Users.query.get(user_id)
        query = models.Queries.query.get(query_id)
        if query is not None:
            if not tryConnection(lambda: db.session.query(models.users_has_queries)
                .filter_by(users_id=user_id, queries_id=query_id).all()):
                user.queries.append(query)
                db.session.commit()
            return json.dumps({"success": True, "id": query_id})
    except Exception, err:
        print traceback.format_exc()
        return json.dumps({"success": False})

@app.route("/unfavorite", methods=["POST"])
@login_required
def unFavorite():
    user_id = getattr(current_user, "id");
    query_id = request.form.get('id')
    query = models.Queries.query.get(query_id)
    if query is None:
        return {"error": "No query by that name"}, status.HTTP_417_EXPECTATION_FAILED
    else:
        sql = "delete from users_has_queries where users_id = '" + str(user_id) + "' and queries_id = '" + str(query_id) + "'"
        print sql
        db.engine.execute(sql)
        return json.dumps({"deleted": True}), status.HTTP_200_OK
    # except Exception, err:
        # return json.dumps({"error": "No query by that name"}), status.HTTP_417_EXPECTATION_FAILED

# User 'liked' a story ##
@app.route('/favoriteStory', methods=['POST'])
@login_required
def favoriteStory():
  try:
    user_id = request.form.get('user_id')
    story_id = request.form.get('story_id')
    user = models.Users.query.get(user_id)
    story = models.Stories.query.get(story_id)
    if story is not None:
      if not tryConnection(lambda: db.session.query(models.users_has_stories).filter_by(users_id=user_id, stories_id=story_id).all()):
        users.stories.append(query)
        db.session.commit()
      return json.dumps({"success": True})
  except Exception, err:
    print traceback.format_exc()
    return json.dumps({"success": False})

########################
## Query REST Methods ##
########################

# Get all queries ##
@app.route('/queries', methods=['GET'])
@login_required
def queries():
    queries = tryConnection(lambda: models.Queries.query.all())
    return flask.jsonify(queries=to_json_list(queries, True))

# Get one query by id or by title ##
@app.route('/queries/<string:identifier>', methods=['GET'])
@login_required
def getQueryById(identifier):
    return manager.getQueryById(identifier)
@app.route('/title/query/<string:title>', methods=['GET'])
def getQueryByTitle(title):
    return manager.getQueryByTitle(title)

# Create a new query ##
@app.route('/queries/<string:title>', methods=['POST','PUT'])
@login_required
def createQuery(title=None):
    if title is None:
        title = request.form.get('title')
    last_query = datetime.datetime.now()
    existing = tryConnection(lambda: models.Queries.query.filter_by(title = title).all())
    query_id = None
    if not existing: 
        query = models.Queries(title=title, last_query=last_query, created=last_query)
        db.session.add(query)
        db.session.commit()
        query_id = query.id
    else: 
        query_id = existing[0].id
    # Return the ID of the query, whether new or old
    return json.dumps({'id': query_id})


@app.route("/queryExists/<string:title>", methods=["GET"])
@login_required
def exists(title=None):
    if title is None:
        return json.dumps({"exists": False});
    else: 
        return manager.doesQueryExist(title);


########################
## Story REST Methods ##
########################

# Get all stories ##


@app.route('/stories', methods=['GET'])
@login_required
def stories():
    stories = models.Stories.query.all()
    return flask.jsonify(stories=to_json_list(stories))

# Get story by id ##


@app.route('/stories/<string:id>', methods=['GET'])
@login_required
def getStory(id):
    story = tryConnection(lambda: models.Stories.query.get(id))
    if (story is None):
        return flask.jsonify()
    return flask.jsonify(story=to_json(story))

# Create a new story ##
@app.route('/stories', methods=['POST'])
# @app.route(('/stories/<string:title>/<string:publication>/'
#            '<string:date>/<string:author>/<string:url>/<float:lat>'
#            '/<float:lng>'))
@login_required
def createStory(title=None, publication=None, date=None, author=None, url=None,
                lat=None, lng=None, content=None, query_id=None, aggregator='Yahoo', location=''):
    return manager.createStory(title, publication, date, author, url, lat, lng, content, query_id, aggregator, location)

# Create a bunch of new stories #
@app.route('/stories/many', methods=['POST'])
@login_required
def createManyStories():
    stories = request.json
    resultIds = []
    for story in stories:
        title = story.get('title')
        content = story.get('content')
        publication = story.get('publisher')
        date = parser.parse(story.get("date")).strftime('%Y-%m-%d %H:%M:%S')
        url = story.get('url')
        lat = story.get('lat')
        lng = story.get('lng')
        location = story.get('location')
        aggregator = story.get('aggregator')
        query_id = story.get('query_id')
        location = story.get('location')
        resultIds.append(createStory(title, publication, date, None, url, lat, lng, content, query_id, aggregator, location));
    return json.dumps({"success": True})

@app.route('/stories/<string:id>', methods=['PUT'])
@login_required
def storyPut(id):
    story = models.Stories.query.get(id)
    story.lat = request.json.get("lat")
    story.lng = request.json.get("lng")
    db.session.commit()
    return flask.jsonify(story=to_json(story))

# Add story to an existing query ##
@app.route('/addStoryToQuery/<string:query_id>/<string:story_id>', methods=['POST'])
@login_required
def addStoryToQuery(query_id, story_id):
    return manager.addStoryToQuery(query_id, story_id)

# Add a list of stories to an existing query ##
@app.route('/addStoriesToQuery', methods=['POST'])
@login_required
def addStoriesToQuery():
    story_list = request.form.getlist('stories')[0].split(",")
    query_id = request.form.get('query_id')
    query = tryConnection(lambda: models.Queries.query.get(query_id))
    if query is None:
        return 'Query does not exist\n'
    for story_id in story_list:
        story = models.Stories.query.get(story_id)
        if story is None:
            continue
        # story.queries.append(query)
    # db.session.commit()
    return 'Success!\n'