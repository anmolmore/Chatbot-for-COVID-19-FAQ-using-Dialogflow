from flask import Flask, request, make_response, jsonify, render_template
from flask_cors import CORS

import os
from ast import literal_eval
import pandas as pd
import json

import dialogflow

from cdqa.utils.filters import filter_paragraphs
from cdqa.pipeline import QAPipeline

app = Flask(__name__)
CORS(app)

dataset_path = 'data/df_corona.csv'
reader_path = 'model/model.joblib'
project_id = os.getenv('DIALOGFLOW_PROJECT_ID')

df = pd.read_csv(dataset_path, usecols=['context', 'question'])
df = df.fillna(method='ffill')

df['paragraphs'] = df[df.columns[1:]].apply(
    lambda x: x.dropna().values.tolist(),
    axis=1)

df.rename(columns={"question": "title"}, inplace=True)
df.drop(columns='context', inplace=True)

cdqa_pipeline = QAPipeline(reader=reader_path)
cdqa_pipeline.fit_retriever(df=df)


def detect_intent_texts(project_id, session_id, text, language_code):
    session_client = dialogflow.SessionsClient()
    session = session_client.session_path(project_id, session_id)

    if text:
        text_input = dialogflow.types.TextInput(
            text=text, language_code=language_code)
        query_input = dialogflow.types.QueryInput(text=text_input)
        response = session_client.detect_intent(
            session=session, query_input=query_input)
        print("...................................................")
        print(response)
        print("...................................................")
        return response.query_result.fulfillment_text
        
@app.route('/send_message', methods=['POST'])
def send_message():
    message = request.form['message']
    project_id = os.getenv('DIALOGFLOW_PROJECT_ID')
    fulfillment_text = detect_intent_texts(project_id, "unique", message, 'en')
    response_text = { "message":  fulfillment_text }
    return jsonify(response_text)

@app.route("/api", methods=["GET"])
def api():

    query = request.args.get("query")
    prediction = cdqa_pipeline.predict(query=query)

    return jsonify(
        query=query, answer=prediction[0], title=prediction[1], paragraph=prediction[2]
    )

@app.route('/')
def my_form():
    return render_template('my-form.html')

@app.route('/', methods=['POST'])
def my_form_post():
    text = request.form['text']
    query = text.lower()
    prediction = cdqa_pipeline.predict(query)

    return jsonify(
        query=query, answer=prediction[0], title=prediction[1], paragraph=prediction[2]
    )
    
@app.route('/webhook', methods=['GET', 'POST'])
def webhook():
    text_message = request.get_json(force=True)
    print(text_message)
    query = text_message['queryResult']['queryText']
    print('user query', query)
    query = query.lower()
    prediction = cdqa_pipeline.predict(query=query)
    
    print('answer to query', prediction)
    response_text = {"fulfillmentText":  prediction}
  
    return make_response(jsonify(response_text))
    
    # return jsonify(
#         query=query, answer=prediction[0], title=prediction[1], paragraph=prediction[2]
#    )
    
if __name__ == '__main__':
   app.run()
