#!/usr/bin/env python3
import json
import random
from datetime import datetime, timedelta

BASE_DATE = datetime(2026, 1, 1, 0, 0, 0)
random.seed(42)

beneficiaries = [f"Beneficiário {i+1}" for i in range(50)]
professionals = [f"Profissional {i+1}" for i in range(20)]
units = [f"Unit {i+1}" for i in range(5)]
statuses = ['scheduled', 'confirmed', 'canceled', 'done']
status_weights = [0.4, 0.3, 0.1, 0.2]

appointments = []

for i in range(5000):
    days_offset = random.randint(-60, 60)
    hours_offset = random.randint(0, 23)
    minutes_offset = random.choice([0, 15, 30, 45])

    starts_at = BASE_DATE + timedelta(days=days_offset, hours=hours_offset, minutes=minutes_offset)

    status = random.choices(statuses, weights=status_weights)[0]

    appointment = {
        'beneficiary_name': random.choice(beneficiaries),
        'professional_name': random.choice(professionals),
        'unit_name': random.choice(units),
        'starts_at': starts_at.isoformat(),
        'status': status,
        'notes': f"Nota {i+1}" if i % 10 == 0 else ""
    }

    appointments.append(appointment)

output = {
    'generated_at': datetime.now().isoformat(),
    'base_date': BASE_DATE.isoformat(),
    'total': len(appointments),
    'appointments': appointments
}

with open('seed_data.json', 'w', encoding='utf-8') as f:
    json.dump(output, f, indent=2, ensure_ascii=False)

print(f"Generated {len(appointments)} appointments in seed_data.json")
