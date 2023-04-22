# -*- coding: utf-8 -*-
from __future__ import print_function
import matplotlib.pyplot as plt
import numpy as np
from sklearn.datasets import load_boston
from sklearn.model_selection import train_test_split
np.random.seed(0)

# load boston housing prices dataset
boston = load_boston()
x = boston['data']
N = x.shape[0]
x = np.concatenate((np.ones((506,1)),x),axis=1) #add constant one feature - no bias needed
d = x.shape[1]
y = boston['target']

idx = np.random.permutation(range(N))

#helper function
def l2(A,B):
    '''
    Input: A is a Nxd matrix
           B is a Mxd matirx
    Output: dist is a NxM matrix where dist[i,j] is the square norm between A[i,:] and B[j,:]
    i.e. dist[i,j] = ||A[i,:]-B[j,:]||^2
    '''
    A_norm = (A**2).sum(axis=1).reshape(A.shape[0],1)
    B_norm = (B**2).sum(axis=1).reshape(1,B.shape[0])
    dist = A_norm+B_norm-2*A.dot(B.transpose())
    return dist

 
 
#to implement
def LRLS(test_datum,x_train,y_train, tau,lam=1e-5):
    '''
    Input: test_datum is a dx1 test vector
           x_train is the N_train x d design matrix
           y_train is the N_train x 1 targets vector
           tau is the local reweighting parameter
           lam is the regularization parameter
    output is y_hat the prediction on test_datum
    '''
    ## TODO
    distances = l2(x_train, test_datum.reshape(len(test_datum), 1).transpose())
    N, d = x_train.shape
    exp = np.exp([((-dist) / (2 * tau ** 2)) for dist in distances])
    A = np.zeros((N, N))
    np.fill_diagonal(A, exp/np.sum(exp))

    x_A = np.dot(x_train.transpose(), A)
    x_A_y = np.dot(x_A, y_train)
    x_A_x = np.dot(x_A, x_train) + np.identity(d) * lam 

    return np.dot(test_datum.transpose(), np.linalg.solve(x_A_x, x_A_y))[0]
    ## TODO


def run_validation(x,y,taus,val_frac):
    '''
    Input: x is the N x d design matrix
           y is the N x 1 targets vector    
           taus is a vector of tau values to evaluate
           val_frac is the fraction of examples to use as validation data
    output is
           a vector of training losses, one for each tau value
           a vector of validation losses, one for each tau value
    '''
    ## TODO
    def helper(data, data_test, label, label_test, tau):
        count_sum = 0
        for i in range(data.shape[0]):
            pred = LRLS(data[i, :].reshape(d,1), data_test, label, tau)
            count_sum += np.square(label_test[i]-pred)
        return count_sum/ data.shape[0]

    data_t, data_v, label_t, label_v = train_test_split(x, y, test_size=val_frac)
    train_losses = []
    valid_losses = []

    for tau in taus:
       train_losses.append(helper(data_t, data_t, label_t, label_t, tau))
       valid_losses.append(helper(data_v, data_t, label_t, label_v, tau))
    return train_losses, valid_losses
    ## TODO


if __name__ == "__main__":
    # In this excersice we fixed lambda (hard coded to 1e-5) and only set tau value. Feel free to play with lambda as well if you wish
    taus = np.logspace(1.0,3,200)
    train_losses, test_losses = run_validation(x,y,taus,val_frac=0.3)
    plt.semilogx(taus, train_losses)
    plt.xlabel('tau')
    plt.ylabel('loss')
    plt.title('train')
    plt.show()

