from apscheduler.scheduler import Scheduler
from pprint import pprint
from app import app, models, db, lm, login_serializer
import flask
from sqlalchemy import exc
from sqlalchemy.exc import IntegrityError
from sqlalchemy import select
import news

def tryConnection (applyfun): 
    try:
        return applyfun()
    except exc.SQLAlchemyError:
        print "operational error, db disconnected"
        db.session.rollback()
        return applyfun()


def updateQuery(title):
    news.getAllNews(title)
    return "update q"

def test():
    queries = models.Queries.query.all()
    for query in queries:
        print query.title
        updateQuery(query.title)
    return "testing"


# test()
# 
# sched = Scheduler()
# sched.start()

# @sched.interval_schedule(seconds=3)
# def update_queries():
#     test()

# @sched.cron_schedule(day_of_week='mon-sun', hour=23)
# def scheduled_job():
#     print 'This job is run every weekday at 5pm.'

# while True: pass