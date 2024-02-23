DELIMITER $$
DROP FUNCTION IF EXISTS `fn_create_session`$$
CREATE FUNCTION `fn_create_session`() RETURNS VARCHAR(128) CHARSET utf8
    BEGIN
        SET @chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
        SET @charLen = LENGTH(@chars);
        SET @random = '';
        WHILE LENGTH(@random) < 20
        DO
        SET @random = CONCAT(@random, SUBSTRING(@chars,CEILING(RAND() * @charLen),1));
        END WHILE;
        RETURN @random ;
    END$$
DELIMITER ;