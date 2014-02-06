from apscheduler.scheduler import Scheduler
from pprint import pprint
from app import app, models, db, lm, login_serializer
import flask
from sqlalchemy import exc
from sqlalchemy.exc import IntegrityError
from sqlalchemy import select
from news import News

def tryConnection (applyfun): 
    try:
        return applyfun()
    except exc.SQLAlchemyError:
        print "operational error, db disconnected"
        db.session.rollback()
        return tryConnection(applyfun)

news = News()

def wrapper():
    queries = models.Queries.query.all()
    for query in queries:
        newStories = news.getAllNewStories(query.title, False)
        newStories = news.analyzeStories(newStories)
    return "testing"

# sched = Scheduler()
# sched.start()

# wrapper()

# @sched.interval_schedule(seconds=10)
# def update_queries():
    # wrapper()

# @sched.cron_schedule(day_of_week='mon-sun', hour=23)
# def scheduled_job():
#     print 'This job is run every weekday at 5pm.'

# while True: pass