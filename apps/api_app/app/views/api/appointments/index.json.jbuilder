json.meta do
  json.total @pagy.count
  json.page @pagy.page
  json.per_page @pagy.items
  json.pages @pagy.pages
  json.prev_page @pagy.prev
  json.next_page @pagy.next
end

json.data @appointments do |appointment|
  json.extract! appointment, :id, :beneficiary_name, :professional_name, :unit_name, :starts_at, :status, :notes
  json.created_at appointment.created_at
  json.updated_at appointment.updated_at
end
