/* header */
version 15.1

set more off, permanently
set scheme s2mono


/* sample */
use "data_need_fulfilment_pilot_3", clear

label define gender_lb 1 "female" ///
                       2 "other" ///
                       3 "male"
   label values gender gender_lb

label define education_lb 1 "No school-leaving certificate" ///
                          2 "Certificate of secondary education" ///
                          3 "General certificate of secondary education" ///
                          4 "General higher education entrance qualification" ///
                          5 "Completed vocational training" ///
                          6 "Technician or master craftsman" ///
                          7 "Bachelor (or comparable)" ///
                          8 "Master (or comparable)" ///
                         11 "Doctorate"
   label values education education_lb

label define state_lb 1 "Baden-Württemberg" ///
                      2 "Bavaria" ///
                      3 "Berlin" ///
                      4 "Brandenburg" ///
                      5 "Bremen" ///
                      6 "Hamburg" ///
                      7 "Hesse" ///
                      8 "Mecklenburg-Vorpommern" ///
                      9 "Lower Saxony" ///
                     10 "North Rhine-Westphalia" ///
                     11 "Rhineland-Palatinate" ///
                     12 "Saarland" ///
                     13 "Saxony" ///
                     14 "Saxony-Anhalt" ///
                     15 "Schleswig-Holstein" ///
                     16 "Thuringia"
   label values state state_lb

sum age, detail
tab gender
tab education
tab state
sum income, detail
sum space, detail
tab persons
tab politics


/* normalize judgment */
use "data_need_fulfilment_pilot_3", clear

reshape long case, i(id) j(case_new)

rename case judgment
rename case_new case

gen judgment_norm = .

foreach i of num 1/24 {
   egen judgment_min_`i' = min(judgment) if id == `i'
   egen judgment_max_`i' = max(judgment) if id == `i'

   replace judgment_norm = (judgment - judgment_min_`i') / (judgment_max_`i' - judgment_min_`i') if id == `i'

   drop judgment_min_`i'
   drop judgment_max_`i'
}


/* reference values */
gen reference_value = .
   replace reference_value = 0.00 if case == 1
   replace reference_value = 0.05 if case == 2
   replace reference_value = 0.10 if case == 3
   replace reference_value = 0.15 if case == 4
   replace reference_value = 0.20 if case == 5
   replace reference_value = 0.25 if case == 6
   replace reference_value = 0.30 if case == 7
   replace reference_value = 0.35 if case == 8
   replace reference_value = 0.40 if case == 9
   replace reference_value = 0.45 if case == 10
   replace reference_value = 0.50 if case == 11
   replace reference_value = 0.55 if case == 12
   replace reference_value = 0.60 if case == 13
   replace reference_value = 0.65 if case == 14
   replace reference_value = 0.70 if case == 15
   replace reference_value = 0.75 if case == 16
   replace reference_value = 0.80 if case == 17
   replace reference_value = 0.85 if case == 18
   replace reference_value = 0.90 if case == 19
   replace reference_value = 0.95 if case == 20
   replace reference_value = 1.00 if case == 21


/* mean judgment */
preserve
   collapse (mean) reference_value = reference_value (mean) mean_judgment_norm = judgment_norm (sd) sd_judgment_norm = judgment_norm (count) n = judgment_norm, by(case)

   generate high = mean_judgment_norm + invttail(n - 1, 0.05) * (sd_judgment_norm / sqrt(n))
   generate low = mean_judgment_norm - invttail(n - 1, 0.05) * (sd_judgment_norm / sqrt(n))

   twoway (connected mean_judgment_norm case) ///
          (connected reference_value case) ///
          (rcap high low case, lcolor(black)), /// 
          title("") ///
          xtitle("Case") ///
          ytitle("Normalized Judgment") ///
          graphregion(color(white)) ///
          legend(off) ///
          saving(figure_pilot_3_1, replace)
      graph export figure_pilot_3_1.pdf, replace
restore

by case, sort : ci means judgment_norm


/* individual judgment */
twoway (connected judgment_norm case, mcolor(black) lpattern(solid)), ///
       by(id, note("") graphregion(color(white))) ///
       title("") ///
       xtitle("Case") ///
       ytitle("Normalized Judgment") ///
       graphregion(color(white)) ///
       legend(off) ///
       saving(figure_pilot_3_2, replace)
   graph export figure_pilot_3_2.pdf, replace


/* Wilcoxon matched-pairs signed-rank test */
foreach i of num 1/21 {
   preserve
      keep if case == `i'

      signrank judgment_norm = reference_value
   restore
}
