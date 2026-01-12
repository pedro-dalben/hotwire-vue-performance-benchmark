json.extract! @appointment, :id, :beneficiary_name, :professional_name, :unit_name, :starts_at, :status, :notes
json.created_at @appointment.created_at
json.updated_at @appointment.updated_at

