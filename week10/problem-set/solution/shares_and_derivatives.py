import functools
import scipy
import numpy as np


def compute_bertrand_prices(df, params, quad_draws, quad_weights):
    """Computes Bertrand-Nash prices for all products in all markets.

    Args:
        df (pandas.DataFrame): DataFrame of simulated data for products containing
            observable and unobservable product characteristics, prices, costs, and
            marginal costs.
        params (dict): Model parameters.
        quad_draws (np.ndarray): 1d array of shape (n_quad_points,)
            containing the Hermite quadrature points.
        quad_weights (np.ndarray): 1d array of shape (n_quad_points,)
            containing the associated Hermite quadrature weights.

    Returns:
        numpy.ndarray: 1d array of shape (num_markets * num_products,) containing the
        Bertrand-Nash prices for all products in all markets.
    """
    num_markets = len(df.index.get_level_values("market").unique())
    num_products = len(df.index.get_level_values("product").unique())

    # Create partial function that fixed all arguments except price.
    get_prices = functools.partial(
        supply_foc,
        params=params,
        x_0=df["obs_char_0"].to_numpy(),
        x_1=df["obs_char_1"].to_numpy(),
        xi=df["xi"].to_numpy(),
        marginal_costs=df["marginal_costs"].to_numpy(),
        num_markets=num_markets,
        num_products=num_products,
        quad_draws=quad_draws,
        quad_weights=quad_weights,
    )
    # Find prices using fixed point algorithm from scipy library.
    start_prices = df["marginal_costs"].to_numpy()
    price_bertrand = scipy.optimize.fsolve(func=get_prices, x0=start_prices)

    return price_bertrand


def supply_foc(
    price,
    params,
    x_0,
    x_1,
    xi,
    marginal_costs,
    num_markets,
    num_products,
    quad_draws,
    quad_weights,
):
    """First order condition for the Bertrand-Nash prices.

    Args:
        price (numpy.ndarray): 1d array of shape (num_markets * num_products,) containing
            the prices for all products in all markets.
        params (dict): Model parameters.
        x_0 (numpy.ndarray): 1d array of shape (num_markets * num_products,) containing
            the first observable characteristic (constant) for all products in all
            markets.
        x_1 (numpy.ndarray): 1d array of shape (num_markets * num_products,) containing
            the second observable characteristic for all products in all markets.
        xi (numpy.ndarray): 1d array of shape (num_markets * num_products,) containing
            the unobservable product characteristics for all products in all markets.
        marginal_costs (numpy.ndarray): 1d array of shape (num_markets * num_products,)
            containing the marginal costs for all products in all markets.
        num_markets (int): Number of markets.
        num_products (int): Number of products.
        quad_draws (np.ndarray): 1d array of shape (n_quad_points,)
            containing the Hermite quadrature points.
        quad_weights (np.ndarray): 1d array of shape (n_quad_points,)
            containing the associated Hermite quadrature weights.
    Returns:
        numpy.ndarray: 1d array of shape (num_markets * num_products,) containing the
            first order conditions for the Bertrand-Nash prices for all products in all
            markets. This is zero if prices are Bertrand-Nash prices.
    """

    # Convert inputs to numpy arrays to speed up the following steps.
    delta = compute_mean_utility(params, x_0, x_1, price, xi)
    shares = compute_shares(
        params=params,
        x_0=x_0,
        x_1=x_1,
        delta=delta,
        num_markets=num_markets,
        num_products=num_products,
        quad_draws=quad_draws,
        quad_weights=quad_weights,
    )
    # Compute matrix of share derivatives.
    shares_flat = shares.reshape(num_markets * num_products)
    share_deriv_inv = _compute_share_derivatives_inv(shares=shares_flat, params=params)

    out = price + (share_deriv_inv @ shares_flat) - marginal_costs
    return out


def compute_mean_utility(params, x_0, x_1, price, xi):
    """Compute the mean utility across consumers for all products in all markets.

    Args:
        params (dict): Model parameters.
        x_0 (numpy.ndarray): 1d array of shape (num_markets * num_products,) containing
            the first observable characteristic (constant) for all products in all
            markets.
        x_1 (numpy.ndarray): 1d array of shape (num_markets * num_products,) containing
            the second observable characteristic for all products in all markets.
        price (numpy.ndarray): 1d array of shape (num_markets * num_products,) containing
            the prices for all products in all markets.
        xi (numpy.ndarray): 1d array of shape (num_markets * num_products,) containing
            the unobservable product characteristics for all products in all markets.

    Returns:
        numpy.ndarray: 1d array of shape (num_markets * num_products,) containing
            the mean utility across consumers for all products in all markets.
    """

    delta = (
        params["beta"][0] * x_0 + params["beta"][1] * x_1 + params["alpha"] * price + xi
    )
    return delta


def compute_shares(
    params, x_0, x_1, delta, num_markets, num_products, quad_draws, quad_weights
):
    """Compute shares by integrating over utilities.

    Args:
        params (dict): Model parameters.
        x_0 (numpy.ndarray): 1d array of shape (num_markets * num_products,) containing
            the first observable characteristic (constant) for all products in all
            markets.
        x_1 (numpy.ndarray): 1d array of shape (num_markets * num_products,) containing
            the second observable characteristic for all products in all markets.
        delta (numpy.ndarray): 1d array of shape (num_markets * num_products,) containing
            the mean utility across consumers for all products in all markets.
        num_markets (int): Number of markets.
        num_products (int): Number of products.
        quad_draws (np.ndarray): 1d array of shape (n_quad_points,)
            containing the Hermite quadrature points.
        quad_weights (np.ndarray): 1d array of shape (n_quad_points,)
            containing the associated Hermite quadrature weights.

    Returns:
        numpy.ndarray: 2d array of shape (num_markets, num_products) containing the
            market shares for all products in all markets.
    """

    # Calculate the shock values to be integrated for each quadrature point and product.
    # Shape is then (num_products * num_markets, num_quad_points).
    mu = np.outer(x_0 * params["sigma"][0] + x_1 * params["sigma"][1], quad_draws)
    # Calculate the exponential of the utility and reshape
    exp_util = np.exp(mu + delta[:, np.newaxis]).reshape(
        num_markets, num_products, quad_draws.shape[0]
    )
    # Calculate shares
    shares = exp_util / (1 + exp_util.sum(axis=1)[:, np.newaxis, :])
    # Weight the shares with the integration weights
    shares_weighted = shares @ quad_weights
    return shares_weighted


def _compute_share_derivatives_inv(shares, params):
    """Compute share derivatives to use in computation of bertrand prices.

    Args:
        params (dict): Model parameters
        shares (np.ndarray): 1d array of shape (num_shares, ) containing the
            market shares for all products in one particular market.

    Returns:
        np.ndarray: 2d array of shape (num_shares, num_shares) with derivatives
            on the diagonal of shares with respect to their own price.
    """
    alpha = params["alpha"]
    share_deriv = np.zeros((len(shares), len(shares)))
    np.fill_diagonal(share_deriv, alpha * shares * (1 - shares))
    return np.linalg.inv(share_deriv)
