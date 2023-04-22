'''
Question 4 Skeleton Code

Here you should implement and evaluate the Conditional Gaussian classifier.
'''

import data
import numpy as np
# Import pyplot - plt.imshow is useful!
import matplotlib.pyplot as plt

def compute_mean_mles(train_data, train_labels):
    '''
    Compute the mean estimate for each digit class

    Should return a numpy array of size (10,64)
    The ith row will correspond to the mean estimate for digit class i
    '''
    means = np.zeros((10, 64))
    # Compute means
    for i in range(10):
        sub = data.get_digits_by_label(train_data, train_labels, i)
        means[i,] = np.mean(sub, axis=0)
    return means

def compute_sigma_mles(train_data, train_labels):
    '''
    Compute the covariance estimate for each digit class

    Should return a three dimensional numpy array of shape (10, 64, 64)
    consisting of a covariance matrix for each digit class
    '''
    covariances = np.zeros((10, 64, 64))
    # Compute covariances
    mle_means = compute_mean_mles(train_data, train_labels)
    for i in range(10):
        sub = data.get_digits_by_label(train_data, train_labels, i)
        covs = np.matmul((sub - mle_means[i]).transpose(), (sub - mle_means[i]))
        covariances[i, :, :] = (covs / len(sub)) + np.identity(64) * 0.01
    return covariances


def generative_likelihood(digits, means, covariances):
    '''
    Compute the generative log-likelihood:
        log p(x|y,mu,Sigma)

    Should return an n x 10 numpy array
    '''
    n, d = digits.shape
    gen_likelihood = np.zeros((n, 10))
    constant = (-0.5 * d) * np.log(2 * np.pi)
    for i in range(n):
        for j in range(10):
            covs = covariances[j, :, :]
            covs_inv = np.linalg.inv(covs)
            mu = digits[i, :] - means[j, :]
            gen_likelihood[i][j] = constant + (- 0.5) * np.log(np.linalg.det(covs)) -  np.matmul(np.matmul(0.5 *mu.transpose(), covs_inv), mu)
    return gen_likelihood

def conditional_likelihood(digits, means, covariances):
    '''
    Compute the conditional likelihood:

        log p(y|x, mu, Sigma)

    This should be a numpy array of shape (n, 10)
    Where n is the number of datapoints and 10 corresponds to each digit class
    '''
    condition_likelihood = np.zeros((digits.shape[0], 10))
    gen_likelihood = generative_likelihood(digits, means, covariances)
    
    for i in range(digits.shape[0]):
        gen_likelihood_num = gen_likelihood[i, :]
        temp = gen_likelihood_num[0]
        for j in range(1, 10):
            temp = np.logaddexp(temp, gen_likelihood_num[j])
        temp += np.log(0.1)
        for k in range(10):
            condition_likelihood[i][k] = gen_likelihood_num[k] + np.log(0.1) - temp
    return condition_likelihood

def avg_conditional_likelihood(digits, labels, means, covariances):
    '''
    Compute the average conditional likelihood over the true class labels

        AVG( log p(y_i|x_i, mu, Sigma) )

    i.e. the average log likelihood that the model assigns to the correct class label
    '''
    cond_likelihood = conditional_likelihood(digits, means, covariances)

    # Compute as described above and return
    result = 0
    for i in range(len(digits)):
        result += cond_likelihood[i][int(labels[i])]
    return result / len(digits)

def classify_data(digits, means, covariances):
    '''
    Classify new points by taking the most likely posterior class
    '''
    cond_likelihood = conditional_likelihood(digits, means, covariances)
    # Compute and return the most likely class
    return np.argmax(cond_likelihood, axis=1)

def main():
    train_data, train_labels, test_data, test_labels = data.load_all_data('data')

    # Fit the model
    means = compute_mean_mles(train_data, train_labels)
    covariances = compute_sigma_mles(train_data, train_labels)

    # for i in range(10):
    #     for j in range(len(covariances[i])):
    #         for k in range(len(covariances[i][j])):
    #             if j != k:
    #                 covariances[i][j][k] = 0

    # Evaluation
    train_prediction = classify_data(train_data, means, covariances)
    test_prediction = classify_data(test_data, means, covariances)
    print('Average conditional log-likelihood on training set is {}.'.format(avg_conditional_likelihood(train_data, train_labels, means,
                                         covariances)))
    print('Average conditional log-likelihood on testing set is {}.'.format(avg_conditional_likelihood(test_data, test_labels, means,
                                         covariances)))
    print("Accuracy on training set is {}.".format(np.mean(train_prediction == train_labels)))
    print("Accuracy on training set is {}.".format(str(np.mean(test_prediction == test_labels))))

if __name__ == '__main__':
    main()
