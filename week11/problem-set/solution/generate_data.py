import numpy as np
import pandas as pd
from dynamicprogramming import bellman1, bellman2

def simulate_data(
        theta,
        params,
        num_observations,
        seed=100
):
    """Simulate data given model paramaters.

    This is the main function of this module.

    Args:
        params (dict): Model parameters.
        nd (int): Number of observations.
        seed (int, optional): Controls randomness. Default is 100.

    Returns:
        pandas.DataFrame: DataFrame of simulated data for milage states and replacement decisions
    """

    np.random.seed(seed)
    # Initialize empty dataset with specified number of rows.
    index = range(0,num_observations)
    df = pd.DataFrame(index=index)

    # Solve dynamic programming problem.
    if params["bellman_emax"]:
        EV,V01,numiter = bellman1(
            theta,
            params,
)
    else:
        EV,V01,numiter = bellman2(
            theta,
            params,
)

    # Mileage transition draws
    xup = np.random.binomial(1,params["lambda"],num_observations);

    # Take extreme value type 1 draws.
    epsilon = np.random.gumbel(loc=0.0, scale=1.0, size=[num_observations, 2])

    e1 = epsilon[:, 0]
    e2 = epsilon[:, 1]
    
    # Optimal replacement decisions and resulting mileage resets
    xt = np.zeros((num_observations,1),dtype=int).flatten()
    xt1 = np.zeros((num_observations,1),dtype=int).flatten()
    d = np.zeros((num_observations,1),dtype=int).flatten()

    for i in range(num_observations):
        # Choice
        d[i,] = (V01[xt[i,], 1] + e2[i,]) > (V01[xt[i,], 0] + e1[i,])
        # State transition
        xt1[i,] = (1 - d[i,]) * np.min([xt[i,] + xup[i,], 10]) + d[i,] * xup[i,]
        if i < num_observations - 1:
            xt[i + 1,] = xt1[i,]

    df["xt"] = xt
    df["xt1"] = xt1
    df["d"] = d

    return df
