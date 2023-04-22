from sklearn.impute import KNNImputer
from utils import *
import matplotlib.pyplot as plt

def knn_impute_by_user(matrix, valid_data, k):
    """ Fill in the missing values using k-Nearest Neighbors based on
    student similarity. Return the accuracy on valid_data.

    See https://scikit-learn.org/stable/modules/generated/sklearn.
    impute.KNNImputer.html for details.

    :param matrix: 2D sparse matrix
    :param valid_data: A dictionary {user_id: list, question_id: list,
    is_correct: list}
    :param k: int
    :return: float
    """
    nbrs = KNNImputer(n_neighbors=k)
    # We use NaN-Euclidean distance measure.
    mat = nbrs.fit_transform(matrix)
    acc = sparse_matrix_evaluate(valid_data, mat)
    print("Validation Accuracy: {}".format(acc))
    return acc


def knn_impute_by_item(matrix, valid_data, k):
    """ Fill in the missing values using k-Nearest Neighbors based on
    question similarity. Return the accuracy on valid_data.

    :param matrix: 2D sparse matrix
    :param valid_data: A dictionary {user_id: list, question_id: list,
    is_correct: list}
    :param k: int
    :return: float
    """
    #####################################################################
    # TODO:                                                             #
    # Implement the function as described in the docstring.             #
    #####################################################################
    acc = None
    nbrs = KNNImputer(n_neighbors=k)
    predict_mat = nbrs.fit_transform(matrix.transpose())
    acc = sparse_matrix_evaluate(valid_data, predict_mat.transpose())
    #####################################################################
    #                       END OF YOUR CODE                            #
    #####################################################################
    return acc


def main():
    sparse_matrix = load_train_sparse("../data").toarray()
    val_data = load_valid_csv("../data")
    test_data = load_public_test_csv("../data")

    print("Sparse matrix:")
    print(sparse_matrix)
    print("Shape of sparse matrix:")
    print(sparse_matrix.shape)

    #####################################################################
    # TODO:                                                             #
    # Compute the validation accuracy for each k. Then pick k* with     #
    # the best performance and report the test accuracy with the        #
    # chosen k*.                                                        #
    #####################################################################
    # a)
    accuracy_list = []
    k_values = [1, 6, 11, 16, 21, 26]
    for k in k_values:
        acc = knn_impute_by_user(sparse_matrix, val_data, k)
        accuracy_list.append(acc)
        print(f'user based accuracy for k = {k} is {acc}')
    fig, axis = plt.subplots()
    axis.plot([1, 6, 11, 16, 21, 26], accuracy_list)
    axis.set(xlabel='K', ylabel='Accuracy', title='user based Accuracy vs K')
    # for a,b in zip(k_values, accuracies):
    #     plt.text(a, b, (a, b))
    plt.savefig('Part a - knn - user')

    # c)
    accuracy_list_2 = []
    for k in k_values:
        acc = knn_impute_by_item(sparse_matrix, val_data, k)
        accuracy_list_2.append(acc)
        print(f'item based accuracy for k = {k} is {acc}')
    fig, axis = plt.subplots()
    axis.plot([1, 6, 11, 16, 21, 26], accuracy_list_2)
    axis.set(xlabel='K', ylabel='Accuracy', title='item based Accuracy vs K')
    plt.savefig('Part a - knn - item')
    #####################################################################
    #                       END OF YOUR CODE                            #
    #####################################################################

if __name__ == "__main__":
    main()
