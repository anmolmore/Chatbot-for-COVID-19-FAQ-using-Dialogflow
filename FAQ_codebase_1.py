#11915010	Raghu Punnamraju
#11915043	Anmol More
#11915001	Sriganesh Balamurugan
#11915052	Kapil Bindal
import os
import pandas as pd
import json
import sys
import shortuuid
import numpy
import datetime

#read multiple csv and xlsx files collected

#data collected from International sources
df1 = pd.read_csv('data/dataset_1.csv')
df1['Last Retrieved Time'] = pd.to_datetime(df1['Last Retrieved Time'])
df1 = df1.fillna(method='ffill')
print(df1.shape)

#data collected from karnataka government website
df2 = pd.read_excel('data/dataset_2.xlsx')
df2.rename(columns={"Website" : "Source URL", "Question" : "question", "Answers" : "text"}, inplace=True)
df2['title']  = 'Info from Government'
df2['Organization']  = 'Govt of Karnataka'
df2['Country'] = 'India'
df2['Last Retrieved Time'] = datetime. datetime. today()
df2['context'] = df2['text']
df2.drop(columns=['Unnamed: 3'], inplace=True)
df2 = df2.fillna(method='ffill')
print(df2.shape)

#data collected from WHO website
df3 = pd.read_csv('data/dataset_3.csv')
df3['Last Retrieved Time'] = pd.to_datetime(df3['Last Retrieved Time'])
df3 = df3.fillna(method='ffill')
print(df3.shape)

df = pd.concat([df1, df2, df3], sort=False)
print("Final dataset size : ",df.shape)
print(df.sample(5))

# convert the data in squavd format to be fed to bert based algorithms

def f(a,b):
    return(str(a).find(str(b)))

df['answer_start'] = df[['context','text']].apply(lambda x: f(*x), axis=1)
df['id'] = df['question'].apply(lambda x: shortuuid.uuid(name=x))
df.to_csv('data/dataset_collected.csv', index=False)
df.head()

#remove special characters
spec_chars = ["!",'"',"#","%","&","'","(",")",
              "*","+",",","-",".","/",":",";","<",
              "=",">","?","@","[","\\","]","^","_",
              "`","{","|","}","~","–"]
for char in spec_chars:
    df['context'] = df['context'].str.replace(char, ' ')
    df['text'] = df['text'].str.replace(char, ' ')
    
#clean whitespaces
df['context'] = df['context'].str.split().str.join(" ")
df['text'] = df['text'].str.split().str.join(" ")
df['title'] = df['title'].str.split().str.join(" ")

#function to convert to json for training
def convert_to_dictionary(df):
    group_by_title = df.groupby(['title'])
    final_dict = []
    for key1, value1 in group_by_title:
        temp_dict1 = {}
        dictList2 = []
        temp_dict2 = {}
        title = key1
        temp_dict1['title'] = title
        grouped2 = df.loc[df['title'] == title].groupby(['context'])
        for key2, value2 in grouped2:
            dictList3 = []
            temp_dict3 = {}
            context = key2
            temp_dict2['context'] =context
            grouped3 = df.loc[(df['title'] == title) & (df['context'] == context)].groupby(['id'])
            for key3, value3 in grouped3:
                n = grouped3.get_group(key3)
                dictList4 = []
                for m in n.index: 
                    temp_dict4 = {}
                    temp_dict4['answer_start'] = n.at[m, 'answer_start']
                    temp_dict4['text'] = n.at[m, 'text']
                    dictList4.append(temp_dict4.copy())
                temp_dict3['answers'] = dictList4
                curr_ques = value3["question"].reset_index()
                curr_id = value3["id"].reset_index()
                temp_dict3['question'] = curr_ques.iloc[0,1]
                temp_dict3['id'] = curr_id.iloc[0,1]
                dictList3.append(temp_dict3.copy()) 
            temp_dict2['qas'] = dictList3
            dictList2.append(temp_dict2.copy())
        temp_dict1['paragraphs'] = dictList2
        final_dict.append(temp_dict1.copy())
    return(final_dict)
squavd_list = convert_to_dictionary(df)

def default(o):
    if isinstance(o, numpy.int64): return int(o)  
    raise TypeError
        
with open('dataset_json.json', 'w') as json_file:
    json_file.write(json.dumps({'data': squavd_list,'version': '1.1'},default=default))
    json_file.close()