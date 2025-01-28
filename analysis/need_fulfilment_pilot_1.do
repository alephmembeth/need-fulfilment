/* header */
version 15.1

set more off, permanently
set scheme s2mono


/* sample */
use "data_need_fulfilment_pilot_1", clear

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


/* judgment */
use "data_need_fulfilment_pilot_1", clear

reshape long case, i(id) j(case_new)

rename case judgment
rename case_new case

gen judgment_norm = .

foreach i of num 1/74 {
   egen judgment_min_`i' = min(judgment) if id == `i'
   egen judgment_max_`i' = max(judgment) if id == `i'

   replace judgment_norm = (judgment - judgment_min_`i') / (judgment_max_`i' - judgment_min_`i') if id == `i'

   drop judgment_min_`i'
   drop judgment_max_`i'
}

twoway (connected judgment_norm case, mcolor(black) lpattern(solid)), ///
       by(id, note("") graphregion(color(white))) ///
       saving(figure_pilot_1, replace)
   graph export figure_pilot_1.pdf, replace
