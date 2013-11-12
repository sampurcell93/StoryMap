from dateutil import parser
import datetime
from pprint import pprint
from app import app, models, db, lm, login_serializer
import datetime
import traceback
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
from calais import Calais
from sqlalchemy.exc import IntegrityError
from sqlalchemy import select
from flask.ext.login import login_user, logout_user, current_user, login_required
bcrypt = Bcrypt(app)

views = "./views"

dthandler = lambda obj: obj.isoformat() if isinstance(obj, datetime.datetime)  or isinstance(obj, datetime.date) else None
def _json_object_hook(d): 
    return namedtuple('X', d.keys())(*d.values())
def json2obj(data): 
    return json.loads(data, object_hook=_json_object_hook)

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


## User Interfaces ##
@app.route('/')
def index():
    if current_user.is_authenticated():
        return redirect("/map")
    return render_template("login.html", error=request.args.get('error'), args=request.args)

@app.errorhandler(404)
def page_not_found(e):
    return render_template("404.html")

@app.route("/map")
@login_required
def map(): 
    return render_template("map.html", user=getattr(current_user, "id"))
#######################
## User REST Methods ##
#######################

# Get all users ##

@app.route('/users', methods=['GET'])
@login_required
def users():
    users = models.Users.query.all()
    return flask.jsonify(users=to_json_list(users))

# Get one user by their id ##


@app.route('/users/<string:id>', methods=['GET'])
@login_required
def getUser(id):
    user = models.Users.query.get(id)
    if(user is None):
        return 'User does not exist'
    del user.password
    return flask.jsonify(user=to_json(user))

# Delete user ##


@app.route('/users', methods=['DELETE'])
@login_required
def deleteUser():
    id = request.args.get('id')
    user = models.Users.query.get(id)
    db.session.delete(user)
    db.session.commit()
    return 'User successfully deleted'

# Deactivate account ##


@app.route('/deactive', methods=['POST'])
def deactiveUser():
    user_id = request.args.get('user_id')
    user = models.Users.query.get(user_id)
    user.active = models.INACTIVE
    db.session.commit()
    return 'User successfully deactivated\n'

# Create new user ##


@app.route('/users', methods=['POST'])
@login_required
def createUser():
    try:
        username = request.form['username']
        password = request.form['password']
        email = request.form['email']
        first_name = request.form['first_name']
        last_name = request.form['last_name']
        # The db only accepts a certain pass length
        user = models.Users(
            username=username, email=email, first_name=first_name,
            last_name=last_name, password=bcrypt.generate_password_hash(password),
            last_login=datetime.datetime.now())
        db.session.add(user)
        db.session.commit()
        return 'User successfully created'
    except IntegrityError as e:
        db.session.flush()
        error = {'error_code': e.orig[0], 'error_string': e.orig[1]}
        return redirect("/?error=2&username=" + username + "&email=" + email + "&first_name=" + first_name + "&last_name=" + last_name)
    except Exception as e:
        db.session.flush()
        return 'Error\n'

# User login ##
@lm.user_loader
def load_user(userid):
    return models.Users.query.get(userid)
 
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
    user = models.Users.query.filter_by(username=username).first()
    if user is None:
        return redirect("/?error=0")
    if not bcrypt.check_password_hash(getattr(user, 'password'), password):
        return redirect("/?error=1")
    user.last_login = datetime.datetime.now()
    db.session.commit()
    login_user(user, remember=True)
    return redirect("/map")

@app.route('/logout', methods=['GET'])
def logout():
    logout_user()
    return redirect("/")

# User 'liked' a query ##


@app.route('/favorite', methods=['POST'])
@login_required
def favorite():
    try:
        user_id = request.form.get('user_id')
        query_id = request.form.get('query_id')
        user = models.Users.query.get(user_id)
        query = models.Queries.query.get(query_id)
        if query is not None:
            pprint(db.session.query(models.users_has_queries).filter_by(users_id=user_id, queries_id=query_id).all())
            if not db.session.query(models.users_has_queries).filter_by(users_id=user_id, queries_id=query_id).all():
                print "adding"
                user.queries.append(query)
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
    queries = models.Queries.query.all()
    return flask.jsonify(queries=to_json_list(queries, True))

# Get one query by id or by title ##
@app.route('/queries/<string:identifier>', methods=['GET'])
@login_required
def getQueryById(identifier):
    digit = False
    try:
        digit = identifier.isdigit()
    except Exception: 
        digit = True
    if digit is True:
        print "digit"
        query = models.Queries.query.get(identifier)
        if (query is None):
            return json.dumps({"exists": False})
        return json.dumps(to_json(query, True), default=dthandler)
    else:
        return getQueryByTitle(identifier)
@app.route('/title/query/<string:title>', methods=['GET'])
def getQueryByTitle(title):
    print "titling"
    query = models.Queries.query.filter_by(title = title).all()
    if not query:
        return json.dumps({"exists": False})
    print query[0].id
    return getQueryById(query[0].id)


# Create a new query ##
@app.route('/queries/<string:title>', methods=['POST'])
@login_required
def createQuery(title=None):
    if title is None:
        title = request.form.get('title')
    last_query = datetime.datetime.now()
    existing = models.Queries.query.filter_by(title = title).all()
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


@app.route('/queries/<string:id>', methods=['PUT'])
@login_required
def succeedPut(id):
    return json.dumps({"success": True})


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
    story = models.Stories.query.get(id)
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
                lat=None, lng=None, content=None, query_id=None):
    if title is None:
        print "setting shit"
        pprint(request.json)
        title = request.json['title']
        content = request.json['content']
        publication = request.json['publisher']
        date = parser.parse(request.json['date']).strftime('%Y-%m-%d %H:%M:%S')
        url = request.json['url']
        lat = request.json.get('lat')
        lng = request.json.get('lng')
        aggregator = request.json.get('type')
        query_id = request.json.get('query_id')
        print "query_id:"
        print query_id
    try:
        story = models.Stories(title=title, publisher=publication, date=date, url=url, lat=lat, lng=lng, content=content, aggregator=aggregator)
        db.session.add(story)
        db.session.commit()
        if query_id is not None:
            addStoryToQuery(query_id, story.id)
        return json.dumps({"id": story.id})
    except IntegrityError as e:
        db.session.flush()
        return json.dumps({"duplicate": True})

@app.route('/stories/<string:id>', methods=['PUT'])
@login_required
def storyPut(id):
    return json.dumps({"success": True})

# Add story to an existing query ##
@app.route('/addStoryToQuery/<string:query_id>/<string:story_id>', methods=['POST'])
@login_required
def addStoryToQuery(query_id, story_id):
    story = models.Stories.query.get(story_id)
    if story is None:
        return 'Story does not exist\n'
    query = models.Queries.query.get(query_id)
    if query is None:
        return 'Query does not exist\n'
    story.queries.append(query)
    db.session.commit()
    return 'Success!\n'

# Add a list of stories to an existing query ##
@app.route('/addStoriesToQuery', methods=['POST'])
@login_required
def addStoriesToQuery():
    story_list = request.form.getlist('stories')[0].split(",")
    query_id = request.form.get('query_id')
    query = models.Queries.query.get(query_id)
    if query is None:
        return 'Query does not exist\n'
    for story_id in story_list:
        story = models.Stories.query.get(story_id)
        if story is None:
            continue
        # story.queries.append(query)
    # db.session.commit()
    return 'Success!\n'

@app.route("/externalNews", methods=['GET'])
@login_required
def getNews():
    sources = {
        'google': googleNews,
        'yahoo': yahooNews,
    }
    return sources[request.args['source']]()

def googleNews():
    # Query and offset of stories
    query = request.args['q']
    start = request.args['start']
    data = {'start':start, 'q':query}
    url = "https://ajax.googleapis.com/ajax/services/search/news?v=1.0&rsz=8&"+urllib.urlencode(data)
    # Curl request headers
    req = urllib2.Request(url)
    req.add_header('Accept', 'application/json')
    req.add_header("Content-type", "application/x-www-form-urlencoded")
    # Issue request
    res = urllib2.urlopen(req)
    return res.read()
def yahooNews():
    URL = "http://yboss.yahooapis.com/ysearch/news"
    OAUTH_CONSUMER_KEY = "dj0yJmk9RHp0ckM1NnRMUmk1JmQ9WVdrOVdUbHdOMkZLTTJVbWNHbzlNakV5TXpReE1EazJNZy0tJnM9Y29uc3VtZXJzZWNyZXQmeD0xMg--"
    OAUTH_CONSUMER_SECRET = "626da2d06d0b80dbd90799715961dce4e13b8ba1"
    data = {
        "q": request.args["q"],
        "start": request.args["start"],
        "sort": "date",
        "age": "1000d",
        "format":"json"
    }
    consumer = oauth.OAuthConsumer(OAUTH_CONSUMER_KEY, OAUTH_CONSUMER_SECRET)
    signature_method_plaintext = oauth.OAuthSignatureMethod_PLAINTEXT()
    signature_method_hmac_sha1 = oauth.OAuthSignatureMethod_HMAC_SHA1()
    oauth_request = oauth.OAuthRequest.from_consumer_and_token(consumer, token=None, http_method='GET', http_url=URL, parameters=data)
    oauth_request.sign_request(signature_method_hmac_sha1, consumer, "")
    complete_url = oauth_request.to_url()
    response = urllib.urlopen(complete_url)
    return response.read()

@app.route("/test", methods=['GET'])
def test():
    params = request.args.getlist("params")
    for i in params:
        val = json2obj(json.dumps(i))
        print val['name']
    return "Hello"

@app.route("/calais", methods=['GET'])
@login_required
def calais():
    key = "c3wjfrkfmrsft3r5wgxm5skr"
    calais = Calais(key, submitter="Sam Purcell")
    print request.args['content'].encode("utf-8")
    resp = vars(calais.analyze(request.args['content'].encode("utf-8")))
    return flask.jsonify(**resp)
