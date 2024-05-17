*modify the global with your folder structure
global folder "C:\Users\FW\Dropbox\0X_Teaching\000_Viadrina\2023_24\AdvancedAppliedEconometrics(BSE)\week4\examhomework"

set more off
clear all

capture log close 					// closes any previously open log-file
log using "$folder/PS_examhomework1_log",  replace	// start a new log file

*for nicer layout of the graphs
set scheme s1mono


************
* Problem 1:
************

use "$folder/did_data", clear

* (i)
* First, focus on the variable y instant. Estimate the treatment effect, controlling for unit
* and time fixed effects y_it = alpha_t + delta_i + beta x post x treated. What exactly does beta 
* estimate? How would you calculate the standard errors? Plot the means of the outcome over time, 
* split by treatment group.


areg y_instant i.time_id i.post##c.treated_group, cluster(ids) absorb(ids)

*TE: 1.06 (SE: 0.129)


* Beta estimates the differential pre-post difference, over and above the pre-post difference in the 
* control group (the diff-in-diff).
* We have to cluster the standard errors to account for serial correlation of the error terms. The 
* standard errors should be clustered at the level of randomization, in this case at the individual unit.

binscatter y_instant time_id, discrete by( treated_group ) line(connect) xline(4.5)
graph export "$folder/y_instant1.png", replace

* (ii)
* Now, we want to estimate the dynamic effects for this outcome. Write down the regression
* equation for the event study diff-in-diff specification (controlling for unit and time fixed effects).
* Estimate the effect of the treatment relative to time period 4, for all time periods. Plot these
* coefficients, and report the estimate and standard error in period 6. How do you interpret the
* coefficient plot with regard to the parallel trend assumption and dynamic treatment effects?

*The event study diff-in-diff regression is specified as follows:
* y_it = alpha_t + delta_i + \sum_t alpha_

areg y_instant b4.time_id##i.treated_group , cluster(ids) absorb(ids)
est store x1

di _b[6.time_id#1.treated_group]
di _se[6.time_id#1.treated_group]

* b= 1.044
* se= 0.220

coefplot x1, keep(*.time_id#*.treated_group) vertical base coeflabels(, truncate(10) wrap(5)) yline(0, lcolor(red)) xline(4.5, lpattern(dash))
graph export "$folder/y_instant2.png", replace

* By visual inspection, we observe parallel pre-trends since the coefficients of the leads are close to 
* zero and insignificant. We observe an instant treatment effect at time=5, which does not strongly
* vary significantly over the post-treatment periods. 


* (iii)
* How does your point estimate from part (i) with the same specification compare to taking
* the simple average of the dynamic coefficients from the regression in part (ii)? (Hint: Do not forget
* to include the reference time period when taking the average of the pre-treatment coefficients.)


* We can sum up the treatment effects in the post periods and subtract from it the pre-treatment coefficients
* (by accessing the coefficients from the coefficient matrix).

areg y_instant b4.time_id##i.treated_group , cluster(ids) absorb(ids)

matrix list e(b)
di  ((e(b)[1,32] + e(b)[1,30] + e(b)[1,28] + e(b)[1,26] + e(b)[1,24] + e(b)[1,22])/6 -  (e(b)[1,20] + e(b)[1,18] + e(b)[1,16] + e(b)[1,14]) /4)

* The average of the coefficients is 1.061, which is numerically equivalent to the post-coefficient from (i).



* (iv)
* Now estimate the effect of the treatment relative to time period 3. How do the estimates
* change? Use the coefficient plot to explain why.

* We can change the reference period to period 3 by specifying "b3" in factor notation:

areg y_instant b3.time_id##i.treated_group , cluster(ids) absorb(ids)

* We observe that the treatment effects in all periods are slightly larger, which is due to the fact that 
* the outcome has a lower mean in period 3 (which can be inferred from the coefficient plot). Since the 
* post-treatment coefficients are estimated relative to this lower reference category, they are all mechanically larger.


* (v)
areg y_instant post##treated_group i.time_id, a(ids)
* 1.061346   .0881791
areg y_instant post##treated_group i.time_id, a(ids) robust
 *1.061346    .088991  allowing for heteroskedasticity does not do much, slightly larger errors
areg y_instant post##treated_group i.time_id, a(ids) cluster(treated_group)
* 1.061346   8.19e-13 
*only two clusters so error is too small


* (vi)
*No


*Bonus: notice that we have a single time when the treatment switches. This is why we only have one did. for multipe periods the following command plots coefficients and weights for each did comparision

 g treat_id=(treated_group==1 & post==1)
 xtset ids time_id
 bacondecomp y_instant treat_id
 
 

************
* Problem 2:
************

*q1
*good students attend good schools so naive comparisions across schools will geneate large positive estimates of peer effects
*hoxby strategy that includes school FX leverages variation over time in peer quality and arguably ocurrs randomly because of small draws from a local population. key assumption is that any sorting to schools is constant over time_id- 

*q2
*Lavy et al relax assumption of constant sorting over time and replace this with assumption of constant sorting across subjects.  treatment is if peers happen to be better in any particualr subject relative to the others and how this affects own relative subject performance.as always, being good/bad is measured from previous test scores where peers mostly went to different schools. assumption could be violated is there is subject-specific sorting to schools. moreover, this setup assumes peer effects to be subject-specific and homogeneous across subjects

*q3 
*as stated above we are concerned about potential subject specific sorting to schools that could generate suprious estimates through correlations between own relative performacne and peer relative performance. this figure estimates the peer effect separately for students with different within-individual variation in across subject performance. the rationale for this is that students who are equally good in all subjects cannot sort to school based on subject-preferences shared with future peers in the same way as students who are better in, say, math relative to english. the figuer shows that the main estimate is insensitive to changes in the wihtin-student variaion in past subject performance -> this makes stories of subject specific sorting very unlikely to be driving estimates



 
 
************
* Problem 3:
************

*Q1 
* Good answers will piont out that the estimate in column 4 is "surprising" and at odds with the standard result that adding irrelevant controls has no effects on the estimated coefficients. Examinatino of the data generating process explains what is going on: OLS assumes constant variance in regressors, i.e. not just independence but also identicall distributions (i.i.d). In this example, we have W correlating with strata 2 but not 1. If the assumption of identically distributed regressors is violated, OLS will weight the estimate towards the obervatiosn with higher (conditional) variation in X. If these individuals/groups that have higher variation in X happen to have different treatment effects (as is the case here), the OLS estimate will be shifted in this direction. Bottom line: similar varation in treatment across groups is critical when treatment effects are heterogeneous. This is violated whenever controls are added that do not correlate similarly across tretament strata, such as W.

*Q2
*Oster bounds 

run "$data/ohmygod.do"
psacalc beta X1

*under proportional selection and with R2 max=1 beta is bounded between 0.343 and 4.914. Good news! Note: this result mostly comes from the large R2 of the regressions. But really this is not good news since we happen to know that the control should not be included in the first place. The application of Oster is non-sensical (see Q3)

*Q3
*Oster method assumes either homogeneous effects or constant (conditional) variance in regressors, therefore coefficient movements cannot be interpreted as bounding bias. In this example do-file we know that the unconditional estimate was already unbiased and consistent.
*Best answers would consider general implications of this for the interpretation of coefficient movements across OLS spüecifications with different sets of controls, or for varaible selection routines that are based on statistical signficiance or mea squared errors (lasso machine learning)

 
 
 
 
 
 