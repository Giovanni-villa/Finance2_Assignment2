***** TABLE 1 ******
cd "$wd"
use "$Data\s12_data_final.dta", clear

winsor2 MF_OWN PF_OWN AF_OWN U_OWN ROA, cuts(1 99) suffix(_W)
collapse (mean) MF_OWN PF_OWN AF_OWN U_OWN indpt_pct ppill_rem ab_sm DUALCLASS ROA_W, by(cusip6 yr)

cd "$Output"
asdoc tabstat MF_OWN PF_OWN AF_OWN U_OWN indpt_pct ppill_rem ab_sm DUALCLASS ROA_W, save(Table1) replace stat(N mean median sd)