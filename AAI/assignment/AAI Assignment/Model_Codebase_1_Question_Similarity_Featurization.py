#!/usr/bin/env python

#11915010	Raghu Punnamraju
#11915043	Anmol More
#11915001	Sriganesh Balamurugan
#11915052	Kapil Bindal

import pandas as pd
import codecs
import numpy as np

import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.feature_extraction.text import TfidfTransformer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.metrics import confusion_matrix
from sklearn import metrics
from sklearn.metrics import roc_curve, auc

from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import GridSearchCV, RandomizedSearchCV
from sklearn.metrics import f1_score, precision_score,recall_score

import re
import string
from nltk.corpus import stopwords
from nltk.stem import PorterStemmer
from nltk.stem.wordnet import WordNetLemmatizer

from gensim.models import Word2Vec

from tqdm import tqdm
import pickle
import warnings
warnings.filterwarnings("ignore")

from sklearn_deltatfidf import DeltaTfidfVectorizer


# # Data Loading and Preprocessing

covid_data = pd.read_csv('data/knowledge_base.csv')
covid_data = pd.DataFrame(covid_data.iloc[:,0])

print(covid_data.shape)

covid_data.columns = ['OriginalText']
print(list(covid_data['OriginalText'])[0])
train_x_tf = covid_data


from bs4 import BeautifulSoup
from tqdm import tqdm
train_x_tf['CleanedText'] = ''
# tqdm is for printing the status bar
for i in tqdm(range(0,train_x_tf['OriginalText'].shape[0]-1)):
    range(0,train_x_tf['OriginalText'].shape[0]-1)
    sentence = str(train_x_tf.iloc[i,[train_x_tf.columns.get_loc('OriginalText')]].values)    
    sentence = re.sub("\S*\d\S*", "", sentence).strip()    
    sentence = re.sub('[<>%\$\'\,\|]', ' ', sentence)    
    sentence = re.sub('[^a-zA-Z]',' ',train_x_tf['OriginalText'].iloc[:].values[i])  
#    sentence = ' '.join(e for e in sentence.split() if e not in final_stopwords)    
    train_x_tf.iloc[i,[train_x_tf.columns.get_loc('CleanedText')]] = sentence.strip()     
train_x_tf.head()


import nltk
import sklearn

print('The nltk version is {}.'.format(nltk.__version__))
print('The scikit-learn version is {}.'.format(sklearn.__version__))

# ## TF-IDF Implementation

#TF-IDF Implementation

#initiate TfidfVectorizer with default parameters
tf_idf_vectorizer = TfidfVectorizer(ngram_range=(1,2), min_df=10)
#Learning the internal parameters of data before doing transform
#Here the dimension of the vectorizer is based on xtr
#(which will be applied to crossvalidation and test also during transform)
tf_idf_vect = tf_idf_vectorizer.fit(train_x_tf.CleanedText)

#Applying the learned parameters and creating vectorizer output (Dimension same as xtr)
final_xtr = tf_idf_vect.transform(train_x_tf.CleanedText)

with open('models/covid_tf_idf_vect.pkl', 'wb') as f:
    pickle.dump(tf_idf_vect, f)


##-----------------Standardizing --- START

#Standardizing the vectorized matrix
final_xtr_std = StandardScaler(with_mean=False)
# here it will learn mu and sigma
final_xtr_std.fit(final_xtr)

print("~~~~ STANDARDIZATION : Training ~~~~~")
# with the learned mu and sigma it will do std on train data
standardized_tfidf_train = final_xtr_std.transform(final_xtr)
print('Shape after standarizing:',standardized_tfidf_train.shape)
print(type(standardized_tfidf_train))

with open('models/covid_final_xtr_std.pkl', 'wb') as f:
    pickle.dump(final_xtr_std, f)
    
with open('models/covid_standardized_tfidf_train.pkl', 'wb') as f:
    pickle.dump(standardized_tfidf_train, f)    




