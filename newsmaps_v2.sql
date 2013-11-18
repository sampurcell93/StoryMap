SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

CREATE SCHEMA IF NOT EXISTS `newsmaps` DEFAULT CHARACTER SET latin1 ;
USE `newsmaps` ;

-- -----------------------------------------------------
-- Table `newsmaps`.`queries`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `newsmaps`.`queries` (
  `id` INT(11) NOT NULL,
  `title` VARCHAR(45) NOT NULL,
  `created` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `last_query` TIMESTAMP NULL DEFAULT NULL,
  `active` TINYINT(4) NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE INDEX `title_UNIQUE` (`title` ASC))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `newsmaps`.`stories`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `newsmaps`.`stories` (
  `id` INT(11) NOT NULL,
  `title` VARCHAR(300) NULL DEFAULT NULL,
  `publisher` VARCHAR(300) NULL DEFAULT NULL,
  `date` DATETIME NULL DEFAULT NULL,
  `url` VARCHAR(255) NOT NULL,
  `created` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `active` TINYINT(4) NULL DEFAULT '1',
  `lat` FLOAT NULL DEFAULT NULL,
  `lng` FLOAT NULL DEFAULT NULL,
  `content` TEXT NULL DEFAULT NULL,
  `aggregator` VARCHAR(255) NULL DEFAULT NULL,
  `location` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `url_UNIQUE` (`url` ASC))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `newsmaps`.`queries_has_stories`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `newsmaps`.`queries_has_stories` (
  `queries_id` INT(11) NOT NULL,
  `stories_id` INT(11) NOT NULL,
  `active` TINYINT(4) NULL DEFAULT '1',
  PRIMARY KEY (`queries_id`, `stories_id`),
  INDEX `fk_queries_has_stories_stories1_idx` (`stories_id` ASC),
  INDEX `fk_queries_has_stories_queries1_idx` (`queries_id` ASC),
  CONSTRAINT `fk_queries_has_stories_queries1`
    FOREIGN KEY (`queries_id`)
    REFERENCES `newsmaps`.`queries` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_queries_has_stories_stories1`
    FOREIGN KEY (`stories_id`)
    REFERENCES `newsmaps`.`stories` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `newsmaps`.`users`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `newsmaps`.`users` (
  `id` INT(11) NOT NULL,
  `username` VARCHAR(45) NOT NULL,
  `email` VARCHAR(45) NOT NULL,
  `first_name` VARCHAR(45) NOT NULL,
  `last_name` VARCHAR(45) NOT NULL,
  `active` TINYINT(4) NULL DEFAULT '1',
  `created` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `last_login` DATETIME NULL DEFAULT NULL,
  `password` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `username_UNIQUE` (`username` ASC),
  UNIQUE INDEX `email_UNIQUE` (`email` ASC))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `newsmaps`.`users_has_queries`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `newsmaps`.`users_has_queries` (
  `users_id` INT(11) NOT NULL,
  `queries_id` INT(11) NOT NULL,
  `active` TINYINT(4) NULL DEFAULT '1',
  PRIMARY KEY (`users_id`, `queries_id`),
  INDEX `fk_users_has_queries_queries1_idx` (`queries_id` ASC),
  INDEX `fk_users_has_queries_users_idx` (`users_id` ASC),
  CONSTRAINT `fk_users_has_queries_queries1`
    FOREIGN KEY (`queries_id`)
    REFERENCES `newsmaps`.`queries` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_users_has_queries_users`
    FOREIGN KEY (`users_id`)
    REFERENCES `newsmaps`.`users` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `newsmaps`.`users_has_stories`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `newsmaps`.`users_has_stories` (
  `users_id` INT(11) NOT NULL,
  `stories_id` INT(11) NOT NULL,
  `active` TINYINT(4) NULL,
  PRIMARY KEY (`users_id`, `stories_id`),
  INDEX `fk_users_has_stories_stories1_idx` (`stories_id` ASC),
  INDEX `fk_users_has_stories_users1_idx` (`users_id` ASC),
  CONSTRAINT `fk_users_has_stories_users1`
    FOREIGN KEY (`users_id`)
    REFERENCES `newsmaps`.`users` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_users_has_stories_stories1`
    FOREIGN KEY (`stories_id`)
    REFERENCES `newsmaps`.`stories` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
