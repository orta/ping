require 'ipaddr'

class PingResult < ActiveRecord::Base
  include ApplicationHelper
  belongs_to :location
  validates_numericality_of :lag_ms, greater_than_or_equal_to: 0.0
  validates :location_id, numericality: { only_integer: true }
  validates :server_location_id, numericality: { only_integer: true }

  def distance
    c = Location.find(location_id)
    s = Location.find(server_location_id)
    return nil if not c or not s
    return Geocoder::Calculations.distance_between(
      [c.longitude, c.latitude],
      [s.longitude, s.latitude],
      :units => :km
    )
  end
end
