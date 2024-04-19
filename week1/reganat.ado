* Version 1.2. September 12th, 2012
* Author: Valerio Filoso

program define reganat
		version 10.1
		syntax varlist [if] [in] [aw fw pw iw/] [, Dis(varlist) Label(varname) BIScat BILine Reg NOLegend NOCovlist Scheme(string) Fwl SEMip]

		preserve
		tokenize `varlist'
		local dependent `1'
		mac shift
		local independent `*'
		set graphics off

		* --------------------------------------------------------------------------------------	
		* Variables to plot
		* --------------------------------------------------------------------------------------	
		if "`dis'" == "" {
			local tobep = "`independent'"
		}
		else {
			local tobep = "`dis'"
		}
		
		* --------------------------------------------------------------------------------------	
		* Header: General information to be displayed
		* --------------------------------------------------------------------------------------	
		display " "
		display as text "Regression Anatomy"
		display as text "{hline 78}"
		display as text "Dependent variable ...... : " as result "`dependent'"
		display as text "Independent variables ... : " as result "`independent'"
		display as text "Plotting ................ : " as result "`tobep'"
		if "`label'" != "" {
			display as text"Label variable: `label'" 
		}

		* --------------------------------------------------------------------------------------	
		* Displaying the multivariate model, if requested
		* --------------------------------------------------------------------------------------	
		if `"`reg'"'!="" {
			regress `varlist' `if' `in' 
		}

		* --------------------------------------------------------------------------------------	
		* Calculating semipartial correlation coefficient, if required
		* --------------------------------------------------------------------------------------	
		if "`semip'" != "" {
			pcorr `varlist' `if' `in'
			matrix spc = r(sp_corr)
			local spc_sum = 0
			local dimension = rowsof(spc)
			forvalues y = 1 (1) `dimension' {
				local spc_sum = `spc_sum' + spc[`y',1]^2
			}
			display as text " "
			display as text "Model's variance decomposition                            Value          Perc."
			display as text "{hline 78}"
			cap: reg `varlist' `if' `in'
			local common_v = e(r2) - `spc_sum'
			local idiosy_p = `spc_sum' / e(r2)
			local common_p = `common_v' / e(r2)
			display as text "Variance explained by the X's individually              " as result %7.4f `spc_sum' "        " as result %7.4f `idiosy_p'
			display as text "Variance common to X's                                  " as result %7.4f `common_v' "        " as result %7.4f `common_p'
			display as text "{hline 78}"
			display as text "Variance explained by the model (R-squared)             " as result %7.4f e(r2)
		}
		
		
		* --------------------------------------------------------------------------------------	
		* Size of marker in scatterplot
		* --------------------------------------------------------------------------------------	
		cap: count `if' `in'
		if r(N) > 500 {
			local size = "tiny"
		}
		else {
			local size = "small"
		}

		* --------------------------------------------------------------------------------------	
		* Extraction of variables' labels 
		* --------------------------------------------------------------------------------------	
		local lbldepvar : variable label `dependent'
		if "`lbldepvar'" == "" {
			local lbldepvar = "`dependent'"
		}

		* --------------------------------------------------------------------------------------	
		* A string with the list of controls
		* --------------------------------------------------------------------------------------	
		cap: local stringa = ""
		foreach x of local independent {
			local etichetta : variable label `x'
			if "`etichetta'" == "" {
				local etichetta = "`x'"
			}
			local stringa = "`stringa', `etichetta'"
			}  
		local stringa = substr("`stringa'",2,.)

		* --------------------------------------------------------------------------------------	
		* Markers for observations in the scatterplot, if selected
		* --------------------------------------------------------------------------------------	
		if "`label'" == "" {
			local etich = ""
		}
		else {
			local etich = "mlabel(`label') mlabsize(tiny) mlabposition(9) msize(`size')"
		}

		cap: macro drop totvar
		local totvar = 0 

		* --------------------------------------------------------------------------------------	
		* Preparing the graphs for each variable to be printed
		* --------------------------------------------------------------------------------------	
		foreach x of local tobep {

			local totvar = `totvar' + 1
			local lblx : variable label `x'

			if "`lblx'" == "" {
				local lblx = "`x'"
			}

			local covariates = subinword("`independent'","`x'","",1)
			
			* Preparing x-tilde, according to Regression anatomy theorem
			cap: regress `x' `covariates' `if' `in'
			cap: predict resid_`x' `if' `in', residuals
			label variable resid_`x' "`x'"

*			* Displaying regression results, if required
*			if `"`reg'"'!="" {
*				regress `varlist' `if' `in' 
*			}
	
			* Dropping all the missing obs
			cap: keep if e(sample)

			* Subtracting the relevant mean
			cap: summarize `x'
			cap: gen `x'_std = `x'-r(mean)

			* Generate regression parameters estimates
			cap: regress `dependent' `independent' `if' `in'
			local beta = string(_b[`x'],"%9.3f")
			local sebeta = string(_se[`x'],"%9.3f")

			cap: regress `dependent' `x' `if' `in'
			local betab = string(_b[`x'],"%9.3f")
			local sebetab = string(_se[`x'],"%9.3f")

			cap: regress `dependent' resid_`x' `if' `in'
			local spc = string(e(r2),"%9.3f")
			
			* In case the user requires the FWL version
			if `"`fwl'"'!="" {
				cap: regress `dependent' `covariates' `if' `in'
				cap: drop r_`dependent'_`x'
				cap: drop y_buffer
				cap: predict r_`dependent'_`x', residuals
				cap: generate y_buffer =  `dependent'
				cap: replace `dependent'= r_`dependent'_`x'
				local addition " (FWL version)"
			}
	

			* Scatterplots

		* --------------------------------------------------------------------------------------	
		* Adding the bivariate scatterplot
		* --------------------------------------------------------------------------------------	
			if `"`biscat'"'!="" {
				local biscat "(scatter `dependent' `x'_std `if' `in', `etich' msymbol(triangle))"
				local legscat "Scatterplot: Dots = Transformed data, Triangles = Original data."
			}

		* --------------------------------------------------------------------------------------	
		* Adding the bivariate regression line
		* --------------------------------------------------------------------------------------	
			if `"`biline'"'!="" {
				local capt "caption(`"Bivariate slope: `betab' (`sebetab')"', bexpand justification(left) size(small))"
				local biline "(lfit `dependent' `x'_std `if' `in', lwidth(medium) lpattern(dash) caption(`"Bivariate slope: `betab' (`sebetab')"', size(small) justification(left)) note("Multivariate slope: `beta' (`sebeta'). Semipartial rho2: `spc'", justification(left) size(small)))"

				* --------------------------------------------------------------------------------------	
				* Adding or removing the legend
				* --------------------------------------------------------------------------------------	
				if `"`nolegend'"'=="" {
					local note "caption(`"Regression lines: Solid = Multivariate, Dashed = Bivariate."' "`legscat'", size(small) alignment(middle) position(6) justification(center) box bexpand bmargin(medlarge) span)"
				}
				else {
					local note ""
				}
			}


		* --------------------------------------------------------------------------------------	
		* Preparing the single graphs, with several options
		* --------------------------------------------------------------------------------------	
			scatter `dependent' resid_`x' `if' `in', xtitle("") ytitle("") `etich' xsca(titlegap(2)) ylabel(minmax) xlabel(minmax, nogextend) ymtick(##5) xmtick(##5) ///
			name(`x', replace) legend(off) title("`lblx'", span) || ///
			lfit `dependent' resid_`x' `if' `in', lpattern(solid) lwidth(medium)  xlabel(, labsize(vsmall)) ylabel(, labsize(vsmall)) ///
			note("Multivariate slope: `beta' (`sebeta'). Semipartial rho2: `spc'", bexpand justification(left) size(small)) || ///
			`biline' || ///
			`biscat'
			
		* In case the user required the FWL option, restore the original values of y	
			if `"`fwl'"'!="" {
				cap: replace `dependent' = y_buffer
				cap: drop y_buffer
			}
			
		* This closes the loop over independent variables
			}

		* --------------------------------------------------------------------------------------	
		* Adding or removing the list of covariates
		* --------------------------------------------------------------------------------------	
			if `"`nocovlist'"'=="" {
				local covlist "note("Covariates: `stringa'.", bexpand size(medsmall) justification(center) alignment(middle))"
			}
			else {
				local covlist ""
			}

		* --------------------------------------------------------------------------------------	
		* Defining the composite graph's style
		* --------------------------------------------------------------------------------------	
			if `"`scheme'"'!="" {
				local schema "`scheme'"
			}
			else {
				local schema "sj"
			}

		* --------------------------------------------------------------------------------------	
		* Building up the composite graph
		* --------------------------------------------------------------------------------------	
		set graphics on
		graph combine `tobep', ///
		title("Regression Anatomy`addition'", span) subtitle("Dependent variable: `lbldepvar'", span) ///
		`covlist' ///
		`note' ///
		`nota' ///
		scheme(`schema') commonscheme

		restore
end
