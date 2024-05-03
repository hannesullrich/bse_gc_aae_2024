////////////////////////////////////////////////
// Solution Exercise Week 2
// Panel Data
// NLS Wooldridge (young men 1980 - 1987)
////////////////////////////////////////////////

clear all

// in part g) we will have several hundred regressors (dummies for each nr)
// to allow for this we need to have a maximum matrix size that exceeds the number
// of regressors in g). Not all versions of Stata support this.

cd "C:\Users\FW\Dropbox\0X_Teaching\000_Viadrina\2023_24\AdvancedAppliedEconometrics(BSE)\week2\exercise"

cap log close
log using "exercise_panel_sol.txt", replace text

import excel "marriage-data-excel.xlsx", sheet("Tabelle1") firstrow

sa "marriage-data.dta", replace


u "marriage-data", clear

d

u "background-data", clear

d

u "experience-data", clear

u "wage-data", clear

d

///////////
// a)
///////////

reshape long lwage, i(nr) j(year)

sort nr year

merge 1:1 nr year using "marriage-data"

drop _merge

merge 1:1 nr year using "experience-data"

drop _merge

merge n:1 nr using "background-data"

drop _merge

d

sum

save "data-exercise-panel-nls", replace

///////////
// b)
///////////

xtset nr year
// the panel is balanced, i.e. we have the same number of years for each individual

///////////
// c)
///////////

reg lwage married
// The data suggests a huge marriage premium of 22%, i.e. on average married men earn 22% more than non married men.
// Why should wages differ?
// productivity differs: married men are more productive than unmarried men.
//	this might be due to marriage itself or other unobserved factors

///////////
// d)
///////////

reg lwage married exper union educ black hisp
// Including other characteristics halves the estimate for the marriage premium, ceteris paribus
// the premium is now 11.3%. This means that men with characteristics that imply a higher wage
// are also more likely to be married, e.g. men with more experience.

///////////
// e)
///////////

xtreg lwage married exper union educ black hisp, fe
// Running person fixed effects halves the estimate again, now the premium is
// 6.1%, so unobserved effects are positively correlated with wages and
// the probability of being married.
// educ, black and hisp are dropped from our model because they are perfectly colinear
// with the fixed effects. Fixed effects means we use variation "within" individual,
// i.e. only variation of changes over time, race and education do not change in our
// sample and so coefficients for them cannot be identified.

///////////
// f)
///////////

xtreg lwage married exper union, fe cluster(nr)
// So far our standard errors were correct if the error variance is homoscedastic
// (i.e. the same for each person at each point in time). To allow for arbitrary
// correlation over time for each individual we can use clustered standard errors.
// Standard errors increase (they usually do) but the estimated coefficient for
// married is still significant at the 5% (and the 1%) level.

///////////
// g)
///////////

reg lwage married exper union i.nr, cluster(nr)
// Stata needs to invert a large matrix. Inverting is time and memory consuming.
// The point estimates are the same, the standard errors differ slightly.
// The reason is the small sample correction. When using clustered standard errors
// and the individuals are somehow nested  within clusters (i.e. each individual
// belongs to one cluster) then we do not need to adjust for the absorbed fixed effects
// when calculating the standard errors. xtreg,fe accounts for this, the standard regression
// does not. Note: you can run xtreg with the dfadj option which will conduct the degrees
// of freedom adjustment although it wouldn't be necessary.
// If you do this the standard errors will be the same.

///////////
// h)
///////////

xtreg lwage married union i.year, fe cluster(nr) dfadj
// We can no longer use experience as a regressor. So far we could keep everything that varied
// over time, now including time dummies means that we also control for trends and only
// variation from the general trend is left. Since we have individual dummies in our model that means
// constant changes of a variable will be captured by the trend. Experience
// changes over time, but this change is constant, each year experience increments
// by one i.e. the men in our sample worked in every year that we observe them.
// If we do not omit experience from our list of regressors Stata will drop one of
// the time dummies, we might be tempted to interpret the coefficient on experience,
// but it will not have a significant meaning.
// Controlling for trends does not alter the marriage premium's point estimate, but the p-value is
// now 0.011, which means we can no longer reject the H0 that the premium is 0 at the 1% level.

///////////
// i)
///////////

replace married = married * (-1)
// we use a trick to pick out the year when a man in our sample first got married
// 1. we change the marriage dummy such that when we sort the data by marriage, the
//	married observations will be the first

bysort nr (married year): gen divorced = (year[1] < year[_N] & married[1] == -1 & married[_N] == 0)
// 2. we apply a command for each man in our sample using the bysort prefix
//	for each man we sort the data by marriage status and year, the smallest values
//	will come first so for married men the first value of marriage will be -1, for
//	men who never got married it will be 0 the year of the first observation will be the
//	year we first observe someone as married. The last year will be the last year someone was not
//	married. So all we need to do is check whether the last year in the sort order is greater than
//	the first year in the sort order and at the same time someone was married at some point and not
//	married at another.

replace married = married * (-1)
// 3. we change the marriage dummy back

tab divorced
di 568/8
// There are 71 men in our sample who get divorced.

xtreg lwage married union i.year if divorced == 0, fe cluster(nr)
// Excluding the divorcees does not affect the coefficient estimate but the standard errors
// increase some more and now the p-value is 0.022, so again the coefficient is statistically
// significant at the 5% but not at the 1% level.


log close
