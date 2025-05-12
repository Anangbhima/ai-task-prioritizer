from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
from datetime import datetime
from typing import List, Dict

app = Flask(__name__)
CORS(app)

# Load model and required features
try:
    model = joblib.load('task_priority_model.pkl')
    features = joblib.load('model_features.pkl')  # List of feature names in order
    model_loaded = True
except FileNotFoundError:
    model_loaded = False
    model = None
    features = []

# --- Feature extraction ---
def extract_features(task: Dict, current_time: datetime) -> List[float]:
    try:
        deadline = datetime.strptime(task['deadline'], "%Y-%m-%d")
        days_left = (deadline - current_time).days
    except (KeyError, ValueError):
        days_left = 0
    return [
        days_left,
        task.get('urgency_score', 0),
        len(task.get('dependencies', [])),
        task.get('normalized_urgency', 0.0),
        1 if task.get('status', '').lower() == 'overdue' else 0
    ]

def validate_features(features: List[float]) -> bool:
    return len(features) == 5 and all(isinstance(x, (int, float)) for x in features)

# --- Decorator for feature validation ---
def validate_task_features(func):
    def wrapper(task: Dict, current_time: datetime):
        features = extract_features(task, current_time)
        if not validate_features(features):
            raise ValueError(f"Feature mismatch. Expected 5 numerical features, got {features}")
        return func(task, current_time)
    return wrapper

# --- Prediction ---
@validate_task_features
def predict_task_priority(task: Dict, current_time: datetime) -> float:
    features = extract_features(task, current_time)
    # Return probability of class 1 (high priority)
    return float(model.predict_proba([features])[0][1])

def dependencies_met(task: Dict, completed_task_ids: List[int]) -> bool:
    return all(dep in completed_task_ids for dep in task.get('dependencies', []))

def prioritize(task_list: List[Dict], completed_ids: List[int] = []) -> List[Dict]:
    current_time = datetime.now()
    for task in task_list:
        try:
            if dependencies_met(task, completed_ids):
                task['score'] = predict_task_priority(task, current_time)
                task['status'] = 'ready'
            else:
                task['score'] = -1
                task['status'] = 'blocked'
        except Exception as e:
            task['score'] = -1
            task['error'] = str(e)
    return sorted(
        [t for t in task_list if t['score'] >= 0],
        key=lambda x: x['score'],
        reverse=True
    )

# --- API Routes ---
@app.route('/')
def home():
    return "✅ Task Prioritization API - Operational"

@app.route('/prioritize_tasks', methods=['POST'])
def handle_prioritization():
    try:
        data = request.get_json()
        if not data or 'tasks' not in data:
            return jsonify({"error": "No tasks provided in request body"}), 400

        tasks = data['tasks']
        completed_ids = data.get('completed_task_ids', [])

        if not model_loaded:
            return jsonify({
                "error": "Model not loaded - verify task_priority_model.pkl exists",
                "required_features": features
            }), 500

        # Validate incoming task structure
        required_fields = {'deadline', 'urgency_score', 'dependencies', 'status', 'normalized_urgency'}
        for task in tasks:
            if not required_fields.issubset(task.keys()):
                return jsonify({
                    "error": f"Task missing required fields: {required_fields}",
                    "received": list(task.keys())
                }), 400

        prioritized = prioritize(tasks, completed_ids)
        return jsonify({
            "prioritized_tasks": prioritized,
            "feature_set": features
        })

    except Exception as e:
        return jsonify({
            "error": str(e),
            "expected_features": features,
            "model_status": "loaded" if model_loaded else "not loaded"
        }), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000)

