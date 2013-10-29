-- MySQL dump 10.13  Distrib 5.6.13, for osx10.7 (x86_64)
--
-- Host: localhost    Database: newsmaps
-- ------------------------------------------------------
-- Server version	5.6.13

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `queries`
--

DROP TABLE IF EXISTS `queries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `queries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(45) NOT NULL,
  `created` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `last_query` timestamp NULL DEFAULT NULL,
  `active` tinyint(4) DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `title_UNIQUE` (`title`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `queries`
--

LOCK TABLES `queries` WRITE;
/*!40000 ALTER TABLE `queries` DISABLE KEYS */;
INSERT INTO `queries` VALUES (1,'test','2013-10-08 21:18:50',NULL,1),(3,'Testing',NULL,'2013-10-09 13:29:34',1),(5,'Testingtesting',NULL,'2013-10-09 13:29:45',1),(6,'Testingtestingasd',NULL,'2013-10-09 13:29:48',1),(7,'Fake',NULL,'2013-10-09 16:16:20',1),(8,'superfake',NULL,'2013-10-09 16:16:32',1);
/*!40000 ALTER TABLE `queries` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `queries_has_stories`
--

DROP TABLE IF EXISTS `queries_has_stories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `queries_has_stories`
--

LOCK TABLES `queries_has_stories` WRITE;
/*!40000 ALTER TABLE `queries_has_stories` DISABLE KEYS */;
INSERT INTO `queries_has_stories` VALUES (1,1,1),(3,2,1),(3,3,1),(3,4,1);
/*!40000 ALTER TABLE `queries_has_stories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stories`
--

DROP TABLE IF EXISTS `stories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stories`
--

LOCK TABLES `stories` WRITE;
/*!40000 ALTER TABLE `stories` DISABLE KEYS */;
INSERT INTO `stories` VALUES (1,'test story','nytimes','0000-00-00 00:00:00','bob','nytimes.com','2013-10-08 21:32:33',1,NULL,NULL),(2,'another test','nytimes',NULL,'aaron','nytimes.com/foo','2013-10-09 14:09:16',1,NULL,NULL),(3,'testing testing','thepost',NULL,'jim','thepost.com','2013-10-09 14:09:31',1,NULL,NULL),(4,'Foo','Fake',NULL,'Jake','whatever',NULL,1,1234,4321);
/*!40000 ALTER TABLE `stories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
) ENGINE=InnoDB AUTO_INCREMENT=62 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'awishn02','aaronwishnick@gmail.com','Aaron','Wishnick',1,'2013-10-07 19:49:37',NULL,'password'),(4,'aaronwishnick','aaron_b.wishnick@tufts.edu','Aaron','Wishnick',1,'2013-10-08 22:43:37',NULL,NULL),(28,'fake','email','fake','person',1,'2013-10-09 14:42:27','2013-10-09 10:42:25','1234'),(41,'notfake','notemail','fake','person',1,'2013-10-09 15:01:10','2013-10-09 11:01:10','1234'),(47,'notfaker','notemairl','fake','person',1,'2013-10-09 15:26:37','2013-10-09 11:26:37','1234'),(48,'spurce02','samuel.purcell@tufts.edu','Sam','Purcell',1,'2013-10-29 21:33:48','2013-10-29 17:33:48','test'),(55,'Hash','hash@hash','Hash','Hasherson',1,'2013-10-29 21:48:25','2013-10-29 17:48:25','$2a$12$TlRiBltpTlBrMnf.TNvuyej'),(56,'Final','final','sam ','test',1,'2013-10-29 22:05:00','2013-10-29 18:56:00','$2a$12$lez8Z8vhU/0E/Foum64zde.b7vzE6sUZk5zE44ncNokfnGK.uLrrG');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users_has_queries`
--

DROP TABLE IF EXISTS `users_has_queries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users_has_queries`
--

LOCK TABLES `users_has_queries` WRITE;
/*!40000 ALTER TABLE `users_has_queries` DISABLE KEYS */;
INSERT INTO `users_has_queries` VALUES (4,1,1);
/*!40000 ALTER TABLE `users_has_queries` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-10-29 19:07:38
