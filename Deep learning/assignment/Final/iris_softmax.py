import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

#use tensorflow version 1.x features
import tensorflow.compat.v1 as tf
tf.disable_v2_behavior()

sess = tf.InteractiveSession()
# do stuff  
sess.close()
del sess

columns = ['sepal_length', 'sepal_width', 'petal_length', 'petal_width', 'species']

#separate feature and labels
features = columns[:-1]
label = columns[-1]

iris_train = pd.read_csv('../iris_training.csv', header = None, names = columns)
iris_test = pd.read_csv('../iris_test.csv', header = None, names = columns)

print(iris_train.sample(5))

X_train = iris_train.iloc[:, :-1]

#one hot encode labels
y_train = iris_train.iloc[:, -1:]
y_train = pd.get_dummies(y_train.species)

X_test = iris_test.iloc[:, :-1]

#one hot encode labels
y_test = iris_test.iloc[:, -1:]
y_test = pd.get_dummies(y_test.species)

print(X_train.shape)
print(y_train.shape)
print(X_test.shape)
print(y_test.shape)



df = pd.DataFrame(columns=['Run Count', 'Epoch', 'Learn Rate', 'Mean Accuracy', 'Standard Deviation'])

def declare_weight(shape):
    #use 1/np.sqrt(4) as SD for random initialization
    initialize = tf.truncated_normal(shape, stddev=0.5)
    return tf.Variable(initialize)

def declare_bias(shape):
    initialize = tf.constant(0.5, shape=shape)
    return tf.Variable(initialize)

#run whole thing 10 times
for i in range(1,11) :
    sess = tf.InteractiveSession()
    x = tf.placeholder(tf.float32, shape=[None, 4])  #four features
    y = tf.placeholder(tf.float32, shape=[None, 3])  #three classes

    #placeholders for weights and biasesyui
    weight = declare_weight([4,3])
    bias = declare_bias([3])

    #define softmax using tensorflow
    y_predicted = tf.nn.softmax(tf.matmul(x, weight) + bias)
    
    #try with different learn rate and iterations for gradient descent
    learn_rate = 0.01
    epochs = 1000
    
    #define cost function
    cross_entropy_cost = tf.reduce_mean(-tf.reduce_sum(y * tf.log(y_predicted), axis=1))

    optimizer = tf.train.GradientDescentOptimizer(learning_rate=learn_rate).minimize(cross_entropy_cost)
    sess.run(tf.global_variables_initializer())
    
    for epoch in range(epochs) :
        sess.run([optimizer], feed_dict={x:X_train, y:y_train})

    weight_hat, bias_hat = sess.run([weight, bias])
    prediction_accuracy = tf.equal(tf.argmax(y_predicted, 1), tf.argmax(y,1))
    
    mean_accuracy = sess.run(tf.reduce_mean(tf.cast(prediction_accuracy, tf.float32)),
                                            feed_dict={weight:weight_hat, bias:bias_hat, 
                                                                   x: X_test, y: y_test})
    std = sess.run(tf.math.reduce_std(tf.cast(prediction_accuracy, tf.float32)),
                   feed_dict={weight:weight_hat, bias:bias_hat,
                              x: X_test, y: y_test})
    df = df.append({'Run Count': i, 'Epoch': epochs, 'Learn Rate': learn_rate, 
                    'Mean Accuracy': mean_accuracy, 'Standard Deviation': std}, ignore_index=True)

print(df.head(10))

print("Mean Accuracy across all 10 runs : ", df['Mean Accuracy'].mean())
print("Mean Standard Deviation across all 10 runs : ", df['Standard Deviation'].mean())