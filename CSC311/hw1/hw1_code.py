from sklearn.feature_extraction.text import CountVectorizer
from sklearn.model_selection import train_test_split
from sklearn import tree
import matplotlib.pyplot as plt
import math
import numpy as np

def load_data():
    dataset = []
    labels = []
    fake_news_file = open("clean_fake.txt", "r")
    real_news_file = open("clean_real.txt", "r")
    for line in fake_news_file.readlines():
        dataset.append(line.strip())
        labels.append('fake')
    for line in real_news_file.readlines():
        dataset.append(line.strip())
        labels.append('real')
    fake_news_file.close()
    real_news_file.close()
    vectorizer = CountVectorizer()
    X = vectorizer.fit_transform(dataset)
    data_train, data_rest, label_train, label_rest = train_test_split(X, labels, train_size=0.7, random_state=7)
    features = vectorizer.get_feature_names_out()
    data_validate, data_test, label_validate, label_test = train_test_split(data_rest, label_rest, test_size=0.5,
                                                                      random_state=7)
    data = [data_train, data_validate, data_test]

    outputs = [label_train, label_validate, label_test]

    # print(data[2].shape[0])

    return data, outputs, features, vectorizer

def select_model(data, outputs):
    def check_validate(check, answer):
        correct = 0
        for i in range(len(check)):
            if check[i] == answer[i]:
                correct += 1
        return correct/len(check)
    gini_accuracy = []
    max_depth_list = []
    criterions = ['gini', 'log_loss', 'entropy']
    for i in range(7, 56, 10):
        for j in criterions:
            classifier = tree.DecisionTreeClassifier(max_depth=i, criterion=j)
            classifier.fit(data[0], outputs[0])
            validate = classifier.predict(data[1])
            accuracy = check_validate(validate, outputs[1])
            print("max_depth: "+ str(i) +", criteria: "+ str(j) +", accuracy: "+ str(accuracy))
            if j == 'gini':
                gini_accuracy.append(accuracy)
        max_depth_list.append(i)
    return max_depth_list, gini_accuracy

def compute_information_gain(data, output, vectorizer, word, threshold):
    def entropy_helper(count, total):
        if count == 0:
            return 0
        return - ((count / total) * math.log((count / total), 2))
    # entropy of Y
    count_real = len(output[output=='real'])
    count_fake = len(output) - count_real
    total = len(outputs[0])
    h_y = entropy_helper(count_real, total) + entropy_helper(count_fake, total)
    word_index = vectorizer.vocabulary_[word]

    small_output = output[data[:, word_index] <= threshold]
    big_output = output[data[:, word_index] > threshold]
    small_len = len(small_output)
    big_len = len(big_output)

    small_real = len(small_output[small_output=='real'])
    small_fake = len(small_output[small_output=='fake'])
    big_real = len(big_output[big_output == 'real'])
    big_fake = len(big_output[big_output == 'fake'])
    
    h_x= (small_len / len(output)) * (entropy_helper(small_real, small_len) + entropy_helper(small_fake, small_len)) + (big_len / len(output)) * (entropy_helper(big_real, big_len) + entropy_helper(big_fake, big_len))
    print("Information gain of '"+ str(word) + "' is", h_y - h_x)





data, outputs, features, vectorizer = load_data()

max_depth_list, gini_accuracy = select_model(data, outputs)
plt.plot(max_depth_list, gini_accuracy)
plt.xlabel("max_depth")
plt.ylabel("validation accuracy")
plt.title('Gini')
plt.show()
plt.savefig('accuracy_plot.png')

# part c
classifier = tree.DecisionTreeClassifier(max_depth=27, criterion='log_loss')
classifier.fit(data[0], outputs[0])
plt.figure(figsize=(15, 10))
tree.plot_tree(classifier, max_depth=2, feature_names=features, class_names=['real', 'fake'], fontsize=12,
                   filled=True)
plt.show() 
plt.savefig('best_tree.png')

# part d
words = ["donald", "the", "hillary", "trumps", "de", "election", "are"]
for word in words:
    compute_information_gain(np.array(data[0].toarray()), np.array(outputs[0]), vectorizer, word, 0.5)


