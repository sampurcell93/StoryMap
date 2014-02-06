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
from sqlalchemy import select
from app import app, models, db, lm, login_serializer
from flask import Flask,redirect,request,render_template, g
from flask.ext.login import login_user, logout_user, current_user, login_required

dthandler = lambda obj: obj.isoformat() if isinstance(obj, datetime.datetime)  or isinstance(obj, datetime.date) else None

def tryConnection (applyfun): 
    try:
        return applyfun()
    except exc.SQLAlchemyError:
        print "operational error, db disconnected"
        db.session.rollback()
        return tryConnection(applyfun)


class News():

    def filterExistingStories(self, stories):
        filtered = []
        stories = json.loads(stories)
        if stories is None: return filtered;
        for story in stories:
            exists = tryConnection(lambda: models.Stories.query.filter_by(title = story.get("title")).all())
            if not exists: filtered.append(story)
        return filtered;

    def getAllNewStories(self, title=None, analyze=True):
        print "getting all news and storing it"
        f = self.filterExistingStories(self.feedZilla(title, analyze));
        g = self.filterExistingStories(self.google(title, analyze));
        y = self.filterExistingStories(self.yahoo(title, analyze));
        return f + g + y


    # def analyzeStories(self, stories):
    #     if stories is None: return []
    #     for story in stories:


    def feedZilla(self, title=None, analyze=True):
        q = title
        print q
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
        if analyze is True:
            if stories is not None:
                for story in stories:
                    getCoords(story, {
                        'aggregator': lambda val: 'feedzilla',
                        'date'      : 'publish_date',
                        'content'   : 'summary'
                    })
        return json.dumps(stories, default=dthandler)
    def google(self, title=None, start=None, analyze=True):
        # Query and offset of stories
        q = title
        s = start
        if title is None: q = request.args['q']
        if start is None: s = request.args['start']
        if request and request.args.get("analyze", {}) == "false": analyze = False
        data = {'start': s, 'q': q}
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
        if analyze is True:
            if stories is not None:
                for story in stories:
                    getCoords(story, {
                        'aggregator': lambda val: 'google',
                        'url': 'unescapedUrl',
                        'date': lambda val: datetime.datetime.strptime(val.get("publishedDate"), "%a, %d %b %Y %H:%M:%S -0800")
                    })
        return json.dumps(stories, default=dthandler)
    def yahoo(self, title=None, start=None, analyze=True):
        q = title
        s = start
        if title is None: q = request.args['q']
        if start is None: s = request.args['start']
        if request and request.args.get("analyze", {}) == "false": analyze = False
        URL = "http://yboss.yahooapis.com/ysearch/news"
        OAUTH_CONSUMER_KEY = "dj0yJmk9RHp0ckM1NnRMUmk1JmQ9WVdrOVdUbHdOMkZLTTJVbWNHbzlNakV5TXpReE1EazJNZy0tJnM9Y29uc3VtZXJzZWNyZXQmeD0xMg--"
        OAUTH_CONSUMER_SECRET = "626da2d06d0b80dbd90799715961dce4e13b8ba1"
        print start
        data = {
            "q": q,
            "start": s,
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
        if analyze is True:
            if stories is not None:
                for story in stories:
                    getCoords(story, {
                        'content': 'abstract',
                        'aggregator': lambda val: 'yahoo',
                        'publisher': 'source',
                        'date': lambda val: datetime.datetime.fromtimestamp(float(val.get("date")))
                    })
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
    return sources[request.args['source']](request.args.get("q"))
# Takes a story dict, and dict with values of either type string or type function
# String values simply switch the name of the key in a kay value pair to the new key name
# Functions are applied to the value, like a one time map.
def normalize(story, keymap):
    for key in keymap:
        val = keymap[key]
        if type(val) == str:
            story[key] = story[val]
            del story[val]
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