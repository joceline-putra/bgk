DELIMITER $$
DROP TRIGGER IF EXISTS `tr_balance_after_insert`$$
CREATE TRIGGER `tr_balance_after_insert` AFTER INSERT ON `balances` 
    FOR EACH ROW BEGIN 
  IF NEW.balance_flag = 1 THEN
	UPDATE `users` SET user_balance=(
      SELECT IFNULL(SUM(balance_debit-balance_credit),0) FROM balances 
      WHERE balance_user_id=NEW.balance_user_id AND balance_flag=1)
    WHERE user_id=NEW.balance_user_id;     
  END IF;
END$$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS `tr_balance_after_update`$$
CREATE TRIGGER `tr_balance_after_update` AFTER UPDATE ON `balances` 
    FOR EACH ROW BEGIN 
	UPDATE `users` SET user_balance=(
      SELECT IFNULL(SUM(balance_debit-balance_credit),0) FROM balances 
      WHERE balance_user_id=NEW.balance_user_id AND balance_flag=1)
    WHERE user_id=NEW.balance_user_id;
END$$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS `tr_balance_before_insert`$$
CREATE TRIGGER `tr_balance_before_insert` BEFORE INSERT ON `balances` FOR EACH ROW BEGIN 
  DECLARE mTYPE INT(5);
  DECLARE mTYPE_NAME VARCHAR(255);
  DECLARE mUSER_ID BIGINT(255);
  DECLARE mBANK_ID BIGINT(255);
  
  SET mTYPE = NEW.balance_type;
  
  IF mTYPE = 1 THEN 
    SET mTYPE_NAME='Deposit';
  ELSEIF mTYPE = 2 THEN 
    SET mTYPE_NAME='Withdraw';
  ELSEIF mTYPE = 3 THEN 
    SET mTYPE_NAME='Biaya Layanan';
  ELSE 
    SET mTYPE_NAME='Unknown';
  END IF;
  
  IF NEW.balance_debit > 0 THEN 
    SET NEW.balance_position=1; 
  END IF;
  
  IF NEW.balance_credit > 0 THEN 
    SET NEW.balance_position=2; 
  END IF;

  IF LENGTH(NEW.balance_user_session) > 0 THEN 
    SELECT user_id INTO mUSER_ID FROM users WHERE user_session=NEW.balance_user_session;
    SET NEW.balance_user_id=mUSER_ID;
  END IF;

  IF LENGTH(NEW.balance_bank_session) > 0 THEN 
    SELECT bank_id INTO mBANK_ID FROM banks WHERE bank_session=NEW.balance_bank_session;
    SET NEW.balance_bank_id=mBANK_ID;
  END IF;

  IF NEW.balance_flag = 1 THEN
    UPDATE `users` JOIN (
      SELECT balance_user_id, IFNULL(SUM(balance_debit-balance_credit),0) AS saldo FROM balances WHERE balance_user_id=NEW.balance_user_id
    ) AS j ON user_id=j.balance_user_id
    SET user_balance=j.saldo
    WHERE user_id=NEW.balance_user_id;
  END IF;
  
  SET NEW.balance_type_name = mTYPE_NAME;
END$$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS `tr_mutation_before_insert`$$
CREATE TRIGGER `tr_mutation_before_insert` BEFORE INSERT ON `mutations` 
    FOR EACH ROW BEGIN 
	DECLARE mUSER_SESSION VARCHAR(255);
	DECLARE mBANK_SESSION VARCHAR(255);
	DECLARE mBANK_ID INT(255);
	DECLARE mPHONE VARCHAR(255);
	DECLARE mEMAIL VARCHAR(255);

	SET @mBANK_ACCOUNT_NUMBER = NEW.mutation_api_bank_account_number;	
	
	SELECT bank_id, bank_session, bank_phone_notification, bank_email_notification, bank_user_session 
	INTO mBANK_ID, mBANK_SESSION, mPHONE, mEMAIL, mUSER_SESSION 
	FROM banks 
	WHERE bank_account_number=@mBANK_ACCOUNT_NUMBER;
    /*
	SET @mBANK_API_ID = NEW.mutation_api_bank_id;	
	SELECT bank_id, bank_session, bank_phone_notification, bank_email_notification, bank_user_session 
	INTO mBANK_ID, mBANK_SESSION, mPHONE, mEMAIL, mUSER_SESSION 
	FROM banks 
	WHERE bank_api_id=@mBANK_API_ID; 
	*/
	
	IF NEW.mutation_debit > 0 THEN 
		SET NEW.mutation_total = NEW.mutation_debit;
		SET NEW.mutation_type = 'D';
	ELSE
		IF NEW.mutation_credit > 0 THEN 
			SET NEW.mutation_total = NEW.mutation_credit;
			SET NEW.mutation_type = 'K';
		END IF;
	END IF;

	SET NEW.mutation_notif_phone = mPHONE;
	SET NEW.mutation_notif_email = mEMAIL;
	SET NEW.mutation_session = fn_create_session();
	SET NEW.mutation_bank_session = mBANK_SESSION;
	SET NEW.mutation_bank_id = mBANK_ID;
	SET NEW.mutation_date = NEW.mutation_api_date;
	SET NEW.mutation_user_session = mUSER_SESSION;
	
	-- UPDATE banks SET bank_api_last_check=NOW() WHERE bank_session=mBANK_SESSION;	
	UPDATE banks SET bank_api_last_check=NOW() WHERE bank_account_number=@mBANK_ACCOUNT_NUMBER;		
END$$
DELIMITER ;