# app.py
from flask import Flask, request, jsonify
import joblib

app = Flask(__name__)

# Load the trained model and vectorizer
model = joblib.load('model.pkl')
vectorizer = joblib.load('vectorizer.pkl')

@app.route('/categorize_expense', methods=['POST'])
def categorize_expense():
    data = request.json
    expense_description = data.get('description', '')

    if not expense_description:
        return jsonify({'error': 'No description provided'}), 400

    # Vectorize the input using the loaded vectorizer
    user_input_vec = vectorizer.transform([expense_description])

    # Make a prediction
    prediction = model.predict(user_input_vec)[0]

    return jsonify({'category': prediction})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
