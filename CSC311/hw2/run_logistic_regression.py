from check_grad import check_grad
from utils import *
from logistic import *

import matplotlib.pyplot as plt
import numpy as np


def run_logistic_regression():
    train_inputs, train_targets = load_train()
    # train_inputs, train_targets = load_train_small()
    valid_inputs, valid_targets = load_valid()

    N, M = train_inputs.shape

    #####################################################################
    # TODO:                                                             #
    # Set the hyperparameters for the learning rate, the number         #
    # of iterations, and the way in which you initialize the weights.   #
    #####################################################################
    hyperparameters = {
        "learning_rate": 0.05,
        "weight_regularization": 0.,
        "num_iterations": 800
    }
    weights = np.zeros((M + 1, 1))
    #####################################################################
    #                       END OF YOUR CODE                            #
    #####################################################################

    # Verify that your logistic function produces the right gradient.
    # diff should be very close to 0.
    run_check_grad(hyperparameters)

    # Begin learning with gradient descent
    #####################################################################
    # TODO:                                                             #
    # Modify this section to perform gradient descent, create plots,    #
    # and compute test error.                                           #
    #####################################################################
    ce_trains = []
    ce_valids = []
    iterations = []
    acc_t = []
    acc_v = []
    for t in range(hyperparameters["num_iterations"]):
        df = logistic(weights, train_inputs, train_targets, hyperparameters)[1]
        weights -= hyperparameters["learning_rate"] * df
        ct, at = evaluate(train_targets,
                          logistic_predict(weights, train_inputs))
        cv, av = evaluate(valid_targets,
                          logistic_predict(weights, valid_inputs))
        ce_trains.append(ct)
        ce_valids.append(cv)
        acc_t.append(at)
        acc_v.append(av)
        iterations.append(t)

    # test_input, test_target = load_test()
    # tr_out = evaluate(train_targets, logistic_predict(weights, train_inputs))
    # val_out = evaluate(valid_targets,
    #                       logistic_predict(weights, valid_inputs))
    # te_out = evaluate(test_target, logistic_predict(weights, test_input))
    # print("Train CE: " + str(tr_out[0]) + " Train accuracy: " + str(
    #     tr_out[1]), "Validation CE: " + str(val_out[0]) + " Validation accuracy: " + str(
    #     val_out[1]), ("Test CE: " + str(te_out[0]) + " Test accuracy: " + str(
    #     te_out[1])))

    plt.plot(iterations, ce_trains, label="train", c='g')
    plt.plot(iterations, ce_valids, label="validation", c='y')
    plt.legend()
    plt.xlabel("number of iterations")
    plt.ylabel("Cross Entropy")
    plt.title("mnist_train")
    plt.savefig("3.2b.png")
    plt.show()

        
        
    #####################################################################
    #                       END OF YOUR CODE                            #
    #####################################################################


def run_check_grad(hyperparameters):
    """ Performs gradient check on logistic function.
    :return: None
    """
    # This creates small random data with 20 examples and
    # 10 dimensions and checks the gradient on that data.
    num_examples = 20
    num_dimensions = 10

    weights = np.random.randn(num_dimensions + 1, 1)
    data = np.random.randn(num_examples, num_dimensions)
    targets = np.random.rand(num_examples, 1)

    diff = check_grad(logistic,
                      weights,
                      0.001,
                      data,
                      targets,
                      hyperparameters)

    print("diff =", diff)


if __name__ == "__main__":
    run_logistic_regression()
