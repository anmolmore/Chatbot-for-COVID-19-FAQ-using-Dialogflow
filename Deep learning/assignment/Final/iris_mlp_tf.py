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

#define mlp model with three hidden layers
def mlp_model(x, n_h1, n_h2, n_h3):
    n_f = 4  #No of features
    n_labels = 3  #No of classes
    
    #hidden layer 1
    with tf.name_scope('hidden_layer1'):
        hidden_layer1_weight = tf.Variable(tf.truncated_normal([n_f, n_h1], 
                                                               mean=0, 
                                                               stddev=1/np.sqrt(n_f)), 
                                           name='hidden_layer1_weight')
        hidden_layer1_bias = tf.Variable(tf.zeros([n_h1]), name='hidden_layer1_bias')
        hidden_layer1 = tf.nn.relu(tf.matmul(x, hidden_layer1_weight) + hidden_layer1_bias)
  
    #hidden layer 2
    with tf.name_scope('hidden_layer2'):
        hidden_layer2_weight = tf.Variable(tf.truncated_normal([n_h1, n_h2],
                                                               mean=0, 
                                                               stddev=1/np.sqrt(n_h1)), 
                                           name='hidden_layer2_weight')
        hidden_layer2_bias = tf.Variable(tf.zeros([n_h2]), name='hidden_layer2_bias')
        hidden_layer2 = tf.nn.relu(tf.matmul(hidden_layer1, hidden_layer2_weight) + hidden_layer2_bias)
        
    #hidden layer 3
    with tf.name_scope('hidden_layer3'):
        hidden_layer3_weight = tf.Variable(tf.truncated_normal([n_h2, n_h3],
                                                               mean=0, 
                                                               stddev=1/np.sqrt(n_h2)), 
                                           name='hidden_layer3_weight')
        hidden_layer3_bias = tf.Variable(tf.zeros([n_h3]), name='hidden_layer3_bias')
        hidden_layer3 = tf.nn.relu(tf.matmul(hidden_layer2, hidden_layer3_weight) + hidden_layer3_bias)

    #output layer
    with tf.name_scope('output_layer'):
        output_layer_weight = tf.Variable(tf.truncated_normal([n_h3, n_labels],
                                                  mean=0, 
                                                  stddev=1/np.sqrt(n_h3)),
                                          name='output_layer_weight')
        output_layer_bias = tf.Variable(tf.zeros([3]), name='output_layer_bias')
        output_layer = tf.sigmoid(tf.matmul(hidden_layer3, output_layer_weight) + output_layer_bias)
    
    weight_histogram = tf.summary.histogram("weights", output_layer_weight)
    bias_histogram = tf.summary.histogram("biases", output_layer_bias)
    return output_layer 
    
df = pd.DataFrame(columns=['Run Count', 'Epoch', 'Cost', 'Mean Accuracy', 'Standard Deviation'])
learn_rate = 0.01
log_dir = 'logs'

for i in range(1,11) :
    tf.reset_default_graph()
    g = tf.Graph()
    log_dir = 'logs' + str(i)

    with g.as_default() :
        x = tf.placeholder(tf.float32, shape=[None, 4])  #four features
        y = tf.placeholder(tf.float32, [None, 3])
        y_predicted = mlp_model(x, 5, 10, 5)

        #cross entropy cost function
        with tf.name_scope("cost_function") as scope :
            cost = tf.reduce_mean(tf.nn.softmax_cross_entropy_with_logits_v2(logits=y_predicted,
                                                                                      labels=y))
            tf.summary.scalar("cost_function", cost)

        with tf.name_scope("train") as scope:
            optimizer = tf.train.AdamOptimizer(learn_rate).minimize(cost)

        correct_prediction = tf.equal(tf.argmax(y_train,1), tf.argmax(y_predicted,1))
        accuracy = tf.reduce_mean(tf.cast(correct_prediction, tf.float32))

    with tf.Session(graph=g) as sess:
        sess.run(tf.global_variables_initializer())

        merged_summary = tf.summary.merge_all()
        summary_writer = tf.summary.FileWriter(log_dir, graph=g)

        for epochs in range(1000):
            _, c= sess.run([optimizer,cost],feed_dict = {x: X_train, y: y_train})

            #write to tf summary every 100 iterations
            if(epochs + 1) % 100 == 0:
                summary_str = sess.run(merged_summary, feed_dict={x: X_train, y: y_train})
                summary_writer.add_summary(summary_str, epochs+1)

            #print results for each of 10 runs
            if(epochs + 1) % 1000 == 0:
                test_result = sess.run(y_predicted, feed_dict = {x: X_train})
                correct_prediction = tf.equal(tf.argmax(test_result,1),tf.argmax(y_train,1))
                mean_accuracy = tf.reduce_mean(tf.cast(correct_prediction,"float"))

                mean_std = tf.math.reduce_std(tf.cast(correct_prediction, "float"))

                print("Epoch:",epochs+1,"Cost:", c)
                print("Mean Accuracy across epoch :", mean_accuracy.eval({x: X_test, y: y_test}))
                print("Mean Standard Deviation across epoch :", mean_std.eval({x: X_test, y: y_test}))

                df = df.append({'Run Count': i, 'Epoch': 1000, 'Cost': c,
                                'Mean Accuracy': mean_accuracy.eval({x: X_test, y: y_test}),
                                'Standard Deviation': mean_std.eval({x: X_test, y: y_test})},
                               ignore_index=True)
    
print(df.head(10))

print("Mean Accuracy across all 10 runs : ", df['Mean Accuracy'].mean())
print("Mean Standard Deviation across all 10 runs : ", df['Standard Deviation'].mean())