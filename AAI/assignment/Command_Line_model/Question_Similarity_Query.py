#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pickle
import warnings
warnings.filterwarnings("ignore")
import pandas as pd
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from scipy import sparse

with open('covid_tf_idf_vect.pkl', 'rb') as f:
    tf_idf_vect = pickle.load(f)
with open('covid_final_xtr_std.pkl', 'rb') as f:
    final_xtr_std = pickle.load(f)
with open('covid_standardized_tfidf_train.pkl', 'rb') as f:
    train_embed = pickle.load(f)       
    


# In[ ]:


while(True):
    #query = "What type of virus is coronavirus?"
    query = input()
    #print(query)
    test_x = tf_idf_vect.transform(pd.Series(query))
    final_query = final_xtr_std.transform(test_x)
    final_mat = sparse.vstack((final_query,train_embed))
    similarities_sparse = cosine_similarity(final_mat)
    kb = pd.read_csv('knowledge_base.csv')
    print('Answer => ' + kb.iloc[np.argmax(similarities_sparse[0][1:])][1]    )
    print()


# In[ ]:





# In[ ]:





# In[ ]:




