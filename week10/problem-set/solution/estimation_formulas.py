import numpy as np


def ols_formula(y, x):
    """This function calculates the OLS estimates and standard errors.

    Parameters
    ----------
    y (np.ndarray):
        Dependent variable. Shape is (num_markets * num_products).
    x (np.ndarray):
        Independent variables. Shape is
            (num_markets * num_products, num_independent_variables).

    Returns
    -------
    coeffs (np.ndarray):
        OLS estimates. Shape is (num_independent_variables,).
    std_errors (np.ndarray):
        Standard errors. Shape is (num_independent_variables,).
    """
    inverse_covars = np.linalg.inv(x.T @ x)
    # OLS estimator formular
    coeffs = inverse_covars @ (x.T @ y)

    # Now estimation of standard errors
    projection = x @ coeffs

    residuals = y - projection
    squared_sum_residuals = residuals @ residuals

    degrees_of_freedom = x.shape[0] - x.shape[1]
    covariance_est = (squared_sum_residuals / degrees_of_freedom) * inverse_covars
    std_errors = np.sqrt(np.diag(covariance_est))
    return coeffs, std_errors


def two_sls_formula(y, x, z):
    """This function calculates the 2SLS estimates and standard errors.
    Parameters
    ----------
    y (np.ndarray):
        Dependent variable. Shape is (num_markets * num_products).
    x (np.ndarray):
        Independent variables. Shape is (num_markets * num_products, num_independent_variables).
    z (np.ndarray):
        Instrumental variables. Shape is (num_markets * num_products, num_instrumental_variables).

    Returns
    -------
    coeffs (np.ndarray):
        2SLS estimates. (Shape is (num_independent_variables,))
    std_errors (np.ndarray):
        Standard errors. (Shape is (num_independent_variables,))
    """
    # Step 1: 2SLS (homoscedastic errors), "weighting matrix" W=inv(Z'Z)
    degrees_of_freedom = x.shape[0] - x.shape[1]

    norm = np.mean(np.mean(z.T @ z))
    weight_matrix = np.linalg.inv((z.T @ z) / norm) / norm

    projection_matrix = z @ weight_matrix @ z.T
    coeffs = np.linalg.inv(x.T @ projection_matrix @ x) @ x.T @ projection_matrix @ y

    residuals = y - x @ coeffs
    squared_sum_residuals = residuals.T @ residuals

    inverse_covariates = np.linalg.inv(x.T @ projection_matrix @ x)
    estimator_cov = (squared_sum_residuals / degrees_of_freedom) * inverse_covariates
    std_errors = np.sqrt(np.diag(estimator_cov))

    return coeffs, std_errors
