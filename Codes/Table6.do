
***** TABLE 6 ******
cd "$wd"
use "$Data\s12_data_final.dta", clear

// winsor2 MF_OWN PF_OWN AF_OWN U_OWN ROA MCap adj_mrktvalue, cuts(1 99) suffix(_W)
collapse (mean) MF_OWN PF_OWN AF_OWN U_OWN indpt_pct ppill_rem ab_sm DUALCLASS ROA MCap adj_mrktvalue top250 bot250 r2000, by(cusip6 yr)

gen log_mktcap=ln(MCap)
gen log_mktcap2=log_mktcap^2
gen log_mktcap3=log_mktcap^3
gen log_float=ln(adj_mrktvalue)

egen pas_2=sd(PF_OWN)
gen pas=PF_OWN/pas_2


*** Especification 1
xi: ivregress 2sls ppill_rem log_mktcap log_float i.yr (pas = top250), r cluster(cusip6)
outreg2 using "$Output\Table6.doc", append ctitle(Polynomial N=1) drop(log_float c.log* _I*)  alpha(0.01, 0.10) dec(3) noobs nocons

*** Especification 2
xi: ivregress 2sls ppill_rem log_mktcap log_mktcap2 log_float i.yr (pas = top250), r cluster(cusip6)
outreg2 using "$Output\Table6.doc", append ctitle(Polynomial N=2) drop(log_float c.log* _I*)  alpha(0.01, 0.10) dec(3) noobs nocons

*** Especification 3
ivregress 2sls ppill_rem log_mktcap log_mktcap2 log_mktcap3 log_float i.yr (pas = top250), r cluster(cusip6)
outreg2 using "$Output\Table6.doc", append ctitle(Polynomial N=3) drop(log_float c.log* _I*)  alpha(0.01, 0.10) dec(3) noobs nocons

*** Especification 4
xi: ivregress 2sls ab_sm log_mktcap log_float i.yr (pas = top250), r cluster(cusip6)
outreg2 using "$Output\Table6.doc", append ctitle(Polynomial N=1) drop(log_float c.log* _I*)  alpha(0.01, 0.10) dec(3) noobs nocons

*** Especification 5
xi: ivregress 2sls ab_sm log_mktcap log_mktcap2 log_float i.yr (pas = top250), r cluster(cusip6)
outreg2 using "$Output\Table6.doc", append ctitle(Polynomial N=2) drop(log_float c.log* _I*)  alpha(0.01, 0.10) dec(3) noobs nocons

*** Especification 6
ivregress 2sls ab_sm log_mktcap log_mktcap2 log_mktcap3 log_float i.yr (pas = top250), r cluster(cusip6)
outreg2 using "$Output\Table6.doc", append ctitle(Polynomial N=3) drop(log_float c.log* _I*)  alpha(0.01, 0.10) dec(3) noobs nocons
