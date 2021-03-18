class BookingsController < ApplicationController
  before_action :set_booking, only: %i[ show edit update destroy ]
  before_action :authenticate_user!
  before_action :is_guest?, only: [:show, :edit, :destroy, :update]
  before_action :start_date_is_possible?, only: [:create, :update, :edit]

  def show
  end

  def new
    @booking = Booking.new
    @space = set_space
  end

  def edit
  end

  def create
    @booking = Booking.new(booking_params)
    @booking.guest_id = current_user.id
    @booking.space_id = params[:space_id]
    
    if @booking.save
        redirect_to spaces_path, notice: "La réservation a bien été créée, retrouvez vous réservations dans votre page Profil."
      else
        render :new, status: :unprocessable_entity 
      end
    UserMailer.booking_email(current_user.id).deliver_now
  end

  def update
    if @booking.update(booking_params)
      redirect_to @booking, notice: "La réservation a bien été mise à jour." 
    else
      render :edit, status: :unprocessable_entity 
    end
  end

  def destroy
    @booking.destroy
    redirect_to bookings_url, notice: "La réservation a bien été annulée. " 
  end

  private
    
  def set_booking
    @booking = Booking.find(params[:id])
  end

  def set_space
    @space = Space.find(params[:space_id])
  end

  def booking_params
    params.permit(:start_date, :space_id)
  end

  def is_guest?
    @booking = set_booking
    unless @booking.guest_id == current_user.id
      flash[:danger] = "Vous n'êtes pas autorisé à modifier cette réservation."
      redirect_to root_path
    end
  end

  def start_date_is_possible?
    if params[:start_date] < DateTime.now 
      flash[:alert] = "Vous ne pouvez pas effectuer de réservation à cette date."
      redirect_to new_space_booking_path(params[:space_id])
      return false
    end
    booking = Booking.where(start_date: params[:start_date], space_id: params[:space_id])
    if booking.length > 0
      flash[:alert] = "L'espace est déjà loué à cette date."
      redirect_to new_space_booking_path(params[:space_id])
    end
  end
end
