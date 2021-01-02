from sklearn.preprocessing import LabelEncoder

import pandas as pd

import keras
from keras.models import Sequential
from keras.layers import Dense, Dropout, Activation
from keras.wrappers.scikit_learn import KerasClassifier
from sklearn.model_selection import cross_val_score
from sklearn.model_selection import KFold
from keras.optimizers import SGD
from keras.utils import np_utils

columns = ['sepal_length', 'sepal_width', 'petal_length', 'petal_width', 'species']

#separate feature and labels
features = columns[:-1]
label = columns[-1]

iris_train = pd.read_csv('../iris_training.csv', header = None, names = columns)
iris_test = pd.read_csv('../iris_test.csv', header = None, names = columns)

X_train = iris_train.iloc[:, :-1]

#one hot encode labels
y_train = iris_train.iloc[:, -1:]
y_train = pd.get_dummies(y_train.species)
X_test = iris_test.iloc[:, :-1]

#one hot encode labels
y_test = iris_test.iloc[:, -1:]
y_test = pd.get_dummies(y_test.species)

model = Sequential()
model.add(Dense(5, input_dim=4, activation='relu'))
model.add(Dense(10, activation='relu'))
model.add(Dense(5, activation='relu'))
model.add(Dense(3, activation='sigmoid'))

model.compile(loss='categorical_crossentropy', optimizer='adam', metrics=['accuracy'])

print('Keras model summary')
print(model.summary())

df = pd.DataFrame(columns=['Run Count', 'Epoch', 'Loss Value', 'Accuracy'])

for i in range(1,11) :
    model.fit(X_train, y_train, batch_size=5, epochs=100)
    results = model.evaluate(X_test, y_test)

    print('Mean loss function value {:2f}'.format(results[0]))
    print('Accuracy : {:2f}'.format(results[1]))
    
    df = df.append({'Run Count': i, 'Epoch': 100, 'Loss Value': results[0],
                    'Accuracy': results[1]}, ignore_index=True)
                    
print(df.head(10))

print("Mean Accuracy across all 10 runs : ", df['Accuracy'].mean())
print("Mean Standard Deviation across all 10 runs : ", df['Accuracy'].std())