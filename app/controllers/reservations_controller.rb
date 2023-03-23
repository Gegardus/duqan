class ReservationsController < ApplicationController
  before_action :set_reservation, only: %i[show edit update destroy]
  before_action :set_restaurant, only: %i[create index]
  before_action :set_seat_info, only: [:create]

  def index
    @reservations = current_user.reservations.where(restaurant_id: params[:restaurant_id]).all
  end

  def show; end

  def create
    friends = params.select { |key| key.to_s.include?('friendship') }
    @friends_info = friends.values.select { |values| values[:selected] }

    ActiveRecord::Base.transaction do
      @reservation = Reservation.create(date: reservation_params[:date],
                                        duration: reservation_params[:duration][0],
                                        restaurant_id: @restaurant.id,
                                        user_id: current_user.id)

      @seat_info.each do |seat|
        seat = @restaurant.seats_configuration.seats.where(x: seat[:x],
                                                           y: seat[:y]).first

        seat.with_lock do
          if seat.reserved?(reservation_params[:date])
            redirect_to @restaurant,
                        alert: 'Some seats have been reserved meanwhile. We are sorry for the inconvenience'
          end
          if @reservation.date
            seat.reservations << @reservation

          else
            flash[:alert] = 'Please add date'
          end
        end
      end

      @friends_info.each do |friend|
        friend = Guest.where(id: friend[:friend_id]).first

        invitation = friend.invitations.create!(user_id: friend.id,
                                                reservation_id: @reservation.id,
                                                confirmed: nil)
        InvitationMailer.invitation_mail(friend, invitation).deliver_now
      end
      if @reservation.save
        redirect_to @restaurant, notice: 'Reservation was successfully created.'

      else

        flash[:alert] = 'Something went wrong'

      end
    end
  end

  def update
    respond_to do |format|
      if @reservation.update(reservation_params)
        format.html { redirect_to @restaurant, notice: 'Reservation was successfully updated.' }
        format.json { render :show, status: :ok, location: @reservation }
      else
        format.html { redirect_to @restaurant }
        format.json { render json: @reservation.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  def set_seat_info
    seats = params.select { |key| key.to_s.include?('seat') }
    @seat_info = seats.values.select { |values| values[:reserved] }
  end

  def set_restaurant
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def reservation_params
    params.require(:reservation).permit(:date, :duration)
  end
end
