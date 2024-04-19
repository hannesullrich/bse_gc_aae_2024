/* Fisher Exact Example Application

Setting:

We want to examine the effect of an additional teacher in two classrooms (out of 10), which have 30 students each. Note that this could be anything else, in a nutshell you have 10 groups of 30 participants each and two groups receive treatment.

This code does the following

Section 1: 
generates a dataset with 10 classes of 30 students each, which normal ability, class-level shocks and individual error - all normally distributed.
Two classes get treated (i.e. extra teacher).
Test scores are a simple linear combination of all these factors.
This is your sample, so you can run a regression and estimate the effect of the treatment on test scores.

Section 2:
This section generates all possible combinations of two classes out of 10 (there are 90)

Section 3:
Merges these combinations back to the student data to compute a treatment effect under the sharp null for each case. The drops duplicate cases.

Section 4:
Given this full distribution of the betas, what is the Fisher-exact p value to reject that the treatmant has no effect on no-one? This is your job!
*/

cd ".."


**Section 1 


*generate students in classes dataset with random assignment at class level

set seed 101 

clear
set obs 10
g class_id=_n

g class_shock=rnormal()

expand 30

g ability=rnormal()

g error= rnormal()

g treatment=(class_id<=2)

g test_score= ability + 0.8*treatment + class_shock + error

reg test_score treatment, robust

reg test_score treatment, cluster(class_id)
*beta 1.200143 

sa class_example.dta, replace



**Section 2 


* now implement fisher inference with treatment (2 out of 10) at the class level

u class_example.dta, clear
 
duplicates drop class_id, force
keep class_id

permin class_id, k(2)						///this is a handy command to generate all possible combinations, here two our of all class_id

g perm_n=_n

sa perm.dta, replace



**Section 3 

*Now we are set to run the actual permutations

u perm.dta, clear

cap matrix drop beta						//this will be the matrix to store the estimates

forval p=1/90 {

u perm.dta, clear
keep in `p'

g n=1

reshape long class_id_, i(n) j(treatment)

ren class_id_ class_id

merge 1:m class_id using class_example.dta

g treat_perm=(_merge==3)

qui reg test_score treat_perm

matrix beta=nullmat(beta) \ e(b)			// append new betas to matrix
}
	
clear

svmat beta		

duplicates drop								//this drops exact duplicates -because we did AB and BA combinations of treatments but only need one of these. There are probably more elegant ways of donig this



sum beta1



**Section 4 

*Exercise: given this distribution of the betas under the sharp null, what is the Fisher exact p-value? Compare this to the results you got in the beginnig and comment.




