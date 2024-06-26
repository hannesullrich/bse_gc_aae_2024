import numpy as np

def ufun(d, theta, x):
    """
    This function computes the utility function given arguments.

    Args:
    d (scalar): Decision variable.
    theta (array): Parameter vector [theta1, theta2, theta3].
    x (array): State variable.

    Returns:
    numpy.ndarray: Computed utility values.
    """
    u = -theta[2] * d + (1 - d) * (-theta[0] * x + theta[1] * (x * x))
    return u
