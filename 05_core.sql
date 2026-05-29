

USE WAREHOUSE HOSPITAL_MANAGEMENT_LOADING;
USE DATABASE HOSPITAL_DATABASE;
USE SCHEMA HOSPITAL_CORE;

-- =====================================================
-- CORE TABLES
-- =====================================================

CREATE OR REPLACE TABLE PATIENT_CORE
LIKE HOSPITAL_RAW.PATIENT_RAW;

CREATE OR REPLACE TABLE APPOINTMENT_CORE
LIKE HOSPITAL_RAW.APPOINTMENT_RAW;

CREATE OR REPLACE TABLE BILLING_CORE
LIKE HOSPITAL_RAW.BILLING_RAW;

-- =====================================================
-- EXCEPTION TABLES
-- =====================================================

CREATE OR REPLACE TABLE PATIENT_EXCEPTION
LIKE HOSPITAL_RAW.PATIENT_RAW;

CREATE OR REPLACE TABLE APPOINTMENT_EXCEPTION
LIKE HOSPITAL_RAW.APPOINTMENT_RAW;

CREATE OR REPLACE TABLE BILLING_EXCEPTION
LIKE HOSPITAL_RAW.BILLING_RAW;

-- =====================================================
-- TASK
-- =====================================================

CREATE OR REPLACE TASK TASK_RAW_TO_CORE
WAREHOUSE = HOSPITAL_MANAGEMENT_LOADING
SCHEDULE = '1 MINUTE'
AS

BEGIN

--------------------------------------------------
-- PATIENT VALID RECORDS
--------------------------------------------------

INSERT INTO PATIENT_CORE
(
PATIENT_ID,
FULL_NAME,
DOB,
GENDER,
PHONE,
EMAIL,
CITY,
STATE,
REGISTRATION_DATE
)
SELECT
PATIENT_ID,
FULL_NAME,
DOB,
GENDER,
PHONE,
EMAIL,
CITY,
STATE,
REGISTRATION_DATE
FROM
(
    SELECT *,
           ROW_NUMBER() OVER
           (
              PARTITION BY PATIENT_ID
              ORDER BY REGISTRATION_DATE DESC
           ) RN
    FROM HOSPITAL_RAW.PATIENT_STREAM
    WHERE PATIENT_ID IS NOT NULL
)
WHERE RN = 1;

--------------------------------------------------
-- PATIENT INVALID RECORDS
--------------------------------------------------

INSERT INTO PATIENT_EXCEPTION
(
PATIENT_ID,
FULL_NAME,
DOB,
GENDER,
PHONE,
EMAIL,
CITY,
STATE,
REGISTRATION_DATE
)
SELECT
PATIENT_ID,
FULL_NAME,
DOB,
GENDER,
PHONE,
EMAIL,
CITY,
STATE,
REGISTRATION_DATE
FROM HOSPITAL_RAW.PATIENT_RAW
WHERE PATIENT_ID IS NULL;

--------------------------------------------------
-- APPOINTMENT VALID RECORDS
--------------------------------------------------

INSERT INTO APPOINTMENT_CORE
(
APPT_ID,
APPT_DATE,
PATIENT_ID,
DOCTOR_ID,
DOCTOR_NAME,
DEPARTMENT,
SLOT,
STATUS
)
SELECT
APPT_ID,
APPT_DATE,
PATIENT_ID,
DOCTOR_ID,
DOCTOR_NAME,
DEPARTMENT,
SLOT,
STATUS
FROM
(
    SELECT *,
           ROW_NUMBER() OVER
           (
              PARTITION BY APPT_ID
              ORDER BY APPT_DATE DESC
           ) RN
    FROM HOSPITAL_RAW.APPOINTMENT_STREAM
    WHERE PATIENT_ID IS NOT NULL
      AND APPT_DATE IS NOT NULL
      AND STATUS IN
      (
        'Scheduled',
        'Completed',
        'No-Show',
        'Cancelled'
      )
)
WHERE RN = 1;

--------------------------------------------------
-- APPOINTMENT INVALID RECORDS
--------------------------------------------------

INSERT INTO APPOINTMENT_EXCEPTION
(
APPT_ID,
APPT_DATE,
PATIENT_ID,
DOCTOR_ID,
DOCTOR_NAME,
DEPARTMENT,
SLOT,
STATUS
)
SELECT
APPT_ID,
APPT_DATE,
PATIENT_ID,
DOCTOR_ID,
DOCTOR_NAME,
DEPARTMENT,
SLOT,
STATUS
FROM HOSPITAL_RAW.APPOINTMENT_RAW
WHERE PATIENT_ID IS NULL
   OR APPT_DATE IS NULL
   OR STATUS NOT IN
      (
       'Scheduled',
       'Completed',
       'No-Show',
       'Cancelled'
      );

--------------------------------------------------
-- BILLING VALID RECORDS
--------------------------------------------------

INSERT INTO BILLING_CORE
(
BILL_ID,
BILL_DATE,
PATIENT_ID,
SERVICE_CODE,
SERVICE_DESC,
DEPARTMENT,
GROSS_AMOUNT,
DISCOUNT_AMOUNT,
TAX_AMOUNT,
NET_AMOUNT,
PAYMENT_MODE,
INSURER_NAME
)
SELECT
BILL_ID,
BILL_DATE,
PATIENT_ID,
SERVICE_CODE,
SERVICE_DESC,
DEPARTMENT,
GROSS_AMOUNT,
DISCOUNT_AMOUNT,
TAX_AMOUNT,
NET_AMOUNT,
PAYMENT_MODE,
INSURER_NAME
FROM
(
    SELECT *,
           ROW_NUMBER() OVER
           (
              PARTITION BY BILL_ID
              ORDER BY BILL_DATE DESC
           ) RN
    FROM HOSPITAL_RAW.BILLING_STREAM
    WHERE PATIENT_ID IS NOT NULL
      AND BILL_DATE IS NOT NULL
      AND NET_AMOUNT >= 0
)
WHERE RN = 1;

--------------------------------------------------
-- BILLING INVALID RECORDS
--------------------------------------------------

INSERT INTO BILLING_EXCEPTION
(
BILL_ID,
BILL_DATE,
PATIENT_ID,
SERVICE_CODE,
SERVICE_DESC,
DEPARTMENT,
GROSS_AMOUNT,
DISCOUNT_AMOUNT,
TAX_AMOUNT,
NET_AMOUNT,
PAYMENT_MODE,
INSURER_NAME
)
SELECT
BILL_ID,
BILL_DATE,
PATIENT_ID,
SERVICE_CODE,
SERVICE_DESC,
DEPARTMENT,
GROSS_AMOUNT,
DISCOUNT_AMOUNT,
TAX_AMOUNT,
NET_AMOUNT,
PAYMENT_MODE,
INSURER_NAME
FROM HOSPITAL_RAW.BILLING_RAW
WHERE PATIENT_ID IS NULL
   OR BILL_DATE IS NULL
   OR NET_AMOUNT < 0;

END;

-- =====================================================
-- START TASK
-- =====================================================

ALTER TASK TASK_RAW_TO_CORE resume;

-- =====================================================
-- MANUAL EXECUTION
-- =====================================================

EXECUTE TASK TASK_RAW_TO_CORE;

-- =====================================================
-- VERIFY TASK
-- =====================================================

SHOW TASKS;

-- =====================================================
-- VERIFY CORE TABLES
-- =====================================================

SELECT COUNT(*) FROM PATIENT_CORE;
SELECT COUNT(*) FROM APPOINTMENT_CORE;
SELECT COUNT(*) FROM BILLING_CORE;

-- =====================================================
-- VERIFY EXCEPTION TABLES
-- =====================================================

SELECT COUNT(*) FROM PATIENT_EXCEPTION;
SELECT COUNT(*) FROM APPOINTMENT_EXCEPTION;
SELECT COUNT(*) FROM BILLING_EXCEPTION;

-- =====================================================
-- SAMPLE DATA
-- =====================================================

SELECT * FROM PATIENT_CORE;
SELECT * FROM APPOINTMENT_CORE ;
SELECT * FROM BILLING_CORE LIMIT 10;

SELECT * FROM PATIENT_EXCEPTION LIMIT 10;
SELECT * FROM APPOINTMENT_EXCEPTION LIMIT 10;
SELECT * FROM BILLING_EXCEPTION LIMIT 10;



show tables;

