*modify the global with your folder structure
global folder ".../ExerciseDiD"

set more off
clear all

capture log close 					// closes any previously open log-file
log using "$folder/PS_Did_log", text replace	// start a new log file




************
* Problem DiD:
************

use "$folder/sodasales", clear

* (i)
* Calculate the difference-in-difference estimate of the introduction of the tax 
* on soft drink sales based on these means (i.e. not using regression analysis). 
* Are the findings consistent with economic theory?


* First, we calculate the average sales by treatment group and pre/post period
* and save them as locals.

* Sales in treatment group/pre period
sum sales1 if treat==1 & post==0
local pre_t=r(mean)
* Sales in treatment group/post period
sum sales1 if treat==1 & post==1
local post_t=r(mean)
* Sales in control group/pre period
sum sales1 if treat==0 & post==0
local pre_c=r(mean)
* Sales in control group/post period
sum sales1 if treat==0 & post==1
local post_c=r(mean)

* To get the DiD estimate, we subtract the control group pre-post difference
* from the treatment group pre-post difference.

di (`post_t' - `pre_t') - (`post_c' - `pre_c') 

* The DiD estimate is -3.426. Sales in the treatment group decreased by 3.426 units
* more than in the control group. Assuming parallel trends, this estimate means that
* the tax introduction led to a decline in sales by 3.426 units, which is in line with 
* a negative demand elasticity.

* (ii)
* Write down the regression equation (do not forget to define the variables). Estimate the
* model using Stata and interpret the regression output.


* Alternatively, we can estimate the DiD using the following regression model:

* y_it = beta_0 + beta_1 * post_t + beta_2 * treat_i + beta_3 * post_t * treat_i + epsilon_it

* where the interaction beta_3 identifies the DiD.
* Moreover, the constant beta_0 is the mean in the control group, beta_1 is the pre-post difference
* in the control group, beta_2 is the pre-treatment difference between treatment and control group.

reg sales1 i.post##i.treat, cluster(state)

* The coefficient is numerically identical (-3.426), but now we also get a standard error for 
* the treatment effect.

* We can also plot the DiD:

binscatter sales1 post, by(treat) discrete


* (iii)
* What are the assumptions you need to make so that the difference-in-difference estimator 
* identifies the causal impact of the introduction of the tax? What are potential threats to estimating
* the causal effect of the tax on sugar consumption?


* 1. Common trend assumption: If there was no treatment, the change in the outcome variables
* would be the same for the treatment and control group. More specifically, we need to assume
* that stores in the treated and control regions would have followed the same trends in sales if there
* was no tax introduced.

* 2. Moreover, one needs to assume that there are no spillovers between treatment and control group (SUTVA),
* which could be violated if there are changes in the composition of the treatment and
* control group. If we are interested in the consumption of soda in the treated region, we need to
* assume e.g. that cross-border shopping has not increased due to the tax. If more consumers in the 
* treated regions purchased soft drinks in the control regions in reaction to the tax, we would 
* overestimate the effectiveness of the tax in reducing consumption.

* 3. Finally, we need to exclude general equilibrium effects. For example, if the demand drop in
* the treated regions has (differentially) decreased (factor) prices and thereby increased purchases in
* the control regions, this could bias the treatment effect of the tax.


* (iv)
* How do you calculate your standard errors in this setting and why? Do your standard
* errors differ if you calculate robust standard errors instead?


* We have to cluster the standard errors at the level of treatment assignment, that is, at the state level
* in this example. Thereby, we control for serial correlation in the error terms over time.

* If we computed robust standard errors, we would not take the serial correlation into account and maintain the
* iid assumption:

reg sales1 i.post##i.treat, r

* Note that the standard errors are smaller (less conservative) if we used robust standard errors. However, 
* Bertrand et al. (2005) have shown that not taking serial correlation into account leads to overrejection
* of the null hypothesis in DiD settings.
* NB: You may want to read Abadie, Athey, Imbens, Wooldridge (2023, QJE) for a formal introduction in which
* situations and on what level you should cluster your standard errors. The review article by Roth, Sant'Anna,
* Bilinski and Poe (2022) also offers a good overview specific to DID settings.


* (v)
* The variable sales2 measures the sales of bottled water from these stores. Assuming no
* substitution between soda and water, write down the DDD regression equation that you could
* estimate. Estimate the DDD regression model using Stata and interpret each of the coefficients.
* (Hint: You have to reshape the data first.) 


* We can combine the spatial control group and the bottled water control group in a difference-in-
* difference-in-difference setup by using the fully interacted model:

* y_ijt = beta_0 + beta_1 * post_t + beta_2 * treated_region_i + beta_3 * treated_product_j
*		+ beta_4 * treated_product_j * treated_region_i + beta_5 * post_t * treated_region_i
*		+ beta_6 * treated_product_j * post_t + beta_7 * treated_product_j * treated_region_i * post_t 
*		+ epislon_ijt

* This model includes fixed effects to control for time-region specific shocks (which are common for soft drinks 
* and bottled waters) and time-product specific shocks (which are common across regions). We also control for
* time-invariant product differences across regions. 
* In the DiD setup before, we only could allow for a time fixed effect that is common across regions and a region 
* specific effect that does not vary over time.

* The interpretation of the coefficients is as follows:
* beta_0: Mean sales of bottled water in the control region in the pre-period
* beta_1: Pre-post difference in sales of water in control region
* beta_2: Difference in sales of water between regions in the pre-period
* beta_3: Difference between mean sales of water and soda in the control region in the pre-period
* beta_4: The pre-tax difference in sales between soda and water in the treated states (over and
*		  above the difference in the control states).
* beta_5: The differential change in water sales over time in the treated states (over and
*		  above the change over time in the control states): the "placebo DiD".
* beta_6: The differential change in soda sales over time in the control region (over and above
*		  the change over time in water sales in the control region).
* beta_7: The DDD estimate: the differential DiD treatment effect of the tax for soda sales (over and above the DiD
*		  treatment effect for water sales).


* To estimate the DDD, we first have to reshape the data into a "long" format that takes into account the two product
* categories (the data is already in long format with respect to time but not with respect to the product categories).

reshape long sales, i(state store_id post) j(product)

* The reshape command generates a new variable called "product" that takes on 1 for soda and 2 for water (in accordance 
* with the suffixes of the variable sales).
gen soda = 0 if product==2
replace soda = 1 if product==1

* Run the DDD as the fully interacted model of post, treatment and product dummy:
reg sales i.post##i.treat##i.soda, cluster(state)

* The triple interaction coefficient gives the DDD estimate: -3.525, which is very similar to the DiD estimate above. The reason 
* is that the "placebo" DiD for the control product (water) is not significantly different from zero (-0.099). Subtracting
* the latter coefficient from the DDD estimate gives the initial DiD estimate (-3.426). 

* Instead of showing the DDD (very "data hungry") you could also consider showing the DiD for water as a "placebo check" to
* argue that there are apparently no general trends in beverage purchase behavior coinciding with the tax change:
reg sales i.post##i.treat if soda==0, cluster(state)



* How would this estimate be biased if consumers do in fact substitute in reaction to the tax?

* A concern with using water as a control group is that consumers substitute from soda to water in response to the tax. 
* In that case, the SUTVA would be violated since the control group (water) is affected by the treatment. In our setting, we 
* assume that water sales can be used as a counterfactual for soda sales absent the tax change. But if the tax leads to an 
* increase in water sales, our estimate of the counterfactual is biased upwards and our DiD would overestimate the effect of the
* tax on soda sales.
