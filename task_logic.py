
from datetime import datetime
from typing import List, Dict
import joblib

# Load trained model and required features
model = joblib.load('task_priority_model.pkl')
features = joblib.load('model_features.pkl')  # Saved during training

def extract_features(task: Dict, current_time: datetime) -> List[float]:
    """Extract features matching the model's training dataset structure"""
    try:
        deadline = datetime.strptime(task['deadline'], "%Y-%m-%d")
        days_left = (deadline - current_time).days
    except (KeyError, ValueError):
        days_left = 0  # Fallback for invalid/missing dates
    
    return [
        days_left,
        task.get('urgency_score', 0),  # Direct numerical value from dataset
        len(task.get('dependencies', [])),  # Dependency_Count
        task.get('normalized_urgency', 0.0),  # From dataset column
        1 if task.get('status', '').lower() == 'overdue' else 0  # Status_Overdue
    ]

def validate_features(features: List[float]) -> bool:
    """Ensure feature structure matches training data"""
    return len(features) == 5 and all(isinstance(x, (int, float)) for x in features)

def predict_task_priority(task: Dict, current_time: datetime) -> float:
    """Predict priority with feature validation"""
    features = extract_features(task, current_time)
    if not validate_features(features):
        raise ValueError(f"Invalid features: {features}. Expected 5 numerical values")
    return model.predict([features])[0]

def dependencies_met(task: Dict, completed_task_ids: List[int]) -> bool:
    """Simplified dependency check matching dataset structure"""
    return all(dep in completed_task_ids for dep in task.get('dependencies', []))

def prioritize_tasks(task_list: List[Dict], completed_task_ids: List[int] = None) -> List[Dict]:
    """Main prioritization logic with error handling"""
    current_time = datetime.now()
    completed = completed_task_ids or []
    
    for task in task_list:
        try:
            if dependencies_met(task, completed):
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
