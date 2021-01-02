#!/usr/bin/env python

#11915010	Raghu Punnamraju
#11915043	Anmol More
#11915001	Sriganesh Balamurugan
#11915052	Kapil Bindal

import pickle
import warnings
warnings.filterwarnings("ignore")
import pandas as pd
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from scipy import sparse

with open('models/covid_tf_idf_vect.pkl', 'rb') as f:
    tf_idf_vect = pickle.load(f)
with open('models/covid_final_xtr_std.pkl', 'rb') as f:
    final_xtr_std = pickle.load(f)
with open('models/covid_standardized_tfidf_train.pkl', 'rb') as f:
    train_embed = pickle.load(f)

print("Welcome to Corona Chatbot ! ")

while(True):
    print("Please enter your query, press ctrl +c to exit ")
    query = input()
    #print(query)
    test_x = tf_idf_vect.transform(pd.Series(query))
    final_query = final_xtr_std.transform(test_x)
    final_mat = sparse.vstack((final_query,train_embed))
    similarities_sparse = cosine_similarity(final_mat)
    kb = pd.read_csv('data/knowledge_base.csv')
    print('Answer => ' + kb.iloc[np.argmax(similarities_sparse[0][1:])][1]    )
    print()