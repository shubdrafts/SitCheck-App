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
# Path to the video file
VIDEO_PATH = os.path.join(os.path.dirname(__file__), '..', 'my_model', 'Test.mp4')
# Path to the trained model
MODEL_PATH = os.path.join(os.path.dirname(__file__), '..', 'my_model', 'train', 'weights', 'best.pt')

TOTAL_TABLES = 3 
RESTAURANT_ID = 'demo-restaurant-123'
CONFIDENCE_THRESHOLD = 0.5

def process_video():
    print(f"Loading model from: {MODEL_PATH}")
    if not os.path.exists(MODEL_PATH):
        print(f"Error: Model file not found at {MODEL_PATH}")
        return

    # Load YOLO model
    model = YOLO(MODEL_PATH)
    
    print(f"Opening video from: {VIDEO_PATH}")
    if not os.path.exists(VIDEO_PATH):
        print(f"Error: Video file not found at {VIDEO_PATH}")
        return

    # Open video
    cap = cv2.VideoCapture(VIDEO_PATH)
    fps = cap.get(cv2.CAP_PROP_FPS)
    print(f"Video FPS: {fps}")
    
    frame_count = 0
    
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            print("Video finished or failed to read.")
            break
            
        # Process only 1 frame per second (approx)
        # If FPS is 30, we process frame 0, 30, 60...
        if frame_count % int(fps) != 0:
            frame_count += 1
            continue

        # Run YOLO detection
        results = model(frame, conf=CONFIDENCE_THRESHOLD, verbose=False)
        
        # Count detections
        occupied_count = 0
        
        for result in results:
            boxes = result.boxes
            for box in boxes:
                # Check if table is occupied (based on your model classes)
                class_id = int(box.cls[0])
                # Adjust this logic based on your actual model classes
                # Assuming 1 is occupied based on previous code context, but verify if needed.
                if class_id == 1:  
                    occupied_count += 1
        
        # Ensure we don't exceed total tables
        occupied_count = min(occupied_count, TOTAL_TABLES)
        vacant_count = TOTAL_TABLES - occupied_count
        
        # Update database
        update_database(occupied_count, vacant_count, TOTAL_TABLES)
        print(f"Processed Frame {frame_count}: Occupied={occupied_count}, Vacant={vacant_count}, Total={TOTAL_TABLES}")
            
        frame_count += 1
    
    cap.release()
    cv2.destroyAllWindows()

def update_database(occupied, vacant, total):
    try:
        data = {
            'restaurant_id': RESTAURANT_ID,
            'occupied': occupied,
            'vacant': vacant,
            'total': total,
            'timestamp': datetime.now().isoformat()
        }
        
        response = supabase.table('table_occupancy').insert(data).execute()
        return response
    except Exception as e:
        print(f"Database error: {e}")

if __name__ == "__main__":
    print("Starting table occupancy detection...")
    try:
        process_video()
    except KeyboardInterrupt:
        print("\nStopped by user.")
    except Exception as e:
        print(f"An error occurred: {e}")
    print("Detection completed.")

