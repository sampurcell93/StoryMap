# ************************************************************
# Sequel Pro SQL dump
# Version 4004
#
# http://www.sequelpro.com/
# http://code.google.com/p/sequel-pro/
#
# Host: padmatcher.net (MySQL 5.5.25)
# Database: newsmaps
# Generation Time: 2013-10-17 20:52:47 +0000
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table queries
# ------------------------------------------------------------

DROP TABLE IF EXISTS `queries`;

CREATE TABLE `queries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(45) NOT NULL,
  `created` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `last_query` timestamp NULL DEFAULT NULL,
  `active` tinyint(4) DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `title_UNIQUE` (`title`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

LOCK TABLES `queries` WRITE;
/*!40000 ALTER TABLE `queries` DISABLE KEYS */;

INSERT INTO `queries` (`id`, `title`, `created`, `last_query`, `active`)
VALUES
	(1,'test','2013-10-08 17:18:50',NULL,1),
	(3,'Testing',NULL,'2013-10-09 09:29:34',1),
	(5,'Testingtesting',NULL,'2013-10-09 09:29:45',1),
	(6,'Testingtestingasd',NULL,'2013-10-09 09:29:48',1),
	(7,'Fake',NULL,'2013-10-09 12:16:20',1),
	(8,'superfake',NULL,'2013-10-09 12:16:32',1);

/*!40000 ALTER TABLE `queries` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table queries_has_stories
# ------------------------------------------------------------

DROP TABLE IF EXISTS `queries_has_stories`;

CREATE TABLE `queries_has_stories` (
  `queries_id` int(11) NOT NULL,
  `stories_id` int(11) NOT NULL,
  `active` tinyint(4) DEFAULT '1',
  PRIMARY KEY (`queries_id`,`stories_id`),
  KEY `fk_queries_has_stories_stories1_idx` (`stories_id`),
  KEY `fk_queries_has_stories_queries1_idx` (`queries_id`),
  CONSTRAINT `fk_queries_has_stories_queries1` FOREIGN KEY (`queries_id`) REFERENCES `queries` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_queries_has_stories_stories1` FOREIGN KEY (`stories_id`) REFERENCES `stories` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

LOCK TABLES `queries_has_stories` WRITE;
/*!40000 ALTER TABLE `queries_has_stories` DISABLE KEYS */;

INSERT INTO `queries_has_stories` (`queries_id`, `stories_id`, `active`)
VALUES
	(1,1,1),
	(3,2,1),
	(3,3,1),
	(3,4,1);

/*!40000 ALTER TABLE `queries_has_stories` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table stories
# ------------------------------------------------------------

DROP TABLE IF EXISTS `stories`;

CREATE TABLE `stories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(45) NOT NULL,
  `publication` varchar(45) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `author` varchar(45) DEFAULT NULL,
  `url` varchar(255) NOT NULL,
  `created` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `active` tinyint(4) DEFAULT '1',
  `lat` float DEFAULT NULL,
  `lng` float DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `url_UNIQUE` (`url`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

LOCK TABLES `stories` WRITE;
/*!40000 ALTER TABLE `stories` DISABLE KEYS */;

INSERT INTO `stories` (`id`, `title`, `publication`, `date`, `author`, `url`, `created`, `active`, `lat`, `lng`)
VALUES
	(1,'test story','nytimes','0000-00-00 00:00:00','bob','nytimes.com','2013-10-08 17:32:33',1,NULL,NULL),
	(2,'another test','nytimes',NULL,'aaron','nytimes.com/foo','2013-10-09 10:09:16',1,NULL,NULL),
	(3,'testing testing','thepost',NULL,'jim','thepost.com','2013-10-09 10:09:31',1,NULL,NULL),
	(4,'Foo','Fake',NULL,'Jake','whatever',NULL,1,1234,4321);

/*!40000 ALTER TABLE `stories` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table users
# ------------------------------------------------------------

DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(45) NOT NULL,
  `email` varchar(45) NOT NULL,
  `first_name` varchar(45) NOT NULL,
  `last_name` varchar(45) NOT NULL,
  `active` tinyint(4) DEFAULT '1',
  `created` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `last_login` datetime DEFAULT NULL,
  `password` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username_UNIQUE` (`username`),
  UNIQUE KEY `email_UNIQUE` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;

INSERT INTO `users` (`id`, `username`, `email`, `first_name`, `last_name`, `active`, `created`, `last_login`, `password`)
VALUES
	(1,'awishn02','aaronwishnick@gmail.com','Aaron','Wishnick',1,'2013-10-07 15:49:37',NULL,'password'),
	(4,'aaronwishnick','aaron_b.wishnick@tufts.edu','Aaron','Wishnick',1,'2013-10-08 18:43:37',NULL,NULL),
	(28,'fake','email','fake','person',1,'2013-10-09 10:42:27','2013-10-09 10:42:25','1234'),
	(41,'notfake','notemail','fake','person',1,'2013-10-09 11:01:10','2013-10-09 11:01:10','1234'),
	(47,'notfaker','notemairl','fake','person',1,'2013-10-09 11:26:37','2013-10-09 11:26:37','1234');

/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table users_has_queries
# ------------------------------------------------------------

DROP TABLE IF EXISTS `users_has_queries`;

CREATE TABLE `users_has_queries` (
  `users_id` int(11) NOT NULL,
  `queries_id` int(11) NOT NULL,
  `active` tinyint(4) DEFAULT '1',
  PRIMARY KEY (`users_id`,`queries_id`),
  KEY `fk_users_has_queries_queries1_idx` (`queries_id`),
  KEY `fk_users_has_queries_users_idx` (`users_id`),
  CONSTRAINT `fk_users_has_queries_queries1` FOREIGN KEY (`queries_id`) REFERENCES `queries` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_users_has_queries_users` FOREIGN KEY (`users_id`) REFERENCES `users` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

LOCK TABLES `users_has_queries` WRITE;
/*!40000 ALTER TABLE `users_has_queries` DISABLE KEYS */;

INSERT INTO `users_has_queries` (`users_id`, `queries_id`, `active`)
VALUES
	(4,1,1);

/*!40000 ALTER TABLE `users_has_queries` ENABLE KEYS */;
UNLOCK TABLES;



/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
