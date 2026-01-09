require 'json'

seed_file = Rails.root.join('..', '..', 'benchmark', 'seed_data.json')
unless File.exist?(seed_file)
  puts "Erro: seed_data.json não encontrado em #{seed_file}"
  puts "Execute: python3 benchmark/generate_seed_data.py"
  exit 1
end

data = JSON.parse(File.read(seed_file))
appointments_data = data['appointments']

puts "Criando #{appointments_data.length} appointments..."

Appointment.transaction do
  appointments_data.each_with_index do |appt_data, idx|
    appointment = Appointment.new(
      beneficiary_name: appt_data['beneficiary_name'],
      professional_name: appt_data['professional_name'],
      unit_name: appt_data['unit_name'],
      starts_at: DateTime.parse(appt_data['starts_at']),
      status: appt_data['status'],
      notes: appt_data['notes'] || ''
    )
    appointment.save!(validate: false)
  end
end

puts "Seeds concluídos! #{Appointment.count} appointments criados."
