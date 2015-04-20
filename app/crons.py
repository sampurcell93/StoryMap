import sys
import time
from time import mktime
from datetime import datetime
from dateutil import parser
from apscheduler.scheduler import Scheduler
from pprint import pprint
from app import app, models, db, lm, login_serializer
import flask
from os import getcwd
from sqlalchemy import exc
from sqlalchemy.exc import IntegrityError
from sqlalchemy import select
from news import News
from views import QueryManager
import logging
logging.basicConfig( filename=''.join([getcwd(), '/', 'apscheduler.log']),
        level=logging.DEBUG,
        format='%(levelname)s[%(asctime)s]: %(message)s')

Manager = QueryManager()

def tryConnection (applyfun): 
    try:
        return applyfun()
    except exc.SQLAlchemyError:
        print "operational error, db disconnected"
        db.session.rollback()
        return tryConnection(applyfun)

news = News()

def updateAllQueries():
    print "CALLING UPDATE ALL QUERIES"
    queries = models.Queries.query.all()
    # Get all queries in the system - todo add a date checked filter
    for query in queries:
        id = query.id
        title = query.title
        print "title:" + title
        # # Get all the new stories for a query
        newStories = news.getAllNewStories(title, False)
        print newStories
        for feed in newStories:
            feedResponse = newStories[feed]
            if len(feedResponse) is 0:
                print "nothing returned for " + title + " from " + feed
                Manager.updateQueryRetrievalTime(id)
                continue;
            print "returned " + str(len(feedResponse)) + " stories from " + feed;
            analysisBlob = []
            for story in feedResponse:
                analysisBlob.append(story.get("title", "").encode("utf-8") + story.get("content", "").encode("utf-8"));
            analysis = news.analyzeStories(analysisBlob);
            for a, i in enumerate(analysis):
                story = feedResponse[a]
                story.update(i);
                # 2015-01-28T17:52:30-08:00
                date = parser.parse(story.get("date"));
                Manager.createStory(
                    story.get("title"),
                    story.get("publication"),
                    date,
                    story.get("author"),
                    story.get("url"),
                    story.get("lat"),
                    story.get("lng"),
                    story.get("content"),
                    id,
                    story.get("aggregator"),
                    story.get("location")
                    )
            Manager.updateQueryRetrievalTime(id)
        return True
    return True

sched = Scheduler()
sched.start()

# updateAllQueries()
@sched.cron_schedule(day_of_week='mon-sun', hour=12, minute=57)
def scheduled_job():
    updateAllQueries()
