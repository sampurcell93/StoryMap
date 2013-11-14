-- MySQL dump 10.13  Distrib 5.6.13, for osx10.7 (x86_64)
--
-- Host: localhost    Database: newsmaps
-- ------------------------------------------------------
-- Server version   5.6.13
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO,POSTGRESQL' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table "queries"
--

DROP TABLE IF EXISTS "queries";
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE "queries" (
  "id" integer NOT NULL,
  "title" varchar(45) NOT NULL,
  "created" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  "last_query" timestamp NULL DEFAULT NULL,
  "active" integer DEFAULT '1',
  PRIMARY KEY ("id"),
  UNIQUE KEY "title_UNIQUE" ("title")
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table "queries_has_stories"
--

DROP TABLE IF EXISTS "queries_has_stories";
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE "queries_has_stories" (
  "queries_id" integer NOT NULL,
  "stories_id" integer NOT NULL,
  "active" integer DEFAULT '1',
  PRIMARY KEY ("queries_id","stories_id"),
  KEY "fk_queries_has_stories_stories1_idx" ("stories_id"),
  KEY "fk_queries_has_stories_queries1_idx" ("queries_id"),
  CONSTRAINT "fk_queries_has_stories_queries1" FOREIGN KEY ("queries_id") REFERENCES "queries" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT "fk_queries_has_stories_stories1" FOREIGN KEY ("stories_id") REFERENCES "stories" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table "stories"
--

DROP TABLE IF EXISTS "stories";
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE "stories" (
  "id" integer NOT NULL,
  "title" varchar(300) DEFAULT NULL,
  "publisher" varchar(300) DEFAULT NULL,
  "date" datetime DEFAULT NULL,
  "url" varchar(255) NOT NULL,
  "created" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  "active" integer DEFAULT '1',
  "lat" float DEFAULT NULL,
  "lng" float DEFAULT NULL,
  "content" text,
  "aggregator" varchar(255) DEFAULT NULL,
  "location" varchar(255) DEFAULT NULL,
  PRIMARY KEY ("id"),
  UNIQUE KEY "url_UNIQUE" ("url")
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table "users"
--

DROP TABLE IF EXISTS "users";
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE "users" (
  "id" integer NOT NULL,
  "username" varchar(45) NOT NULL,
  "email" varchar(45) NOT NULL,
  "first_name" varchar(45) NOT NULL,
  "last_name" varchar(45) NOT NULL,
  "active" integer DEFAULT '1',
  "created" timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  "last_login" datetime DEFAULT NULL,
  "password" varchar(255) DEFAULT NULL,
  PRIMARY KEY ("id"),
  UNIQUE KEY "username_UNIQUE" ("username"),
  UNIQUE KEY "email_UNIQUE" ("email")
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table "users_has_queries"
--

DROP TABLE IF EXISTS "users_has_queries";
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE "users_has_queries" (
  "users_id" integer NOT NULL,
  "queries_id" integer NOT NULL,
  "active" integer DEFAULT '1',
  PRIMARY KEY ("users_id","queries_id"),
  KEY "fk_users_has_queries_queries1_idx" ("queries_id"),
  KEY "fk_users_has_queries_users_idx" ("users_id"),
  CONSTRAINT "fk_users_has_queries_queries1" FOREIGN KEY ("queries_id") REFERENCES "queries" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT "fk_users_has_queries_users" FOREIGN KEY ("users_id") REFERENCES "users" ("id") ON DELETE NO ACTION ON UPDATE NO ACTION
);
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-11-13 16:28:17

