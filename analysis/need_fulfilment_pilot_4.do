/* header */
version 19.5
set more off
set scheme s2mono


/* compute sociodemographics */
use "data_need_fulfilment_pilot_4", clear

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


/* rename variables */
forvalues i = 1/6 {
   rename fulfillment`i'q  fq`i'
   rename fulfillment`i's1 fa`i'
   rename fulfillment`i's2 fb`i'

   rename justice`i'q      jq`i'
   rename justice`i's1     ja`i'
   rename justice`i's2     jb`i'
}


/* reshape data */
reshape long fq fa fb jq ja jb, i(id) j(case)


/* generate dimension variable */
gen dim = .
   replace dim = 0 if !missing(fq) | !missing(fa) | !missing(fb)
   replace dim = 1 if !missing(jq) | !missing(ja) | !missing(jb)

label define dim_lb 0 "Fulfillment" ///
                    1 "Justice"
   label values dim dim_lb


/* generate unified variables for responses and scales */
gen resp = .
   replace resp = fq if dim == 0
   replace resp = jq if dim == 1

gen s1 = .
   replace s1 = fa if dim == 0
   replace s1 = ja if dim == 1

gen s2 = .
   replace s2 = fb if dim == 0
   replace s2 = jb if dim == 1


/* drop helper variables */
drop fq fa fb jq ja jb


/* generate variables for consistency of choices
   
   coding of resp:
      1 = A and B are equally supplied
      2 = A is better supplied
      3 = B is better supplied
   
   design of cases:
      1–3: same absolute difference
      4–6: same ratio
   
   difference rule predicts:
      cases 1–3: A and B are equally supplied   (resp == 1)
      cases 4–6: A is better supplied           (resp == 2)
   
   ratio rule predicts:
      cases 1–3: B is better supplied           (resp == 3)
      cases 4–6: A and B are equally supplied   (resp == 1)
   
   */
gen diff_cons = 0
   replace diff_cons = 1 if inlist(case, 1, 2, 3) & resp == 1
   replace diff_cons = 1 if inlist(case, 4, 5, 6) & resp == 2

gen ratio_cons = 0
   replace ratio_cons = 1 if inlist(case, 1, 2, 3) & resp == 3
   replace ratio_cons = 1 if inlist(case, 4, 5, 6) & resp == 1


/* generate variables for scale-based differences */
gen diff_s = s2 - s1

gen ratio_s = (s2 - s1) / (abs(s1) + abs(s2) + 1e-9)


/* generate bar charts */
label define resp_lb 1 "A = B" ///
                     2 "A better" ///
                     3 "B better"
   label values resp resp_lb

graph bar (percent), ///
      over(resp, label(angle(45))) ///
      over(dim) ///
      by(case, cols(3) title("Choices by Case and Condition")) ///
      ylabel(, angle(0)) ///
      ytitle("Percent") ///
      legend(order(1 "Fulfillment" 2 "Justice")) ///
      saving(figure_pilot_4_1, replace)
   graph export figure_pilot_4_1.pdf, replace

graph bar (mean) diff_cons ratio_cons, over(dim) ///
      by(case, cols(3) title("Rule Consistency by Case and Condition")) ///
      ylabel(, angle(0)) ///
      ytitle("Mean Consistency") ///
      legend(order(1 "Difference-Consistent" 2 "Ratio-Consistent")) ///
      saving(figure_pilot_4_2, replace)
   graph export figure_pilot_4_2.pdf, replace


/* analyze choices and generate bar charts */
preserve
   
   collapse (sum) diff_cons ratio_cons diff_s ratio_s, by(id dim)
   
   tab dim
   summ diff_cons ratio_cons diff_s ratio_s, detail
   
   
   /* difference vs. ratio within each condition */
   by dim, sort: summarize diff_cons ratio_cons
   
   ttest diff_cons == ratio_cons if dim == 0
   signrank diff_cons = ratio_cons if dim == 0
   
   ttest diff_cons == ratio_cons if dim == 1
   signrank diff_cons = ratio_cons if dim == 1
   
   
   /* fulfillment vs. justice */
   ttest diff_cons, by(dim)
   
   ttest ratio_cons, by(dim)
   
   ttest diff_s, by(dim)
   ttest ratio_s, by(dim)
   
   
   /* strategy types */
   gen strategy = .
      replace strategy = 1 if diff_cons > ratio_cons
      replace strategy = 2 if ratio_cons > diff_cons
      replace strategy = 3 if diff_cons == ratio_cons
   
   label define strategy_lb 1 "Difference-Oriented" ///
                            2 "Ratio-Oriented" ///
                            3 "Mixed or Unclear"
      label values strategy strategy_lb
   
   tab strategy
   tab strategy dim, col chi2
   
   
   /* difference-consistent vs. ratio-consistent choices by condition */
   graph bar (mean) diff_cons ratio_cons, over(dim) ///
         legend(order(1 "Difference-Consistent" 2 "Ratio-Consistent")) ///
         ylabel(, angle(0)) ///
         ytitle("Mean Number of Consistent Responses") ///
         title("Choice Consistency by Condition") ///
         saving(figure_pilot_4_3, replace)
      graph export figure_pilot_4_3.pdf, replace
   
   
   /* strategy types by condition */
   graph bar (percent), ///
         over(strategy, label(angle(45))) ///
         over(dim) ///
         stack ///
         ylabel(, angle(0)) ///
         ytitle("Percent") ///
         title("Strategy Types by Condition") ///
         saving(figure_pilot_4_4, replace)
      graph export figure_pilot_4_4.pdf, replace
   
restore


/* compute normalized scales */
bysort id: egen s1_min = min(s1)
bysort id: egen s1_max = max(s1)

gen s1_norm = .
   replace s1_norm = (s1 - s1_min) / (s1_max - s1_min) if s1_max > s1_min

bysort id: egen s2_min = min(s2)
bysort id: egen s2_max = max(s2)

gen s2_norm = .
   replace s2_norm = (s2 - s2_min) / (s2_max - s2_min) if s2_max > s2_min

drop s1_min s1_max s2_min s2_max


/* analyze normalized scales and generate bar chart */
forvalues i = 1/6 {
   di "Case `i': A vs. B"
   ttest s1_norm == s2_norm if case == `i'
}

preserve
   
   keep id case dim s1_norm s2_norm
   
   rename s1_norm scorea
   rename s2_norm scoreb
   
   reshape long score, i(id case dim) j(family) string
   
   collapse (mean) score, by(dim case family)
   
   list, sepby(dim case)
   
   
   /* mean normalized judgment */
   graph bar (mean) score, ///
         over(family) ///
         over(case) ///
         by(dim, cols(2) ///
         title("Normalized Judgments by Case and Condition") ///
         note("")) ///
         ylabel(, angle(0)) ///
         ytitle("Mean") ///
         saving(figure_pilot_4_5, replace)
      graph export figure_pilot_4_5.pdf, replace
   
restore
