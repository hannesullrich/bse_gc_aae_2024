import numpy as np
import pandas as pd


def simulate_data(params, num_products, num_markets, seed=100):
    """Simulate data given model paramaters.

    This is the main function of this module.

    Args:
        params (dict): Model parameters.
        num_products (int): Number of products.
        num_markets (int): Number of markets.
        seed (int, optional): Controls randomness. Default is 100.

    Returns:
        pandas.DataFrame: DataFrame of simulated data for products containing
        observable and unobservable product characteristics, prices, costs, and market
        shares.
    """

    np.random.seed(seed)
    # Initialize empty dataset with multiindex of products and markets.
    idx = pd.MultiIndex.from_product(
        [range(num_markets), range(num_products)],
        names=["market", "product"],
    )
    df = pd.DataFrame(index=idx)

    # Add observable characteristics.
    df["obs_char_0"] = 1
    # Draw observable characteristic from uniform distribution and assign to each
    # product.
    df["obs_char_1"] = np.random.uniform(1, 2, size=num_markets * num_products)

    # Add cost shifters.
    for i in [1, 2, 3]:
        df[f"obs_cost_shifter_{i}"] = np.random.uniform(
            0, 1, size=num_products * num_markets
        )

    # Add unobservable demand characteristics.
    unobserved_char = np.random.multivariate_normal(
        mean=[0, 0], cov=params["sigma_c"], size=num_products * num_markets
    )

    df["xi"], df["omega"] = unobserved_char[:, 0], unobserved_char[:, 1]

    # Compute marginal costs.
    df["marginal_costs"] = (
        params["gamma_1"][0] * df["obs_char_0"]
        + params["gamma_1"][1] * df["obs_char_1"]
        + params["gamma_2"][0] * df["obs_cost_shifter_1"]
        + params["gamma_2"][1] * df["obs_cost_shifter_2"]
        + params["gamma_2"][2] * df["obs_cost_shifter_3"]
        + df["omega"]
    )

    return df
