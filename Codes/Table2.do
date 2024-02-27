***** TABLE 2 ******
cd "$wd"
use "$Data\s12_data_final.dta", clear

// winsor2 MF_OWN PF_OWN AF_OWN U_OWN ROA MCap adj_mrktvalue, cuts(1 99) suffix(_W)
collapse (mean) MF_OWN PF_OWN AF_OWN U_OWN indpt_pct ppill_rem ab_sm DUALCLASS ROA MCap adj_mrktvalue top250 bot250 r2000, by(cusip6 yr)

gen log_mktcap=ln(MCap)
gen log_mktcap2=log_mktcap^2
gen log_mktcap3=log_mktcap^3
gen log_float=ln(adj_mrktvalue)


*** Especification 1
xi: reg MF_OWN top250 log_mktcap log_mktcap2 log_mktcap3 log_float i.yr, r cluster(cusip6)
outreg2 using "$Output\Table2.doc", append ctitle(All Mutual Funds) drop(log_float c.log* _I*)  alpha(0.01, 0.10) dec(3) noobs nocons

*** Especification 2
xi: reg PF_OWN top250 log_mktcap log_mktcap2 log_mktcap3 log_float i.yr, r cluster(cusip6)
outreg2 using "$Output\Table2.doc", append ctitle(Passive) drop(log_float c.log* _I*)  alpha(0.01, 0.10) dec(3) noobs nocons

*** Especification 3
xi: reg AF_OWN top250 log_mktcap log_mktcap2 log_mktcap3 log_float i.yr, r cluster(cusip6)
outreg2 using "$Output\Table2.doc", append ctitle(Active) drop(log_float c.log* _I*)  alpha(0.01, 0.10) dec(3) noobs nocons

*** Especification 4
xi: reg U_OWN top250 log_mktcap log_mktcap2 log_mktcap3 log_float i.yr, r cluster(cusip6)
outreg2 using "$Output\Table2.doc", append ctitle(Unclassified) drop(log_float c.log* _I*)  alpha(0.01, 0.10) dec(3)  noobs nocons
