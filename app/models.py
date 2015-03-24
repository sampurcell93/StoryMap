from app import db, login_serializer
import os,binascii
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

users_has_stories = db.Table('users_has_stories',
                               db.Column(
                                   'stories_id', db.Integer,
                                   db.ForeignKey('stories.id')),
                               db.Column(
                                   'users_id', db.Integer,
                                   db.ForeignKey('users.id')),
                               db.Column('active', TINYINT, default=ACTIVE)
                               )

class Preferences(db.Model):
  __tablename__ = "preferences";
  id = db.Column(db.Integer, primary_key=True)
  user_id = db.Column(db.Integer, db.ForeignKey('users.id'), index=True)

class Users(db.Model):
    id = db.Column(db.Integer, primary_key=True, autoincrement=True, nullable=False)
    username = db.Column(db.String(45), index=True, unique=True)
    email = db.Column(db.String(45), index=True, unique=True)
    first_name = db.Column(db.String(45))
    last_name = db.Column(db.String(45))
    active = db.Column(TINYINT, default=INACTIVE)
    password = db.Column(db.String(255))
    last_login = db.Column(DATETIME)
    reset_password_token = db.Column(db.String(45), default=binascii.b2a_hex(os.urandom(15)));
    account_validation_token = db.Column(db.String(45), default=binascii.b2a_hex(os.urandom(15)));
    queries = db.relationship('Queries', secondary=users_has_queries,
                              backref=db.backref('users', lazy='dynamic'))
    preferences = db.relationship('Preferences', backref=db.backref('users', uselist=True, lazy='dynamic'));

    # child = relationship("Child", backref=backref("parent", uselist=False))
    def is_authenticated(self):
        return True

    def is_active(self):
        return self.active

    def is_anonymous(self):
        return False

    def get_id(self):
        return unicode(self.id)

    def get_auth_token(self):
        """
        Encode a secure token for cookie
        """
        data = [str(self.id), self.password]
        return login_serializer.dumps(data)

    def __repr__(self):
        return '<User %r>' % (self.id)


class Queries(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(45), index=True, unique=True)
    created = db.Column(TIMESTAMP)
    last_query = db.Column(TIMESTAMP)
    active = db.Column(TINYINT, default=ACTIVE)

class Stories(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(300), index=True, unique=True)
    publisher = db.Column(db.String(300))
    date = db.Column(DATETIME)
    # author = db.Column(db.String(45))
    url = db.Column(db.String(255))
    created = db.Column(TIMESTAMP)
    active = db.Column(TINYINT, default=ACTIVE)
    aggregator = db.Column(db.String(255))
    location = db.Column(db.String(255))
    lat = db.Column(db.Float)
    lng = db.Column(db.Float)
    content = db.Column(db.Text)
    queries = db.relationship('Queries', secondary=queries_has_stories,
                              backref=db.backref('stories', lazy='dynamic'))
