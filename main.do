*** This do-file performs the replication for Appel-Gormley-Kein (2016)


clear all
set more off

global wd "C:\Users\Giovanni\OneDrive - Duke University\Appel-Gormley-Kein\"
global Data "$wd\Data"
global Codes "$wd\Codes"
global Output "$wd\Output"

capture log close
log using "$wd\Replication_log_file.log", replace

*** We run the data preparation for the Replication
do "$Codes\data_prep.do"

***  Table 1 ***
do "$Codes\table1.do"

***  Table 2 ***
do "$Codes\table2.do"

***  Table 3 ***
do "$Codes\table3.do"

***  Table 4 ***
do "$Codes\table4.do"

***  Table 5 ***
do "$Codes\table5.do"

***  Table 6 ***
do "$Codes\table6.do"

***  Table 7 ***
do "$Codes\table7.do"

*** log file ***
log close