import numpy as np


def ufun(
        d,
        theta,
        x
):
    """
    This function computes the flow utility function given arguments.

    Args:
    d (array-like): Decision variable.
    theta (array-like): Parameter vector [theta1, theta2, theta3].
    x (array-like): State variable.

    Returns:
    u (numpy.ndarray): Computed utility values.
    """
    u = -theta[2] * d + (1 - d) * (-theta[0] * x - theta[1] * (x * x))
    return u


def bellman1(
        theta,
        params,
):
    """
    This function computes the Bellman equation, iterating over EXPECTED value function EV, Emax.

    Args:
        theta (array-like): Parameters [theta1, theta2, theta3].
        params : Fixed parameters
        x (array-like): State variable.
        threshold (float, optional): Convergence criterion. Default is 1e-12.

    Returns:
    tuple: (EV, V01, numiter) where EV is the expected value function, 
           V01 is the choice-specific value function, and numiter is the number of iterations.
    """
    
    x = params["x"]

    # EV, V01 start as zero vectors
    EV = np.zeros((x.shape[0]))  # allocate Emax function (expected V)
    V01 = np.zeros((x.shape[0], 2))  # allocate choice-specific V (choice set: 0,1)
    numiter = 0
    value_difference = 10

    while value_difference > params["threshold"]:
        # If no replacement, starting from given state
        # current u + discount factor * ( trans prob (shift) * EV (shift) + trans prob (no shift) * EV (no shift) )
        vd0 = ufun(0, theta, x) + params["beta"] * (params["lambda"] * np.append(EV[1:], EV[-1]) + (1 - params["lambda"]) * EV)
        
        # If replacement, starting from new state 0
        # current u + discount factor * ( trans prob (shift) * EV (shift) + trans prob (no shift) * EV (no shift) )
        vd1 = ufun(1, theta, x) + params["beta"] * (params["lambda"] * EV[1] + (1 - params["lambda"]) * EV[0])
        
        # Expected maximum utility, given extreme value assumption
        nev = params["euler"] + np.log(np.exp(vd0) + np.exp(vd1))  # Log-sum

        value_difference = np.max(np.abs((nev - EV) / nev))
        EV = nev
        numiter += 1

    V01[:, 0] = ufun(0, theta, x) + params["beta"] * (params["lambda"] * np.append(EV[1:], EV[-1]) + (1 - params["lambda"]) * EV)
    V01[:, 1] = ufun(1, theta, x) + params["beta"] * (params["lambda"] * EV[1] + (1 - params["lambda"]) * EV[0])

    return EV, V01, numiter


def bellman2(
        theta,
        params,
):
    """
    Computes the Bellman equation.
    Iteration over conditional value function V01.

    Parameters:
    theta (array-like): Parameters [theta1, theta2, theta3].
    Data (dict): Dictionary containing all necessary data.

    Returns:
    tuple: (EV, V01, numiter) where EV is the expected value function, 
           V01 is the choice-specific value function, and numiter is the number of iterations.
    """

    x = params["x"]

    V01 = np.zeros((x.shape[0], 2))  # allocate choice-specific V (choice set: 0,1)
    numiter = 0
    value_difference = 10

    while value_difference > params["threshold"]:
        # No replacement
        nv01 = np.zeros((x.shape[0], 2))
        nv01[:, 0] = ufun(0, theta, x) + params["beta"] * (
            params["lambda"] * (params["euler"] + np.log(np.exp(np.append(V01[1:, 0], V01[-1, 0])) + np.exp(np.append(V01[1:, 1], V01[-1, 1])))) +
            (1 - params["lambda"]) * (params["euler"] + np.log(np.exp(V01[:, 0]) + np.exp(V01[:, 1])))
        )

        # Replacement
        nv01[:, 1] = ufun(1, theta, x) + params["beta"] * (
            params["lambda"] * (params["euler"] + np.log( np.exp(V01[1, 0]) + np.exp(V01[1, 1]))) +
            (1 - params["lambda"]) * (params["euler"] + np.log( np.exp(V01[0, 0]) + np.exp(V01[0, 1])))
        )

        value_difference = np.max(np.abs((nv01 - V01) / nv01))
        V01 = nv01
        numiter += 1

    # Emax
    EV = params["euler"] + np.log(np.exp(nv01[:, 0]) + np.exp(nv01[:, 1]))

    return EV, V01, numiter
