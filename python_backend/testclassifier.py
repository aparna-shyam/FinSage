import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report
import joblib

# ===============================
# Load Dataset
# ===============================
df = pd.read_csv("train.csv")
print("Dataset loaded successfully!")
print(df.head())
print("Columns:", df.columns.tolist())

# Combine title and description into a single text field
df["text"] = df["title"].fillna("") + " " + df["description"].fillna("")

# Features (X) and Labels (y)
X = df["text"]
y = df["categories"]

# ===============================
# TF-IDF Vectorization
# ===============================
vectorizer = TfidfVectorizer(stop_words="english", max_features=5000)
X_vec = vectorizer.fit_transform(X)

# ===============================
# Train-Test Split
# ===============================
X_train, X_test, y_train, y_test = train_test_split(
    X_vec, y, test_size=0.2, random_state=42
)

# ===============================
# Train Logistic Regression
# ===============================
clf = LogisticRegression(max_iter=200)
clf.fit(X_train, y_train)

# ===============================
# Evaluate Model
# ===============================
y_pred = clf.predict(X_test)
print("\nClassification Report:\n")
print(classification_report(y_test, y_pred))

# ===============================
# Save the trained model and vectorizer
# ===============================
joblib.dump(clf, 'model.pkl')
joblib.dump(vectorizer, 'vectorizer.pkl')
print("\nModel and vectorizer saved successfully!")

# ===============================
# User Input Prediction (Optional, for testing)
# ===============================
while True:
    user_input = input("\nEnter an expense description (or type 'exit' to quit): ")
    if user_input.lower() == "exit":
        print("Exiting... Goodbye!")
        break

    # Convert input to TF-IDF
    user_vec = vectorizer.transform([user_input])

    # Predict category
    prediction = clf.predict(user_vec)[0]
    print(f"Predicted Category: {prediction}")