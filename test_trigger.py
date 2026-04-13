import requests

BASE = "http://localhost:8000"

def trace():
    print("1. Register worker")
    w = requests.post(f"{BASE}/api/v1/workers/register", json={
        "name": "Trace Worker",
        "phone": "9998887779",
        "upi_id": "trace@upi",
        "zone_id": 1
    })
    
    if w.status_code == 409:
        w = requests.post(f"{BASE}/api/v1/workers/login", json={"phone": "9998887779"})
        
    print(w.json())
    worker_id = w.json()["id"]
    
    print("\n2. Enroll Policy")
    p = requests.post(f"{BASE}/api/v1/policies/enroll", json={"worker_id": worker_id})
    print(p.status_code, p.text)
    
    print("\n3. Simulate Trigger")
    t = requests.post(f"{BASE}/api/v1/admin/simulate-trigger", json={
        "zone_id": 1,
        "event_type": "Rain",
        "severity": "High"
    })
    print(t.status_code, t.text)

if __name__ == "__main__":
    trace()
