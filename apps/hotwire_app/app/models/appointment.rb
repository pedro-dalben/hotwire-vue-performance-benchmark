class Appointment < ApplicationRecord
  enum :status, {
    scheduled: 'scheduled',
    confirmed: 'confirmed',
    canceled: 'canceled',
    done: 'done'
  }

  validates :beneficiary_name, presence: true, length: { minimum: 3 }
  validates :professional_name, presence: true, length: { minimum: 3 }
  validates :starts_at, presence: true
  validate :starts_at_not_in_past

  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_unit, ->(unit) { where(unit_name: unit) if unit.present? }
  scope :by_date_range, ->(start_date, end_date) {
    where(starts_at: start_date..end_date) if start_date.present? && end_date.present?
  }
  scope :search_by_name, ->(q) {
    where("beneficiary_name ILIKE ?", "%#{q}%") if q.present?
  }
  scope :ordered, -> { order(starts_at: :asc) }

  private

  def starts_at_not_in_past
    return unless starts_at.present?
    errors.add(:starts_at, "não pode ser no passado") if starts_at < Time.zone.now
  end
end
