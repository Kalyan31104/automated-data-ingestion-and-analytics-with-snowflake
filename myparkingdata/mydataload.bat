@echo off
set SNOWSQL_PWD=doe
@echo on
snowsql -a xlfbnzj-nw62498 -u de_1 -w de_warehouse -d parking_db -s staging_sch -f D:\myparkingdata\put.txt -f D:\myparkingdata\copy.txt