from app import db
from sqlalchemy.dialects.mysql import TINYINT, TIMESTAMP, DATETIME

ACTIVE = 1
INACTIVE = 0

users_has_queries = db.Table('users_has_queries',
                             db.Column(
                                 'users_id', db.Integer,
                                 db.ForeignKey('users.id')),
                             db.Column(
                                 'queries_id', db.Integer,
                                 db.ForeignKey('queries.id')),
                             db.Column('active', TINYINT, default=ACTIVE)
                             )

queries_has_stories = db.Table('queries_has_stories',
                               db.Column(
                                   'stories_id', db.Integer,
                                   db.ForeignKey('stories.id')),
                               db.Column(
                                   'queries_id', db.Integer,
                                   db.ForeignKey('queries.id')),
                               db.Column('active', TINYINT, default=ACTIVE)
                               )


class Users(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(45), index=True, unique=True)
    email = db.Column(db.String(45), index=True, unique=True)
    first_name = db.Column(db.String(45))
    last_name = db.Column(db.String(45))
    active = db.Column(TINYINT, default=ACTIVE)
    password = db.Column(db.String(45))
    last_login = db.Column(DATETIME)
    queries = db.relationship('Queries', secondary=users_has_queries,
                              backref=db.backref('users', lazy='dynamic'))


class Queries(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(45), index=True, unique=True)
    created = db.Column(TIMESTAMP)
    last_query = db.Column(TIMESTAMP)
    active = db.Column(TINYINT, default=ACTIVE)


class Stories(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(45), index=True, unique=True)
    publication = db.Column(db.String(45))
    date = db.Column(DATETIME)
    author = db.Column(db.String(45))
    url = db.Column(db.String(255))
    created = db.Column(TIMESTAMP)
    active = db.Column(TINYINT, default=ACTIVE)
    lat = db.Column(db.Float)
    lng = db.Column(db.Float)
    queries = db.relationship('Queries', secondary=queries_has_stories,
                              backref=db.backref('stories', lazy='dynamic'))
