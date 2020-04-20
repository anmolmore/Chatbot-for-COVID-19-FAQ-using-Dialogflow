#11915010	Raghu Punnamraju
#11915043	Anmol More
#11915001	Sriganesh Balamurugan
#11915052	Kapil Bindal

import pandas as pd
from ast import literal_eval

from cdqa.utils.filters import filter_paragraphs
from cdqa.utils.download import download_model, download_bnpp_data
from cdqa.pipeline.cdqa_sklearn import QAPipeline

#read the cleaned dataset and just take question and context for our model
df = pd.read_csv('data/dataset_collected.csv', usecols=['question', 'context'])

#convert paragraphs to a list
df['paragraphs'] = df[df.columns[1:]].apply(
    lambda x: x.dropna().values.tolist(),
    axis=1)

df.rename(columns={"question": "title"}, inplace=True)
df.drop(columns='context', inplace=True)
df.to_csv('df_corona.csv', index=False)

#use a lighter pipleline model to build pipeline on top of it
cdqa_pipeline = QAPipeline(reader='models/model.joblib')
cdqa_pipeline.fit_retriever(df=df)

query = "Can I travel ?"
prediction = cdqa_pipeline.predict(query=query)

print('Query : {}\n'.format(query))
print('Answer from Bot: {}\n'.format(prediction[0]))
print('Matched to Question : {}\n'.format(prediction[1]))
print('Paragraph pickup from : {}\n'.format(prediction[2]))