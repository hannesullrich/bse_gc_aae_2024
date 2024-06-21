import numpy as np
from scipy.special import roots_hermite


def quadrature_hermite(n_quad_points, mu, sigma):
    """Return the Hermite quadrature points and weights.

    It is the specific quadrature rule for the normal distribution.
    See the mathematical details here:
    https://en.wikipedia.org/wiki/Gauss%E2%80%93Hermite_quadrature

    Args:
        n_quad_points (int): Number of quadrature points.
        mu (float): Mean of the normal distribution.
        sigma (float): Standard deviation of the normal distribution.

    Returns:
        tuple:

        - quad_points_scaled (np.ndarray): 1d array of shape (n_quad_points,)
            containing the Hermite quadrature points.
        - quad_weights (np.ndarray): 1d array of shape (n_quad_points,)
            containing the associated Hermite quadrature weights.

    """
    # This should be the better quadrature. Leave out for now!
    quad_points, quad_weights = roots_hermite(n_quad_points)
    # Rescale draws and weights
    quad_points_scaled = quad_points * np.sqrt(2) * sigma + mu
    quad_weights *= 1 / np.sqrt(np.pi)

    return quad_points_scaled, quad_weights
