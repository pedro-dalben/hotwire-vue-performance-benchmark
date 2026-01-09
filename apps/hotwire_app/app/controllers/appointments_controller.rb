class AppointmentsController < ApplicationController
  before_action :set_appointment, only: [:show, :edit, :update, :destroy]

  def index
    appointments = Appointment.all
      .by_status(params[:status])
      .by_unit(params[:unit_name])
      .by_date_range(params[:start_date], params[:end_date])
      .search_by_name(params[:q])
      .ordered

    page = params[:page]&.to_i || 1
    per_page = 25
    total = appointments.count
    @pagy = PaginationHelper.new(count: total, page: page, items: per_page)
    @appointments = appointments.offset((page - 1) * per_page).limit(per_page)
  end

  def show
  end

  def new
    @appointment = Appointment.new
  end

  def create
    @appointment = Appointment.new(appointment_params)

    if @appointment.save
      redirect_to @appointment, notice: "Appointment criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @appointment.update(appointment_params)
      redirect_to @appointment, notice: "Appointment atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @appointment.destroy
    redirect_to appointments_url, notice: "Appointment removido com sucesso."
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(:beneficiary_name, :professional_name, :unit_name, :starts_at, :status, :notes)
  end
end
