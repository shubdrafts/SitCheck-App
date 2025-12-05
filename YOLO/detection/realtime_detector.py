import os
import cv2
import time
from ultralytics import YOLO
from supabase import create_client, Client
from dotenv import load_dotenv
from datetime import datetime

# Load environment variables
load_dotenv()

# Supabase configuration
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_KEY = os.getenv('SUPABASE_KEY')

if not SUPABASE_URL or not SUPABASE_KEY:
    print("Error: SUPABASE_URL and SUPABASE_KEY must be set in .env file")
    exit(1)

try:
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
except Exception as e:
    print(f"CRITICAL ERROR initializing Supabase: {e}")
    exit(1)

# Configuration
# RTSP URL - REPLACE THIS WITH YOUR ACTUAL RTSP LINK
RTSP_URL = "http://10.56.246.26:8080/video" 

# Path to the NEW trained model
# Relative path from d:\SitCheck-AGv2\YOLO\detection\ to d:\SitCheck-AGv2\New YOLO\runs\detect\sitcheck_model\weights\best.pt
MODEL_PATH = os.path.join(os.path.dirname(__file__), '..', '..', 'New YOLO', 'runs', 'detect', 'sitcheck_model', 'weights', 'best.pt')

TOTAL_TABLES = 3 
RESTAURANT_ID = 'demo-restaurant-123' # Reusing demo ID for now
CONFIDENCE_THRESHOLD = 0.5
PROCESS_INTERVAL = 3.0 # Process 1 frame every 3 seconds

def process_stream():
    print(f"Loading model from: {MODEL_PATH}")
    if not os.path.exists(MODEL_PATH):
        print(f"Error: Model file not found at {MODEL_PATH}")
        return

    # Load YOLO model
    try:
        model = YOLO(MODEL_PATH)
    except Exception as e:
        print(f"Error loading model: {e}")
        return
    
    print(f"Connecting to RTSP stream: {RTSP_URL}")
    print("Note: If this fails, check your RTSP URL and ensure your IP camera is reachable.")

    # Open video stream
    cap = cv2.VideoCapture(RTSP_URL)
    
    if not cap.isOpened():
        print("Error: Could not open RTSP stream.")
        return

    last_process_time = 0
    
    while True:
        # Read frame
        ret, frame = cap.read()
        
        if not ret:
            print("Failed to receive frame from stream. Retrying...")
            time.sleep(1)
            # Try to reconnect
            cap.release()
            cap = cv2.VideoCapture(RTSP_URL)
            continue

        current_time = time.time()
        
        # Process only if interval has passed
        if current_time - last_process_time < PROCESS_INTERVAL:
            # Skip processing, just continue to read frames to clear buffer
            # (Optional: add a small sleep to reduce CPU usage if reading is too fast, 
            # but for RTSP usually we want to keep reading to avoid lag)
            continue
            
        last_process_time = current_time

        # Run YOLO detection
        results = model(frame, conf=CONFIDENCE_THRESHOLD, verbose=False)
        
        # Count detections
        occupied_count = 0
        
        for result in results:
            boxes = result.boxes
            for box in boxes:
                class_id = int(box.cls[0])
                # Assuming 1 is occupied. Adjust if your new model has different classes.
                if class_id == 1:  
                    occupied_count += 1
        
        # Ensure we don't exceed total tables
        occupied_count = min(occupied_count, TOTAL_TABLES)
        vacant_count = TOTAL_TABLES - occupied_count
        
        # Update database
        update_database(occupied_count, vacant_count, TOTAL_TABLES)
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Processed Frame: Occupied={occupied_count}, Vacant={vacant_count}, Total={TOTAL_TABLES}")
    
    cap.release()
    cv2.destroyAllWindows()

import requests

def update_database(occupied, vacant, total):
    # 1. Try to update Local Node.js Server (Fast, works offline)
    try:
        local_data = {
            'restaurant_id': RESTAURANT_ID,
            'occupied': occupied,
            'vacant': vacant,
            'total': total
        }
        requests.post('http://localhost:3000/api/occupancy/update', json=local_data, timeout=1)
    except Exception as e:
        print(f"Local update failed: {e}")

    # 2. Try to update Supabase (Persistent, might fail if network is bad)
    try:
        data = {
            'restaurant_id': RESTAURANT_ID,
            'occupied': occupied,
            'vacant': vacant,
            'total': total,
            'timestamp': datetime.now().isoformat()
        }
        
        # We don't wait for the response to avoid blocking the video loop too long,
        # but here we use .execute() which is synchronous. 
        # For production, might want to run this in a separate thread.
        supabase.table('table_occupancy').insert(data).execute()
        
    except Exception as e:
        print(f"Supabase error: {e}")

if __name__ == "__main__":
    print("Starting Real-Time Table Occupancy Detection...")
    print(f"Model: {MODEL_PATH}")
    print(f"Stream: {RTSP_URL}")
    print("Press Ctrl+C to stop.")
    
    try:
        process_stream()
    except KeyboardInterrupt:
        print("\nStopped by user.")
    except Exception as e:
        print(f"An error occurred: {e}")
    print("Detection completed.")
