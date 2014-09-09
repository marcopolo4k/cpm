CREATE TABLE `blog` (
    `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
    `title` text,
    `content` text,
    `deleted` tinyint(1) unsigned NOT NULL DEFAULT '0',
    PRIMARY KEY (`id`),
    KEY `ix_deleted` (`deleted`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='Blog posts';

CREATE TABLE `audit` (
    `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
    `blog_id` mediumint(8) unsigned NOT NULL,
    `changetype` enum('NEW','EDIT','DELETE') NOT NULL,
    `changetime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `ix_blog_id` (`blog_id`),
    KEY `ix_changetype` (`changetype`),
    KEY `ix_changetime` (`changetime`),
    CONSTRAINT `FK_audit_blog_id` FOREIGN KEY (`blog_id`) REFERENCES `blog` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;


CREATE TRIGGER `test_trigger1` AFTER DELETE
    ON `user1_db1`.`blog`
    FOR EACH ROW BEGIN
    END;


CREATE TABLE `blog_archive` (
    `id` mediumint(8) unsigned NOT NULL,
    `title` text,
    `content` text,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Blog posts archive';

CREATE TABLE `audit_archive` (
    `id` mediumint(8) unsigned NOT NULL,
    `blog_id` mediumint(8) unsigned NOT NULL,
    `changetype` enum('NEW','EDIT','DELETE') NOT NULL,
    `changetime` timestamp NOT NULL,
    PRIMARY KEY (`id`),
    KEY `ix_blog_id` (`blog_id`),
    KEY `ix_changetype` (`changetype`),
    KEY `ix_changetime` (`changetime`),
    CONSTRAINT `FK_audit_blog_archive_id` FOREIGN KEY (`blog_id`) REFERENCES `blog_archive` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


SET GLOBAL event_scheduler = ON;


CREATE EVENT `test_event1`
ON SCHEDULE AT TIMESTAMP(CURDATE() +INTERVAL 1 DAY, '11:00:00')
DO BEGIN
-- event body
END;


delimiter //
CREATE DEFINER=`user1`@`localhost` PROCEDURE `test_procedure1`()
BEGIN
 SELECT * FROM blog;
END//

DELIMITER //
CREATE FUNCTION test_function1()
  RETURNS TEXT
  LANGUAGE SQL
BEGIN
  RETURN 'Hello World';
END;
//
DELIMITER ;


CREATE VIEW test_view1 AS
SELECT id, title, content
FROM blog;
