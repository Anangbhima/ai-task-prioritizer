# train_model.py

import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report
import joblib
from datetime import datetime

# Step 1: Load and preprocess dataset
df = pd.read_csv("Updated1_Task_Prioritization_Dataset_Corrected_Deadlines.csv")

# Convert Deadline to datetime and calculate days left from current date
current_date = datetime(2025, 5, 4)  # Use your actual current date
df['Deadline'] = pd.to_datetime(df['Deadline'])
df['Days_Left'] = (df['Deadline'] - current_date).dt.days

# Create binary status indicator (1 for Overdue, 0 otherwise)
df['Status_Overdue'] = df['Status'].apply(lambda x: 1 if x == 'Overdue' else 0)

# Step 2: Select relevant features
features = [
    'Urgency_Score',
    'Days_Left', 
    'Normalized_Urgency',
    'Dependency_Count',
    'Status_Overdue'
]

X = df[features]
y = df['Priority']

# Step 3: Train-test split
X_train, X_test, y_train, y_test = train_test_split(
    X, y, 
    test_size=0.2, 
    random_state=42,
    stratify=y  # Maintain class distribution
)

# Step 4: Initialize and train model
model = RandomForestClassifier(
    n_estimators=100,
    max_depth=5,
    random_state=42,
    class_weight='balanced'  # Handle class imbalance
)

model.fit(X_train, y_train)

# Step 5: Evaluate model
y_pred = model.predict(X_test)

print(f"Model Accuracy: {accuracy_score(y_test, y_pred):.2f}")
print("Classification Report:\n", classification_report(y_test, y_pred))

# Step 6: Save model and feature list
joblib.dump(model, "task_priority_model.pkl")
joblib.dump(features, "model_features.pkl")  # For API validation

print("Model training complete. Feature importance:")
for feature, importance in zip(features, model.feature_importances_):
    print(f"{feature}: {importance:.2f}")
