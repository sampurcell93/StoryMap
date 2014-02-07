from apscheduler.scheduler import Scheduler
from pprint import pprint
from app import app, models, db, lm, login_serializer
import flask
from sqlalchemy import exc
from sqlalchemy.exc import IntegrityError
from sqlalchemy import select
from news import News
from views import QueryManager

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
    queries = models.Queries.query.all()
    # Get all queries in the system - todo add a date checked filter
    for query in queries:
        # Get all the new stories for a query
        newStories = news.getAllNewStories(query.title, False)
        if newStories is None: return;
        # Analyze each story for location
        print "about to analyze all new stories"
        newStories = news.analyzeStories(newStories)
        # Save each story to the DB and link it to the query
        for story in newStories:
            print "Creating story with title: "
            print story.get("title")
            print " and url: "
            print story.get("url")
            Manager.createStory(
                story.get("title"),
                story.get("publication"),
                story.get("date"),
                story.get("author"),
                story.get("url"),
                story.get("lat"),
                story.get("lng"),
                story.get("content"),
                query.id,
                story.get("aggregator"),
                story.get("location")
            )
    return True

sched = Scheduler()
sched.start()


# updateAllQueries()
# @sched.interval_schedule(seconds=10)
# def update_queries():
    # wrapper()

@sched.cron_schedule(day_of_week='mon-sun', hour=23)
def scheduled_job():
    updateAllQueries()
