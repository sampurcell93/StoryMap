import sys
import urllib
import json
import urllib2
import flask
import oauth2
import time
import datetime
import oauth.oauth as oauth
from pprint import pprint
from calais import Calais
from sqlalchemy import exc
from sqlalchemy.exc import IntegrityError
from dateutil import parser
from sqlalchemy import select
from views import QueryManager
from app import app, models, db, lm, login_serializer, queue
from flask import Flask,redirect,request,render_template, g
from flask.ext.login import login_user, logout_user, current_user, login_required

dthandler = lambda obj: obj.isoformat() if isinstance(obj, datetime.datetime)  or isinstance(obj, datetime.date) else None

def RateLimited(maxPerSecond):
    minInterval = 1.0 / float(maxPerSecond)
    def decorate(func):
        lastTimeCalled = [0.0]
        def rateLimitedFunction(*args,**kargs):
            elapsed = time.clock() - lastTimeCalled[0]
            leftToWait = minInterval - elapsed
            if leftToWait>0:
                time.sleep(leftToWait)
            ret = func(*args,**kargs)
            lastTimeCalled[0] = time.clock()
            return ret
        return rateLimitedFunction
    return decorate


Manager = QueryManager()
# Calais Rate limits our analysis requests, 
# this throttles requests without needing to sleep
AnalysisQueue = queue.Queue(.4);
AnalysisQueue.execute()
key = "c3wjfrkfmrsft3r5wgxm5skr"
CalaisObj = Calais(key, submitter="Sam Purcell")

@app.route("/dev", methods=["GET"])
def test():
    key = "c3wjfrkfmrsft3r5wgxm5skr"
    calais = Calais(key, submitter="Sam Purcell")
    return json.dumps(coords("How High? Historically speaking, what does Kentucky's potentially undefeated season mean? The post How High? appeared first on SLAMonline .".encode("utf-8")));

def pr(*args):
  print args[0] % (len(args) > 1 and args[1:] or [])
  sys.stdout.flush()

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
        f = self.filterExistingStories(self.feedZilla(title, analyze));
        # g = self.filterExistingStories(self.google(title, analyze));
        # y = self.filterExistingStories(self.yahoo(title, analyze));
        # return {"feedzilla": f, "google": g, "yahoo": y}
        return {"feedzilla": f}


    def analyzeStories(self, stories):
        if stories is None: return []
        for i, story in enumerate(stories):
            stories[i] = self.analyzeStory(stories[i])
        # Return all the analyzed stories
        return stories

    def analyzeStory(self, blob):
        story = {
            "title": blob.get("title") + " " + blob.get("content"),
            "content": "".encode("utf-8")
        }
        return getCoords(story)

    def feedZilla(self, title=None, analyze=True):
        q = title
        if title is None: q = request.args['q']
        if request and request.args.get("analyze", {}) == "false": analyze = False
        data = {'query': q, 'count': 100}
        url = 'http://api.feedzilla.com/v1/articles.json?'+urllib.urlencode(data)
        req = urllib2.Request(url)
        req.add_header('Accept', 'application/json')
        req.add_header("Content-type", "application/x-www-form-urlencoded")
        # Issue request
        try:
            res = urllib2.urlopen(req).read()
        except Exception as e:
            print "fucked up feedzilla response"
            return json.dumps({"sslerror": True})
        blob = json.loads(res)
        if blob is not None: 
            stories = blob.get("articles", {})
        if stories is not None:
            for story in stories: 
                normalize(story, self.normalizers['feedzilla'])
                if analyze is True: analyzeStory(story)
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
        try:
            res = urllib2.urlopen(req).read()
        except Exception as e:
            print "fucked up google response"
            return json.dumps({"sslerror": True})
        blob = json.loads(res)
        if blob is not None: stories = blob.get("responseData", {})
        if stories: stories = stories.get("results")
        else: return json.dumps([])
        if stories is not None:
            for story in stories: 
                normalize(story, self.normalizers['google'])
                if analyze is True: analyzeStory(story)
        return json.dumps(stories, default=dthandler)
        
    def yahoo(self, title=None, analyze=True, start='0'):
        q = title
        if title is None and request: q = request.args['q']
        if start == "0" and request: start = request.args['start']
        if request and request.args.get("analyze", {}) == "false": analyze = False
        URL = "http://yboss.yahooapis.com/ysearch/news"
        OAUTH_CONSUMER_KEY = "dj0yJmk9RHp0ckM1NnRMUmk1JmQ9WVdrOVdUbHdOMkZLTTJVbWNHbzlNakV5TXpReE1EazJNZy0tJnM9Y29uc3VtZXJzZWNyZXQmeD0xMg--"
        OAUTH_CONSUMER_SECRET = "626da2d06d0b80dbd90799715961dce4e13b8ba1"
        pr("here")
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
                if analyze is True: analyzeStory(story)
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
    pr(request.args.get('source'))
    pr(request.args.get("q"))
    return sources[request.args.get('source')](request.args.get("q"))

@app.route("/analyze/one", methods=['GET'])
@login_required
# Pass in a text blob
def analyzeOne():
    story = request.args['story']
    return json.dumps(t.analyzeStory(story), default=dthandler)

@app.route("/analyze/many", methods=['POST'])
@login_required
def analyzeMany():
    stories = request.form.get("stories")
    # pprint(stories);
    stories = json.loads(stories)
    return json.dumps(t.analyzeStories(stories), default=dthandler)

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



def handleEntities(entities):
    empty = {'lat': None, 'lng': None}
    if not entities:
        # pr("but no entities")
        return empty
    # print "############################\n"
    # print entities
    # print "############################\n"
    # if (not entities or isinstance(entities, list) is False):
        # return empty;
    for entity in entities:
        resolutions = entity.get("resolutions")
        if resolutions:
            # pprint(entity.get("resolutions"))
            for coords in resolutions:
                lat      = coords.get("latitude")
                lng      = coords.get("longitude")
                location = coords.get("name")
                if lat and lng:
                    print("returning with %s,%s", lat, lng)
                    return {'lat': float(lat), 'lng': float(lng), 'location': location}
    return empty;

# Takes in a content string, runs it through calais,
# and returns coords if found as a {lat: x, lng: x} dict

testme = 0

@RateLimited(4)  # 2 per second at most
def coords(content=None):
    print testme
    global testme
    testme += 1
    # pr("IN COORDS")
    empty = {'lat': None, 'lng': None}
    if content is None: 
        # pr("was none somehow")
        return empty;
    # print "############################\n"
    # print content.encode("utf-8");
    # print "############################\n"
    # pr("content was good")
    entities = []
    try: 
        # def deferredAnalyze:
            # calais.analyze(content.encode("utf-8"))
        # pr("about to get calais resp")
        # AnalysisQueue.push(deferredAnalyze)
        entities = CalaisObj.analyze(content.encode("utf-8"))
        print entities
    except Exception as e: 
        return empty;
        # pr("resp failure")
    return handleEntities(entities);

# Expects a normalized story, which it then maps coords onto
def getCoords (story, normalizeObj=None): 
    if normalizeObj is not None: 
        normalize(story, normalizeObj)
    content = story.get("content", '') + ' ' + story.get("title", '')
    print "before sleep"
    # time.sleep(.2);
    coordinates = coords(content)
    # time.sleep(.2);
    print "waking up"
    story['lat'] = coordinates.get('lat')
    story['lng'] = coordinates.get('lng')
    story['location'] = coordinates.get('location')
    story.pop("title", None);
    story.pop("content", None);
    return story
