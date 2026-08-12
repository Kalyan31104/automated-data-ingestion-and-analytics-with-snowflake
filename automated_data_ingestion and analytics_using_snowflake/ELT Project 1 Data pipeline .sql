use role data_engineer;
use warehouse de_warehouse;
Create database parking_db;
use database parking_db;
drop schema public;
create schema staging_sch;
create schema prod_sch data_retention_time_in_days = 10;
-----------------------------------------------------
use schema staging_sch;
 
create stage ext_stage
url = 'azure://hxwjulystorageaccount.blob.core.windows.net/parking-data'
credentials = (azure_sas_token = 'your_sas_token');
 
list @ext_stage;
 
create stage int_stage;
 
show stages;
---------------------------------
use schema staging_sch;
 
create or replace table parking_NEW
(
Summons_Number Number ,
Plate_ID Varchar ,
Registration_State Varchar ,
Plate_Type Varchar ,
Issue_Date DATE ,
Violation_Code Number ,
Vehicle_Body_Type Varchar ,
Vehicle_Make Varchar ,
Issuing_Agency Varchar ,
Street_Code1 Number ,
Street_Code2 Number ,
Street_Code3 Number ,
Vehicle_Expiration_Date Number ,
Violation_Location Varchar ,
Violation_Precinct Number ,
Issuer_Precinct Number ,
Issuer_Code Number ,
Issuer_Command Varchar ,
Issuer_Squad Varchar ,
Violation_Time Varchar ,
Time_First_Observed Varchar ,
Violation_County Varchar ,
Violation_In_Front_Of_Or_Opposite Varchar ,
House_Number Varchar ,
Street_Name Varchar ,
Intersecting_Street Varchar ,
Date_First_Observed Number ,
Law_Section Number ,
Sub_Division Varchar ,
Violation_Legal_Code Varchar ,
Days_Parking_In_Effect Varchar ,
From_Hours_In_Effect Varchar ,
To_Hours_In_Effect Varchar ,
Vehicle_Color Varchar ,
Unregistered_Vehicle Varchar ,
Vehicle_Year Number ,
Meter_Number Varchar ,
Feet_From_Curb Number ,
Violation_Post_Code Varchar ,
Violation_Description Varchar ,
No_Standing_or_Stopping_Violation Varchar ,
Hydrant_Violation Varchar ,
Double_Parking_Violation Varchar ,
Latitude Varchar,
Longitude Varchar,
Community_Board Varchar,
Community_Council Varchar,
Census_Tract Varchar,
BIN Varchar,
BBL Varchar,
NTA Varchar
);
---------------------
use schema staging_sch;
 
CREATE OR REPLACE TASK PARKING_DATA_LOAD_TASK
WAREHOUSE = de_warehouse
SCHEDULE = '1 minute'
AS
copy into PARKING_NEW
from @ext_stage
ON_ERROR='CONTINUE'
file_format = (type = 'csv',error_on_column_count_mismatch=false);
 
show tasks;
---testing ext stage whether working or not----
alter task PARKING_DATA_LOAD_TASK resume;

select * from PARKING_NEW;--54043,0

alter task PARKING_DATA_LOAD_TASK suspend;

truncate table PARKING_NEW;
/*
created a folder in myparkingdata in D drive
within that create a folder dataset and upload data in that

create the following
copy.txt
put.txt
mydataload.bat

copy.txt
copy into PARKING_NEW
from @int_stage
ON_ERROR='CONTINUE'
file_format = (type = 'csv',error_on_column_count_mismatch=false);

put.txt
put file://D:\myparkingdata\dataset\* @int_stage;

mydataload.bat
@echo off
set SNOWSQL_PWD=doe
@echo on
snowsql -a xlfbnzj-nw62498 -u de_1 -w de_warehouse -d parking_db -s staging_sch -f D:\myparkingdata\put.txt -f D:\myparkingdata\copy.txt

execute mydataload.bat in cmd of location D:\myparkingdata\

*/
remove @int_stage;
list @int_stage;
----------------------------------------
use schema prod_sch;
 
create table NY_PARKING_TABLE like PARKING_DB.STAGING_SCH.PARKING_NEW;
create table NJ_PARKING_TABLE like PARKING_DB.STAGING_SCH.PARKING_NEW;
-------------------------------------------
use schema staging_sch;
 
create or replace stream NY_STREAM on table parking_new append_only = true;
create or replace stream NJ_STREAM on table parking_new append_only = true;

------------------------------------------------
use schema staging_sch;
 
CREATE OR REPLACE TASK NY_PARKING_NEW_TASK

WAREHOUSE = de_warehouse

SCHEDULE = '1 minute'

WHEN

SYSTEM$STREAM_HAS_DATA('NY_STREAM')

AS

INSERT INTO PARKING_DB.PROD_SCH.NY_PARKING_TABLE

(

Summons_Number, Plate_ID, Registration_State, Plate_Type, Issue_Date, Violation_Code, Vehicle_Body_Type, Vehicle_Make,

Issuing_Agency, Street_Code1, Street_Code2, Street_Code3, Vehicle_Expiration_Date, Violation_Location, Violation_Precinct,

Issuer_Precinct, Issuer_Code, Issuer_Command, Issuer_Squad, Violation_Time, Time_First_Observed, Violation_County,

Violation_In_Front_Of_Or_Opposite, House_Number, Street_Name, Intersecting_Street, Date_First_Observed, Law_Section,

Sub_Division, Violation_Legal_Code, Days_Parking_In_Effect, From_Hours_In_Effect, To_Hours_In_Effect, Vehicle_Color,

Unregistered_Vehicle, Vehicle_Year, Meter_Number, Feet_From_Curb, Violation_Post_Code, Violation_Description,

No_Standing_or_Stopping_Violation, Hydrant_Violation, Double_Parking_Violation, Latitude, Longitude, Community_Board,

Community_Council, Census_Tract, BIN, BBL, NTA

)

SELECT

Summons_Number, Plate_ID, Registration_State, Plate_Type, Issue_Date, Violation_Code, Vehicle_Body_Type, Vehicle_Make,

Issuing_Agency, Street_Code1, Street_Code2, Street_Code3, Vehicle_Expiration_Date, Violation_Location, Violation_Precinct,

Issuer_Precinct, Issuer_Code, Issuer_Command, Issuer_Squad, Violation_Time, Time_First_Observed, Violation_County,

Violation_In_Front_Of_Or_Opposite, House_Number, Street_Name, Intersecting_Street, Date_First_Observed, Law_Section,

Sub_Division, Violation_Legal_Code, Days_Parking_In_Effect, From_Hours_In_Effect, To_Hours_In_Effect, Vehicle_Color,

Unregistered_Vehicle, Vehicle_Year, Meter_Number, Feet_From_Curb, Violation_Post_Code, Violation_Description,

No_Standing_or_Stopping_Violation, Hydrant_Violation, Double_Parking_Violation, Latitude, Longitude, Community_Board,

Community_Council, Census_Tract, BIN, BBL, NTA

FROM NY_STREAM WHERE Registration_State='NY' AND metadata$action = 'INSERT';

CREATE OR REPLACE TASK NJ_PARKING_NEW_TASK
WAREHOUSE = de_warehouse
SCHEDULE = '1 minute'
WHEN
SYSTEM$STREAM_HAS_DATA('NJ_STREAM')
AS
INSERT INTO PARKING_DB.PROD_SCH.NJ_PARKING_TABLE
(
Summons_Number, Plate_ID, Registration_State, Plate_Type, Issue_Date, Violation_Code, Vehicle_Body_Type, Vehicle_Make,
Issuing_Agency, Street_Code1, Street_Code2, Street_Code3, Vehicle_Expiration_Date, Violation_Location, Violation_Precinct,
Issuer_Precinct, Issuer_Code, Issuer_Command, Issuer_Squad, Violation_Time, Time_First_Observed, Violation_County,
Violation_In_Front_Of_Or_Opposite, House_Number, Street_Name, Intersecting_Street, Date_First_Observed, Law_Section,
Sub_Division, Violation_Legal_Code, Days_Parking_In_Effect, From_Hours_In_Effect, To_Hours_In_Effect, Vehicle_Color,
Unregistered_Vehicle, Vehicle_Year, Meter_Number, Feet_From_Curb, Violation_Post_Code, Violation_Description,
No_Standing_or_Stopping_Violation, Hydrant_Violation, Double_Parking_Violation, Latitude, Longitude, Community_Board,
Community_Council, Census_Tract, BIN, BBL, NTA
)
SELECT
Summons_Number, Plate_ID, Registration_State, Plate_Type, Issue_Date, Violation_Code, Vehicle_Body_Type, Vehicle_Make,
Issuing_Agency, Street_Code1, Street_Code2, Street_Code3, Vehicle_Expiration_Date, Violation_Location, Violation_Precinct,
Issuer_Precinct, Issuer_Code, Issuer_Command, Issuer_Squad, Violation_Time, Time_First_Observed, Violation_County,
Violation_In_Front_Of_Or_Opposite, House_Number, Street_Name, Intersecting_Street, Date_First_Observed, Law_Section,
Sub_Division, Violation_Legal_Code, Days_Parking_In_Effect, From_Hours_In_Effect, To_Hours_In_Effect, Vehicle_Color,
Unregistered_Vehicle, Vehicle_Year, Meter_Number, Feet_From_Curb, Violation_Post_Code, Violation_Description,
No_Standing_or_Stopping_Violation, Hydrant_Violation, Double_Parking_Violation, Latitude, Longitude, Community_Board,
Community_Council, Census_Tract, BIN, BBL, NTA
FROM NJ_STREAM WHERE Registration_State='NJ' AND metadata$action = 'INSERT';

show tasks;
---------------------------------------------------
select * from PARKING_DB.STAGING_SCH.PARKING_NEW;
select count(*) from PARKING_DB.STAGING_SCH.PARKING_NEW;--54043 ,106432
 
select * from PARKING_DB.PROD_SCH.NJ_PARKING_TABLE;
select count(*) from PARKING_DB.PROD_SCH.NJ_PARKING_TABLE;--5641,12161
 
select * from PARKING_DB.PROD_SCH.NY_PARKING_TABLE;
select count(*) from PARKING_DB.PROD_SCH.NY_PARKING_TABLE;--37568,75472
---------------------------------------------------------
alter task NJ_PARKING_NEW_TASK resume;
alter task NY_PARKING_NEW_TASK resume;
alter task PARKING_DATA_LOAD_TASK resume;
-------------------------------------------------------
show tasks;

alter task NJ_PARKING_NEW_TASK suspend;
alter task NY_PARKING_NEW_TASK suspend;
alter task PARKING_DATA_LOAD_TASK suspend;

-------------------------------------------------------power bi report made ,added new data one over cloud and one with batch file which results dashboard changes------------
/*connect to powerbi import data from snowflake using option snowflake
fill credntials like server is account url without https and console or just xlfbnzj-nw62498.snowflakecomputing.com and warehouse analyst_wh(as using that) later provide analyst username and password to connect*/

--------------------------------------------------------------------------------------------------
---used dynamic dynamic tables to store results instead of streams--
create schema dynamic_sch;
use schema dynamic_sch;

create or replace table parking_new like PARKING_DB.STAGING_SCH.PARKING_NEW;

create or replace DYNAMIC table ny_dynamic
target_lag = '1 Minute'
warehouse = de_warehouse
as
select * from parking_new where Registration_State='NY';

create or replace DYNAMIC table nj_dynamic
target_lag = '1 Minute'
warehouse = de_warehouse
as
select * from parking_new where Registration_State='NJ';

select * from parking_new;--54043,101399
select * from ny_dynamic;--37568,70539
select * from nj_dynamic;--5641,11833


COPY INTO PARKING_DB.DYNAMIC_SCH.PARKING_NEW
FROM @PARKING_DB.STAGING_SCH.EXT_STAGE/xaa
FILE_FORMAT = (
    TYPE = 'CSV',
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE,
    SKIP_HEADER = 1
)
ON_ERROR = 'CONTINUE';

COPY INTO PARKING_DB.DYNAMIC_SCH.PARKING_NEW
FROM @PARKING_DB.STAGING_SCH.EXT_STAGE/xac
FILE_FORMAT = (
    TYPE = 'CSV',
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE,
    SKIP_HEADER = 1
)
ON_ERROR = 'CONTINUE';

--truncate table PARKING_DB.DYNAMIC_SCH.PARKING_NEW;
alter DYNAMIC table ny_dynamic suspend;
alter DYNAMIC table nj_dynamic suspend;

show tables;

use schema staging_sch;
show tasks;






 