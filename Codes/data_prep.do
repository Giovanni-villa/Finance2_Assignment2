*** This do-file executes the data preparation for Appel-Gormley-Kein Replication.


*** We prepare s12 Data to match with the other sources
use "$Data\s12_data", clear

*** We use the shares outstanding measure that it's more accurate.
*** Transform the one 
replace shrout2=shrout1*1000 if shrout2==.
drop shrout1
rename shrout2 shrout
rename fundname fundname_s12

*** dropping non useful variables
drop change stkname ticker stkcd  stkcdesc assets

gen yr=year(rdate)
gen mo=month(rdate)
gen yearmonth=ym(yr, mo)
*drop rdate
format %tm yearmonth

*** Keeping only the last day of the month data
egen groupid=group(fundno cusip)
duplicates tag groupid yearmonth, gen(aux)
sort groupid yearmonth rdate
by groupid yearmonth: gen aux2=_n
by groupid yearmonth: egen aux3=max(aux2)
drop if aux>0 & aux2<aux3
drop aux aux2 aux3

*** generating end-of-september holdings variable
gen shares_sept=shares if mo==9
bys groupid (yearmonth): gen aux=_n
bys groupid (yearmonth): replace shares_sept=shares if shares_sept==. & aux==1
bys groupid (yearmonth): replace shares_sept=shares_sept[_n-1] if shares_sept==.
drop aux

*** Now We impute the previous holding data to each end-of-september data
gen aux=9-mo
bysort groupid (year): egen aux2=min(aux) if aux>=0
gen shares2=shares_sept if aux2==aux
bys groupid (yr): replace shares2=shares_sept if _n==1 & shares2==.
keep if shares2!=.
drop aux aux2

*** We keep the closest to september data in case we have more than one obs in any year
*** (Initial data + data in september)
bys groupid yr: gen aux=_n
bys groupid yr: egen aux2=max(aux)
keep if aux==aux2
drop aux aux2 shares shares_sept
rename shares2 shares

*** Now after we have the yearly dataset to yearly data and fill the gaps assuming the holdings
*** maintain in case of missing data before 2004
xtset groupid yr
tsfill, full
bys groupid (yr): replace shares=shares[_n-1] if yr<2004 & shares==.
drop mo yearmonth rdate shrout
drop if shares==.

*** We recover the other variables for our data
bys groupid (yr): replace fundname=fundname[_n-1] if _n>1 & fundname==""
bys groupid (yr): replace cusip=cusip[_n-1] if _n>1 & cusip==""
foreach var of varlist fundno prc{
	bys groupid (yr): replace `var'=`var'[_n-1] if _n>1 & `var'==.
} 

tostring fundno, replace

save "$Data\s12_data_aux1.dta", replace

*** We open Russell 2000 Data and match to our dataset

use "$Data\russell_all.dta", clear
gen yr = yofd(dofm(yearmonth))
drop yearmonth

merge 1:m cusip yr using "$Data\s12_data_aux1.dta"

*** We keep only holdings for firms in the Russell index
drop if _m==2
drop _m

save "$Data\s12_data_aux2.dta", replace

*** We add the Float Market-Adj Cap (MktValue variable)

use "$Data\russell_constituents.dta", clear

gen yr = year(Date)
gen mo = month(Date)
rename MktValue Float
** we keep end-of-june data only
keep if mo==6
drop mo

* Getting top250 and bottom 250 of Russell 2000 and 1000 respectively
bys yr: egen q75 = pctile(R2000_WT), p(75)
bys yr: egen q25 = pctile(R1000_WT), p(25)
gen top250=1 if R2000_WT>=q75 & R2000_WT!=.
gen bot250=1 if R1000_WT<=q25 & R1000_WT!=.

keep if top250==1 | bot250==1
replace top250=0 if top250==.
replace bot250=0 if bot250==.
keep Date CUSIP Float top250 bot250 yr

rename CUSIP cusip
replace cusip=substr(cusip, 1, 8)

** Now we merge with our dataset
merge 1:m cusip yr using "$Data\s12_data_aux2.dta"
keep if _m==3
drop _m
save "$Data\s12_data_aux3.dta", replace

*** Merging CRSP Index fund flag variable and MFLINKS

use "$Data\index_fund_flag.dta", clear

gen yr=year(caldt)
gen mo=month(caldt)
gen yearmonth=ym(yr, mo)
format %tm yearmonth

duplicates drop
drop summary_period2
drop caldt

*** We keep only end-of-september data. We impute the previous non-missing obs
*** in case it's not available

xtset crsp_fundno yearmonth
tsfill, full

bys crsp_fundno (yearmonth): replace index_fund_flag=index_fund_flag[_n-1] if index_fund_flag==""
drop mo yr
gen date=dofm(yearmonth)
gen mo=month(date)
gen yr=year(date)
keep if mo==9
drop date mo yearmonth


*** We generate the index flat variable
gen index_flag=0 if index_fund_flag==""
replace index_flag=1 if index_flag==.
drop if index_flag==.
drop index_fund_flag
duplicates drop

save "$Data\ind_mflink1.dta", replace


** merge with MFLINK1
use "$Data\mflink1_raw.dta", clear
expand 9
bys crsp_fundno: gen yr=_n + 1997

merge 1:1 crsp_fundno yr  using "$Data\ind_mflink1.dta"
drop if _m==1
drop _m


** replacing index flag for the case with multiple fundno for one wficn with 1 if 
** there is one fundno flagged as index fund (following MFLINKS)
bys wficn yr: egen aux=max(index_flag)
replace index_flag=aux
keep yr wficn index_flag crsp_fundno
duplicates drop

save "$Data\ind_mflink1.dta", replace

*** Now we merge with the MFLINKS2 data
use "$Data\mflink2_raw.dta", clear
keep wficn fundname fundno rdate 
drop if wficn==.
gen yr=year(rdate)
keep if yr>=1998 & yr<=2006
drop rdate
duplicates drop

*** Now we collapse all names by id-year in a single string to facilitate the merge

bys wficn: gen fund_names = fundname[1]
bys wficn: replace fund_names = fund_names[_n-1] + " " + fundname if _n > 1
bys wficn: replace fund_names = fund_names[_N]
drop fundname
duplicates drop
strcompress fund_names

*** Now we flag the words related to passive investing
gen passive_ind= 0
qui foreach word in "INDEX", "IDX", "INDX", "IND", "RUSSELL", "S & P", "S AND P", "S&P", "SANDP", "SP", "DOW", "DJ", "MSCI", "BLOOMBERG", "KBW", "NASDAQ", "NYSE", "STOXX", "FTSE", "WILSHIRE", "MORNINGSTAR", "100", "400", "500", "600", "900", "1000", "1500", "2000", "5000". {
	  replace passive_ind=1 if strlen(fund_names) > strlen(subinword(fund_names, "`word'", "", .)) & passive_ind == 0
}


*** We merge with our MFLINK1 data
merge m:m wficn yr using "$Data\ind_mflink1.dta"
gen active_ind=1 if _m==3 & passive_ind==0
replace active_ind=0 if active_ind==.
replace passive_ind=0 if passive_ind==.
drop if _m==2
drop _m
keep wficn fundno fund_names passive_ind active_ind yr index_flag
duplicates drop

*** complement with index_flag from CSRP
replace passive_ind= 1 if index_flag==1
drop wficn fund_names
duplicates drop fundno yr, force

*** We merge with our previous data
tostring fundno, replace
merge 1:m fundno yr using "$Data\s12_data_aux3.dta"
drop if _m==1
drop _m 

save "$Data\s12_data_aux4.dta", replace




*** Now we work with the RiskMetrics Director's data
use "$Data\directors.dta", clear

keep YEAR LEGACY_PPS_ID RT_ID TICKER CUSIP MEETINGDATE INDEXNAME CLASSIFICATION MTGMONTH
gen ind_flag=1 if CLASSIFICATION=="I"
replace ind_flag=0 if ind_flag==.

bys CUSIP MEETINGDATE: egen indpt_pct=mean(ind_flag)

keep MEETINGDATE CUSIP indpt_pct 

*** We go transform to fiscal date format as it's explained in the paper
gen yr=year(MEETINGDATE)
gen mo=month(MEETINGDATE)
replace yr=yr+1 if mo>=7
rename CUSIP cusip6
drop if yr>=2007 & yr<=1998

*** We take the avg of the Independent directors percentage in every year by firm
collapse (mean) indpt_pct, by(yr cusip6)


*** We merge with our data
merge 1:m cusip6 yr using "$Data\s12_data_aux4.dta"
drop if _m==1
drop _m
save "$Data\s12_data_aux5.dta", replace

*** Now we work with the governance data from RiskMetrics
use "$Data\governance.dta", clear

* We keep only relevant variables
keep CN6 YEAR PPILL LSPMT DUALCLASS DATE1 DATE2

* We generate the Poison pill removal and Greater ability to call special meeting dummies
bys CN6 (YEAR): gen ppill_rem=1 if PPILL==0 & PPILL[_n-1]==1
replace ppill_rem=0 if ppill_rem==.
bys CN6 (YEAR): gen ab_sm=1 if LSPMT==0 & LSPMT[_n-1]==1
replace ab_sm=0 if ab_sm==.

drop DATE1 DATE2 PPILL LSPMT

* We complete the panel with the data between periods
egen id=group(CN6)
xtset id YEAR
tsfill, full

bys id (YEAR): replace CN6=CN6[_n-1] if CN6==""
foreach var of varlist DUALCLASS ab_sm ppill_rem{
	bys id (YEAR): replace `var'=`var'[_n-1] if `var'==.
} 

drop if CN6==""
drop id

rename CN6 cusip6
rename YEAR yr

*** We merge with our data
merge 1:m cusip6 yr using "$Data\s12_data_aux5.dta"
drop if _m==1
drop _m

save "$Data\s12_data_aux6.dta", replace

*** Now we work with Compustat Data
use "$Data\compustat.dta", clear
keep fyear cusip at csho ni prcc_f LPERMNO LPERMCO
rename fyear yr
drop if yr<1998 | yr>=2007
replace cusip=substr(cusip, 1, 8)

gen ROA=ni/at
label variable ROA `Return on Assets'

gen aux=csho*prcc_f
bys LPERMCO yr: egen MCap=sum(aux)
label variable MCap `Total Market Cap by PERMCO'
keep yr cusip prcc_f at csho ni ROA MCap
duplicates drop

*** Merge with our dataset
merge 1:m cusip yr using "$Data\s12_data_aux6.dta"
keep if _m==3
drop _m

*** Eliminating observations for which Market-Cap from CRSP < Total mutual funds holdings
gen aux=prc*shares
bys cusip6 yr: egen MF_H=sum(aux)
replace MCap=MCap*1000000
drop aux

drop if MCap<MF_H


**** Definition of relevant variables ****
bys cusip6 yr: egen MF_O=sum(shares)
bys cusip6 yr: gen MF_OWN=MF_O/(csho*1000000)*100
bys cusip6 yr: egen PF_O=sum(shares) if passive_ind==1
bys cusip6 yr: gen PF_OWN=PF_O/(csho*1000000)*100
bys cusip6 yr: egen AF_O=sum(shares) if active_ind==1
bys cusip6 yr: gen AF_OWN=AF_O/(csho*1000000)*100

** Dropping if there is mutual fund ownership is missing
drop if MF_O==.

* Generate unknown ownership indicator
gen unknown_ind=1 if active_ind!=1 & passive_ind!=1
replace unknown_ind=0 if unknown_ind==.

bys cusip yr: egen U_O=sum(shares) if unknown_ind==1
bys cusip yr: gen U_OWN=U_O/(csho*1000000)*100


// *** We keep only variables within our 250 threshhold
// keep if bot250==1 | top250==1

save "$Data\s12_data_final.dta", replace
