DELIMITER $$
DROP PROCEDURE IF EXISTS `sp_report_balance`$$
CREATE PROCEDURE `sp_report_balance`(
IN vSTART VARCHAR(255),
IN vEND VARCHAR(255),
IN vUSER_ID BIGINT(50),
IN vSEARCH VARCHAR(255)
)
BEGIN
    DECLARE mDATE_START_APP VARCHAR(255);
    DROP TEMPORARY TABLE IF EXISTS journals_temp;
    CREATE TEMPORARY TABLE journals_temp (
        `temp_id` BIGINT NOT NULL AUTO_INCREMENT,
        `balance_id` BIGINT(50),
        `balance_date` VARCHAR(255),
        `balance_number` VARCHAR(255),
        `balance_note` VARCHAR(255),
        `balance_session` VARCHAR(255),
        `balance_type` BIGINT(50),
        `balance_type_name` VARCHAR(255),         
        -- `journal_number` VARCHAR(255),
        -- `trans_number` VARCHAR(255),
        -- `account_group` INT(5),
        -- `account_code` VARCHAR(255),
        -- `account_name` VARCHAR(255),
        `debit` DOUBLE(18,2) DEFAULT 0,
        `credit` DOUBLE(18,2) DEFAULT 0,
        `balance` DOUBLE(18,2) DEFAULT 0,
        `user_id` BIGINT(50),		
        `balance_position` INT(5),		
        `status` INT(5) DEFAULT 0,
        `message` VARCHAR(255),
        `total_data` INT(50),
        `search` VARCHAR(255),
        PRIMARY KEY (`temp_id`),
        INDEX `BALANCE_ID`(`balance_id`) USING BTREE
    ) ENGINE=MEMORY;

    SELECT MIN(balance_date) INTO mDATE_START_APP FROM balances WHERE balance_user_id=vUSER_ID;
    SET @start_date = mDATE_START_APP - INTERVAL 1 DAY;
    SET @end_date = CONCAT(vSTART,' 23:59:59') - INTERVAL 1 DAY;
    SET @running_date_start = CONCAT(vSTART,' 00:00:00');
    SET @running_date_end = CONCAT(vEND,' 23:59:59');

    SET @start_date_journal = @start_date;
    SET @end_date_journal = @end_date;

    SET @start_date = DATE_FORMAT(@start_date, "%Y%m%d%H%i%s");
    SET @end_date = DATE_FORMAT(@end_date, "%Y%m%d%H%i%s");

    BLOCK_A:BEGIN /* Get Start Balance */
        -- DECLARE mACCOUNT_ID INT(50);
        -- DECLARE mACCOUNT_CODE VARCHAR(255);
        -- DECLARE mACCOUNT_NAME VARCHAR(255);
        -- DECLARE mACCOUNT_GROUP INT(5);
        DECLARE mDEBIT DOUBLE(18,2) DEFAULT 0;
        DECLARE mCREDIT DOUBLE(18,2) DEFAULT 0;
        DECLARE mBALANCE DOUBLE(18,2) DEFAULT 0;

        DECLARE mFINISHED INTEGER;
        DECLARE mACTION_CURSOR CURSOR FOR
            SELECT IFNULL(SUM(balance_debit)-SUM(balance_credit),0) AS start_balance
            FROM balances
            WHERE `balance_user_id` = vUSER_ID
            AND `balance_date` > @start_date
            AND `balance_date` < @end_date
            AND `balance_flag`=1;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET mFINISHED = 1;
        OPEN mACTION_CURSOR;

        LOOP_1: LOOP
            FETCH mACTION_CURSOR INTO mBALANCE;
            IF mFINISHED = 1 THEN LEAVE LOOP_1; END IF;
            -- SET @type_name = 'Saldo Awal';
            INSERT INTO journals_temp(`balance_id`,`balance_type`,`balance_type_name`,`balance_date`,`balance`,`user_id`,`balance_position`)
            VALUES(0,0,'Saldo Awal', @end_date_journal,mBALANCE,vUSER_ID,1);
        END LOOP LOOP_1;
    END BLOCK_A;

    BLOCK_B:BEGIN /* Get Running Balance */
        DECLARE mBALANCE_ID BIGINT(50);
        DECLARE mBALANCE_NUMBER VARCHAR(255);
        DECLARE mBALANCE_DATE DATETIME;
        DECLARE mBALANCE_NOTE TEXT;

        DECLARE mBALANCE_TYPE INT(5);
        DECLARE mBALANCE_TYPE_NAME VARCHAR(255);

        DECLARE mPOSITION INT(5);
        DECLARE mSESSION VARCHAR(255);		
        DECLARE mDEBIT DOUBLE(18,2) DEFAULT 0;
        DECLARE mCREDIT DOUBLE(18,2) DEFAULT 0;
        DECLARE mBALANCE DOUBLE(18,2) DEFAULT 0;

        DECLARE mTOTAL_DATA INT(50) DEFAULT 0;
        DECLARE mFINISHED INTEGER;
        DECLARE mACTION_CURSOR CURSOR FOR
            SELECT
            `balances`.`balance_id`,
            `balances`.`balance_date`,			
            `balances`.`balance_number`,
            `balances`.`balance_note`,
            `balances`.`balance_type`,
            `balances`.`balance_type_name`,			
            `balances`.`balance_position`,
            `balances`.`balance_session`,
            IFNULL(balances.balance_debit,0) AS debit,
            IFNULL(balances.balance_credit,0) AS credit,
            (
                SELECT @saldo_awal := @saldo_awal + balances.balance_debit - balances.balance_credit
            ) AS balance
            FROM (
                SELECT @saldo_awal := (
                    SELECT IFNULL(balance,0) FROM journals_temp WHERE user_id=vUSER_ID AND balance_type_name='Saldo Awal'
                )
            ) AS start_balance
            CROSS JOIN (
                SELECT
                    balances.balance_id, balances.balance_session, balances.balance_number, balances.balance_type, balances.balance_type_name, balances.balance_flag, balances.balance_date, balances.balance_note,
                    balances.balance_debit, balances.balance_credit,
                    balances.balance_user_id, balances.balance_position
                FROM balances LEFT JOIN `users` ON `balances`.`balance_user_id` = `users`.`user_id`
            ) AS `balances`
            WHERE `balances`.`balance_date` > @running_date_start
            AND `balances`.`balance_date` < @running_date_end
            AND `balances`.`balance_flag`=1
            AND `balances`.`balance_user_id`= vUSER_ID
            ORDER BY `balances`.`balance_date` ASC;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET mFINISHED = 1;

        OPEN mACTION_CURSOR;
        LOOP_1: LOOP
            -- FETCH mACTION_CURSOR INTO mJOURNAL_ITEM_ID, mJOURNAL_DATE, mJOURNAL_NOTE, mACCOUNT_ID, mACCOUNT_CODE, mACCOUNT_NAME, mACCOUNT_GROUP, mTYPE_ID, mJOURNAL_ID, mTRANS_ID, mDEBIT, mCREDIT, mBALANCE;
            FETCH mACTION_CURSOR INTO mBALANCE_ID, mBALANCE_DATE, mBALANCE_NUMBER, mBALANCE_NOTE, mBALANCE_TYPE, mBALANCE_TYPE_NAME, mPOSITION, mSESSION, mDEBIT, mCREDIT, mBALANCE;			
            IF mFINISHED = 1 THEN LEAVE LOOP_1; END IF;
            -- INSERT INTO journals_temp(`journal_item_id`,`journal_item_date`,`journal_item_note`,`type_name`,`type_id`,`journal_id`,`trans_id`,`account_id`,`account_group`,`account_code`,`account_name`,`debit`,`credit`,`balance`)
            -- VALUES(mJOURNAL_ITEM_ID,mJOURNAL_DATE,mJOURNAL_NOTE,mTYPE_NAME,mTYPE_ID,mJOURNAL_ID,mTRANS_ID,mACCOUNT_ID,mACCOUNT_GROUP,mACCOUNT_CODE,mACCOUNT_NAME,mDEBIT,mCREDIT,mBALANCE);
            INSERT INTO journals_temp(`balance_id`,`balance_date`,`balance_number`,`balance_note`,`balance_type`,`balance_type_name`,`balance_position`,`balance_session`,`debit`,`credit`,`balance`,`user_id`)
            VALUES(mBALANCE_ID,mBALANCE_DATE,mBALANCE_NUMBER,mBALANCE_NOTE,mBALANCE_TYPE, mBALANCE_TYPE_NAME, mPOSITION, mSESSION, mDEBIT,mCREDIT,mBALANCE,vUSER_ID);			
        END LOOP LOOP_1;
    END BLOCK_B;

    -- //Sini

    BLOCK_C:BEGIN
        DECLARE mTOTAL_DATA BIGINT(255);
        /* Count All Data*/
        SELECT IFNULL(COUNT(*),0) INTO mTOTAL_DATA FROM journals_temp WHERE user_id=vUSER_ID;
        UPDATE journals_temp
        SET total_data=mTOTAL_DATA,
        `status`=CASE WHEN mTOTAL_DATA > 0 THEN 1 ELSE 0 END,
        `message`=CASE WHEN mTOTAL_DATA > 0 THEN 'Data found' ELSE 'Data not found' END
        WHERE user_id=vUSER_ID;
    END BLOCK_C;
    
    SELECT journals_temp.*, DATE_FORMAT(balance_date, "%d/%m/%Y, %H:%i") AS balance_date_format, fn_time_ago(balance_date) AS balance_date_time_ago 
    FROM journals_temp;
END$$
DELIMITER ;