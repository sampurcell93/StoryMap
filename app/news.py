import urllib
import json
import urllib2
import flask
import oauth2
import datetime
import oauth.oauth as oauth
from pprint import pprint
from calais import Calais
from sqlalchemy import exc
from sqlalchemy.exc import IntegrityError
from dateutil import parser
from sqlalchemy import select
from views import QueryManager
from app import app, models, db, lm, login_serializer
from flask import Flask,redirect,request,render_template, g
from flask.ext.login import login_user, logout_user, current_user, login_required

dthandler = lambda obj: obj.isoformat() if isinstance(obj, datetime.datetime)  or isinstance(obj, datetime.date) else None

Manager = QueryManager()

def tryConnection (applyfun): 
    try:
        return applyfun()
    except exc.SQLAlchemyError:
        db.session.rollback()
        return applyfun()

class News():
    normalizers = {
        "feedzilla" : {
                    'aggregator': lambda val: 'feedzilla',
                    'date'      : lambda val: parser.parse(val.get("publish_date")),
                    'content'   : 'summary'
        }, 
        "google"    : {
                    'aggregator': lambda val: 'google',
                    'url': 'unescapedUrl',
                    'date': lambda val: parser.parse(val.get("publishedDate")),
        },
        "yahoo"     : {
                    'aggregator': lambda val: 'yahoo',
                    'content': 'abstract',
                    'publisher': 'source',
                    'date': lambda val: datetime.datetime.fromtimestamp(float(val.get("date")))
        }
    }

    def filterExistingStories(self, stories):
        filtered = []
        stories = json.loads(stories)
        if stories is None: return filtered;
        for story in stories:
            exists = tryConnection(lambda: models.Stories.query.filter_by(title = story.get("title"), url=story.get("url")).all())
            if not exists: filtered.append(story)
        return filtered;

    def getAllNewStories(self, title=None, analyze=True):
        print "getting all news and storing it"
        f = self.filterExistingStories(self.feedZilla(title, analyze));
        # g = self.filterExistingStories(self.google(title, analyze));
        # y = self.filterExistingStories(self.yahoo(title, analyze));
        return f


    def analyzeStories(self, stories):
        if stories is None: return []
        for story in stories:
            aggregator = story.get("aggregator")
            # Normalize and analyze the story
            getCoords(story)
        # Return all the analyzed stories
        return stories


    def feedZilla(self, title=None, analyze=True):
        q = title
        if title is None: q = request.args['q']
        if request and request.args.get("analyze", {}) == "false": analyze = False
        data = {'q': q, 'count': 100}
        url = 'http://api.feedzilla.com/v1/articles.json?'+urllib.urlencode(data)
        req = urllib2.Request(url)
        req.add_header('Accept', 'application/json')
        req.add_header("Content-type", "application/x-www-form-urlencoded")
        # Issue request
        res = urllib2.urlopen(req).read()
        blob = json.loads(res)
        if blob is not None: stories = blob.get("articles", {})
        if stories is not None:
            for story in stories: 
                normalize(story, self.normalizers['feedzilla'])
                if analyze is True: getCoords(story)
        return json.dumps(stories, default=dthandler)


    def google(self, title=None, analyze=True, start='0'):
        # Query and offset of stories
        q = title
        if title is None and request: q = request.args['q']
        if request: start = request.args['start']
        if request and request.args.get("analyze", {}) == "false": analyze = False
        data = {'start': start, 'q': q}
        url = "https://ajax.googleapis.com/ajax/services/search/news?v=1.0&rsz=8&"+urllib.urlencode(data)
        # Curl request headers
        req = urllib2.Request(url)
        req.add_header('Accept', 'application/json')
        req.add_header("Content-type", "application/x-www-form-urlencoded")
        # Issue request
        res = urllib2.urlopen(req).read()
        blob = json.loads(res)
        if blob is not None: stories = blob.get("responseData", {})
        if stories: stories = stories.get("results")
        else: return json.dumps([])
        if stories is not None:
            for story in stories: 
                normalize(story, self.normalizers['google'])
                if analyze is True: getCoords(story)
        return json.dumps(stories, default=dthandler)
    def yahoo(self, title=None, analyze=True, start='0'):
        q = title
        if title is None and request: q = request.args['q']
        if start == "0" and request: start = request.args['start']
        if request and request.args.get("analyze", {}) == "false": analyze = False
        URL = "http://yboss.yahooapis.com/ysearch/news"
        OAUTH_CONSUMER_KEY = "dj0yJmk9RHp0ckM1NnRMUmk1JmQ9WVdrOVdUbHdOMkZLTTJVbWNHbzlNakV5TXpReE1EazJNZy0tJnM9Y29uc3VtZXJzZWNyZXQmeD0xMg--"
        OAUTH_CONSUMER_SECRET = "626da2d06d0b80dbd90799715961dce4e13b8ba1"
        data = {
            "q": q,
            "start": start,
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
        response  = urllib.urlopen(complete_url).read()
        stories = json.loads(response).get("bossresponse").get("news", {}).get("results")
        if stories is not None:
            for story in stories: 
                normalize(story, self.normalizers['yahoo'])
                if analyze is True: getCoords(story)
        return json.dumps(stories, default=dthandler)

t = News()

@app.route("/externalNews", methods=['GET'])
@login_required
def getNews():
    sources = {
        'google': t.google,
        'yahoo': t.yahoo,
        'feedzilla': t.feedZilla
    }
    return sources[request.args['source']](request.args.get("q"), request.args.get("analyze"))

@app.route("/analyze", methods=['POST'])
@login_required
def analyze():
    print "analyzing"
    stories = request.json.get("stories")
    print stories
    stories = json.loads(stories)
    return json.dumps(Manager.analyzeStories(stories), default=dthandler)

# Takes a story dict, and dict with values of either type string or type function
# String values simply switch the name of the key in a kay value pair to the new key name
# Functions are applied to the value, like a one time map.
def normalize(story, keymap):
    for key in keymap:
        val = keymap[key]
        if type(val) == str:
            story[key] = story.get(val)
        elif hasattr(val, '__call__'):
            story[key] = val(story)
    return story

# Expects a normalized story, which it then maps coords onto
def getCoords (story, normalizeObj=None): 
    if normalizeObj is not None: 
        normalize(story, normalizeObj)
    coordinates = coords(story.get("content") + story.get("title"))
    story['lat'] = coordinates.get('lat')
    story['lng'] = coordinates.get('lng')
    story['location'] = coordinates.get('location')

# Takes in a content string, runs it through calais,
# and returns coords if found as a {lat: x, lng: x} dict
def coords(content=None):
    if content is None:
        return 
    key = "c3wjfrkfmrsft3r5wgxm5skr"
    calais = Calais(key, submitter="Sam Purcell")
    empty = {'lat': None, 'lng': None}
    try: resp = vars(calais.analyze(content.encode("utf-8")))
    except Exception as e: resp = {}
    entities = resp.get("entities")
    if entities is None: return empty
    for entity in entities:
        resolutions = entity.get("resolutions")
        if resolutions:
            # pprint(entity.get("resolutions"))
            for coords in resolutions: 
                lat      = coords.get("latitude")
                lng      = coords.get("longitude")
                location = coords.get("name")
                if lat and lng:
                    return {'lat': float(lat), 'lng': float(lng), 'location': location}
    return empty