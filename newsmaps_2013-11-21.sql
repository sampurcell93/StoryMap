# ************************************************************
# Sequel Pro SQL dump
# Version 4004
#
# http://www.sequelpro.com/
# http://code.google.com/p/sequel-pro/
#
# Host: padmatcher.net (MySQL 5.5.25)
# Database: newsmaps
# Generation Time: 2013-11-21 17:14:54 +0000
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



# Dump of table stories
# ------------------------------------------------------------

DROP TABLE IF EXISTS `stories`;

CREATE TABLE `stories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(300) DEFAULT NULL,
  `publisher` varchar(300) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `url` varchar(255) NOT NULL,
  `created` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `active` tinyint(4) DEFAULT '1',
  `lat` float DEFAULT NULL,
  `lng` float DEFAULT NULL,
  `content` text,
  `aggregator` varchar(255) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `url_UNIQUE` (`url`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



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
  `password` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username_UNIQUE` (`username`),
  UNIQUE KEY `email_UNIQUE` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



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



# Dump of table users_has_stories
# ------------------------------------------------------------

DROP TABLE IF EXISTS `users_has_stories`;

CREATE TABLE `users_has_stories` (
  `users_id` int(11) NOT NULL,
  `stories_id` int(11) NOT NULL,
  `active` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`users_id`,`stories_id`),
  KEY `fk_users_has_stories_stories1_idx` (`stories_id`),
  KEY `fk_users_has_stories_users1_idx` (`users_id`),
  CONSTRAINT `fk_users_has_stories_users1` FOREIGN KEY (`users_id`) REFERENCES `users` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `fk_users_has_stories_stories1` FOREIGN KEY (`stories_id`) REFERENCES `stories` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;




/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
