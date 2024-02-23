ALTER TABLE users ADD COLUMN user_total_link BIGINT(255);

DELIMITER $$
DROP TRIGGER IF EXISTS `tr_link_after_insert`$$
CREATE TRIGGER `tr_link_after_insert` AFTER INSERT ON `links` FOR EACH ROW BEGIN
DECLARE mCOUNT INT(50);
    IF NEW.link_user_session IS NOT NULL THEN
        SELECT COUNT(*) INTO mCOUNT FROM links WHERE link_user_session=NEW.link_user_session;
        UPDATE users SET user_total_link=mCOUNT WHERE user_session=NEW.link_user_session;	
    END IF;
END$$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS `tr_link_before_insert`$$
CREATE TRIGGER `tr_link_before_insert` BEFORE INSERT ON `links` FOR EACH ROW BEGIN
    SET NEW.link_session=fn_create_session();
    SET NEW.link_date_created=NOW();
    IF NEW.link_flag IS NULL THEN SET NEW.link_flag=0; END IF;
    IF NEW.link_url IS NULL THEN SET NEW.link_url = fn_create_url(); END IF;
END$$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS `tr_link_hit_after_delete`$$
CREATE TRIGGER `tr_link_hit_after_delete` AFTER DELETE ON `links_hits` FOR EACH ROW BEGIN
    DECLARE mCOUNT INT(50);
    SELECT COUNT(*) INTO mCOUNT FROM links_hits WHERE hit_link_session=OLD.hit_link_session;
    UPDATE links SET link_visit=mCOUNT WHERE link_session=OLD.hit_link_session;
END$$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS `tr_link_hit_after_insert`$$
CREATE TRIGGER `tr_link_hit_after_insert` AFTER INSERT ON `links_hits` FOR EACH ROW BEGIN
    DECLARE mCOUNT INT(50);
    IF NEW.hit_link_session IS NOT NULL THEN
        SELECT COUNT(*) INTO mCOUNT FROM links_hits WHERE hit_link_session=NEW.hit_link_session;
        UPDATE links SET link_visit=mCOUNT WHERE link_session=NEW.hit_link_session;
    END IF;
END$$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS `tr_link_hit_before_insert`$$
CREATE TRIGGER `tr_link_hit_before_insert` BEFORE INSERT ON `links_hits` FOR EACH ROW BEGIN
    DECLARE mCOUNT INT(50);
    SET NEW.hit_session = fn_create_session();
    IF NEW.hit_date_created IS NULL THEN 
        SET NEW.hit_date_created = NOW();
    END IF;
END$$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS `tr_user_before_insert`$$
CREATE TRIGGER `tr_user_before_insert` BEFORE INSERT ON `users` FOR EACH ROW BEGIN
    SET NEW.user_session=fn_create_session();
    SET NEW.user_date_created=NOW();
END$$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS `tr_icon_before_insert`$$ 
CREATE TRIGGER `tr_icon_before_insert` BEFORE INSERT ON `icons`
FOR EACH ROW 
BEGIN
   SET NEW.icon_session = fn_create_session();
   SET NEW.icon_date_created = NOW();
END $$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS `tr_profile_before_insert`$$ 
CREATE TRIGGER `tr_profile_before_insert` BEFORE INSERT ON `profiles`
FOR EACH ROW 
BEGIN
   SET NEW.profile_session = fn_create_session();
   SET NEW.profile_date_created = NOW();
END $$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS `tr_profile_item_before_insert`$$ 
CREATE TRIGGER `tr_profile_item_before_insert` BEFORE INSERT ON `profiles_items`
FOR EACH ROW 
BEGIN
   SET NEW.item_session = fn_create_session();
   SET NEW.item_date_created = NOW();
END $$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS `tr_user_asset_before_insert`$$ 
CREATE TRIGGER `tr_user_asset_before_insert` BEFORE INSERT ON `users_assets`
FOR EACH ROW 
BEGIN
   SET NEW.asset_session = fn_create_session();
   SET NEW.asset_date_created = NOW();
END $$
DELIMITER ;