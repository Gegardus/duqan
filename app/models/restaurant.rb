class Restaurant < ApplicationRecord
  acts_as_mappable default_units: :meters,
                   default_formula: :sphere,
                   distance_field_name: :distance,
                   lat_column_name: :lat,
                   lng_column_name: :lng

  has_many :managers, -> { where(role: 'manager') }
  has_one :seats_configuration, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :seats, through: :seats_configuration, dependent: :destroy
  has_one :menu

  validates_presence_of :title

  before_create :tap_configuration
  before_create :tap_menu

  def distances(current_user)
    distances_arr = []

    @restaurants = Restaurant.all
    @restaurants.each do |a|
      distances_arr << a.distance_from(current_user, units: :meters).to_i
    end
    distances_arr.map(&:to_i).sort
  end
end

def rating
  Review.all.where(restaurant_id: id).average(:rating).to_f
end

  private

def tap_configuration
  build_seats_configuration
end

def tap_menu
  build_menu
end
