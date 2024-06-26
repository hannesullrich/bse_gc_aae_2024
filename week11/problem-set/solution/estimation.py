import numpy as np
from dynamicprogramming import bellman1, bellman2

def rust_llf(
        theta, 
        d,
        xt,
        params,
):
    # This computes the likelihood function

    if params["bellman_emax"]:
        # Solve using Emax method.
        # Produces V01 (choice-specific value function)
        _, V01, _ = bellman1(
            theta,
            params,
)
    else:
        # Solve using alternative specific method
        # Produces V01 (choice-specific value function)
        _, V01, _ = bellman2(
            theta,
            params,
)

    prd1 = np.exp(V01[xt, 1]) / (np.exp(V01[xt, 0]) + np.exp(V01[xt, 1]))

    # # Save V01 if needed, e.g., using numpy.savez
    # np.savez('V01.npz', V01=V01)

    llfi = np.log(d * prd1 + (1 - d) * (1 - prd1))

    llf = -np.mean(llfi)
    
    return llf