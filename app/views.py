from pprint import pprint
from app import app, models, db
import datetime
import flask
from flask import request
from flask import render_template
from flask_oauth import OAuth
import time
import oauth2
import oauth.oauth as oauth
import urllib
import urllib2
import httplib2
import json
from calais import Calais
from sqlalchemy.exc import IntegrityError
from calais import Calais

views = "./views"

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


@app.route('/')
@app.route('/index')
def index():
    return render_template("index.html")

@app.errorhandler(404)
def page_not_found(e):
    return 'Woops this page does not exist.\n'

#######################
## User REST Methods ##
#######################

# Get all users ##


@app.route('/users', methods=['GET'])
def users():
    users = models.Users.query.all()
    return flask.jsonify(users=to_json_list(users))

# Get one user by their id ##


@app.route('/users/<string:id>', methods=['GET'])
def getUser(id):
    user = models.Users.query.get(id)
    if(user is None):
        return 'User does not exist'
    return flask.jsonify(user=to_json(user))

# Delete user ##


@app.route('/users', methods=['DELETE'])
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
def createUser():
    try:
        username = request.args.get('username')
        password = request.args.get('password')
        email = request.args.get('email')
        first_name = request.args.get('first_name')
        last_name = request.args.get('last_name')
        user = models.Users(
            username=username, email=email, first_name=first_name,
            last_name=last_name, password=password,
            last_login=datetime.datetime.now())
        db.session.add(user)
        db.session.commit()
        return 'User successfully created'
    except IntegrityError as e:
        db.session.flush()
        error = {'error_code': e.orig[0], 'error_string': e.orig[1]}
        return flask.jsonify(**error)
    except Exception as e:
        db.session.flush()
        return 'Error\n'

# User login ##


@app.route('/login', methods=['POST'])
def login():
    username = request.args.get('username')
    password = request.args.get('password')
    user = models.Users.query.filter_by(username=username).first()
    if user is None:
        return 'User does not exist\n'
    if getattr(user, 'password') != password:
        return 'Incorrect password\n'
    user.last_login = datetime.datetime.now()
    db.session.commit()
    return 'Success!\n'

# User 'liked' a query ##


@app.route('/favorite', methods=['POST'])
def favorite():
    try:
        user_id = request.args.get('user_id')
        query_id = request.args.get('query_id')
        user = models.Users.query.get(user_id)
        user.queries.append(models.Queries.query.get(query_id))
        db.session.commit()
        return 'Success!\n'
    except:
        return 'An error occured\n'

########################
## Query REST Methods ##
########################

# Get all queries ##


@app.route('/queries', methods=['GET'])
def queries():
    queries = models.Queries.query.all()
    return flask.jsonify(queries=to_json_list(queries, True))

# Get one query by id ##


@app.route('/queries/<string:id>', methods=['GET'])
def getQuery(id):
    query = models.Queries.query.get(id)
    if (query is None):
        return 'Query does not exist'
    return flask.jsonify(query=to_json(query, True))

# Create a new query ##


@app.route('/queries', methods=['POST'])
@app.route('/queries/<string:title>', methods=['POST'])
def createQuery(title=None):
    if title is None:
        title = request.args.get('title')
    last_query = datetime.datetime.now()
    query = models.Queries(title=title, last_query=last_query)
    db.session.add(query)
    db.session.commit()
    return 'Success!\n'

########################
## Story REST Methods ##
########################

# Get all stories ##


@app.route('/stories', methods=['GET'])
def stories():
    stories = models.Stories.query.all()
    return flask.jsonify(stories=to_json_list(stories))

# Get story by id ##


@app.route('/stories/<string:id>', methods=['GET'])
def getStory(id):
    story = models.Stories.query.get(id)
    if (story is None):
        return flask.jsonify()
    return flask.jsonify(story=to_json(story))

# Create a new story ##


@app.route('/stories', methods=['POST'])
@app.route(('/stories/<string:title>/<string:publication>/'
           '<string:date>/<string:author>/<string:url>/<float:lat>'
           '/<float:lng>'))
def createStory(title=None, publication=None, date=None, author=None, url=None,
                lat=None, lng=None):
    if title is None:
        title = request.args.get('title')
        publication = request.args.get('publication')
        date = request.args.get('date')
        author = request.args.get('author')
        url = request.args.get('url')
        lat = request.args.get('lat')
        lng = request.args.get('lng')
    story = models.Stories(title=title, publication=publication, date=date,
                           author=author, url=url, lat=lat, lng=lng)
    db.session.add(story)
    db.session.commit()
    return 'Success!\n'

# Add story to an existing query ##


@app.route('/addStoryToQuery', methods=['POST'])
def addStoryToQuery():
    story_id = request.args.get('story_id')
    query_id = request.args.get('query_id')
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
def addStoriesToQuery():
    story_list = request.args.getlist('stories')[0].split(",")
    query_id = request.args.get('query_id')
    query = models.Queries.query.get(query_id)
    if query is None:
        return 'Query does not exist\n'
    for story_id in story_list:
        story = models.Stories.query.get(story_id)
        if story is None:
            continue
        story.queries.append(query)
    db.session.commit()
    return 'Success!\n'

@app.route("/externalNews", methods=['GET'])
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

<<<<<<< HEAD
@app.route("/calais")
def calais():
    key = "c3wjfrkfmrsft3r5wgxm5skr"
    calais = Calais(key, submitter="Sam Purcell")
    print request.args['content'].encode("utf-8")
    resp = vars(calais.analyze(request.args['content'].encode("utf-8")))
    return flask.jsonify(**resp)
=======
@app.route("/calais", methods=['GET'])
def calais():
    API_KEY = "c3wjfrkfmrsft3r5wgxm5skr"
    content = request.args.get("content").encode('utf-8')
    calais = Calais(API_KEY, submitter="Story Map")
    result = calais.analyze(content)
    try:
        return json.dumps(result.entities)
    except:
        return json.dumps({'error':'An error occured'})
>>>>>>> 5aaabbfbfaf563ba165bafd191c9ba9ee0957f9c
