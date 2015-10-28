require 'test_helper'

class GeocoderStub
  PreparedResponses = {
    '8.8.8.8' => {
      :ip_address => true,
      :data =>
        {"dma_code"=>"0", "ip"=>"8.8.8.8", "asn"=>"AS15169", "city"=>"Mountain View", "latitude"=>37.386, "country_code"=>"US", "offset"=>"-7", "country"=>"United States", "region_code"=>"CA", "isp"=>"Google Inc.", "timezone"=>"America/Los_Angeles", "area_code"=>"0", "continent_code"=>"NA", "longitude"=>-122.0838, "region"=>"California", "postal_code"=>"94040", "country_code3"=>"USA"},
      :error => nil
    },
    'www.google.com' => {
      :ip_address => true,
      :data => nil,
      :error => '400 Bad Request'
    },
    'Paris, France' => {
      :ip_address => false,
      :data =>
        {"types"=>["locality", "political"], "geometry"=>{"location"=>{"lat"=>48.85341, "lng"=>2.3488}, "location_type"=>"APPROXIMATE", "viewport"=>{"southwest"=>{"lat"=>48.796009, "lng"=>2.216784}, "northeast"=>{"lat"=>48.921822, "lng"=>2.485605}}}, "address_components"=>[{"short_name"=>"Paris", "types"=>["locality", "political"], "long_name"=>"Paris, FR"}, {"short_name"=>"FR", "types"=>["country", "political"], "long_name"=>"France"}]},
      :error => nil
    },
    '216.58.216.4' => {
      :ip_address => true,
      :data =>
        {"dma_code"=>"0", "ip"=>"216.58.216.4", "asn"=>"AS15169", "city"=>"Mountain View", "latitude"=>37.4192, "country_code"=>"US", "offset"=>"-7", "country"=>"United States", "region_code"=>"CA", "isp"=>"Google Inc.", "timezone"=>"America/Los_Angeles", "area_code"=>"0", "continent_code"=>"NA", "longitude"=>-122.0574, "region"=>"California", "postal_code"=>"94043", "country_code3"=>"USA"},
      :error => nil
    },
  }

  # result to be used in app/models/location.rb
  def self.search(query, opts = {})
    pr = PreparedResponses[query]
    return [nil] unless pr
    return [nil] unless (!opts[:ip_address] == !pr[:ip_address])	# !: I want false and nil to be equal here
    return [nil] if pr[:error]  # Geocoder gem does not raise an error
    def pr.address
      data = self[:data]
      if data['city']
        return "#{data['city']}, #{data['region_code']} #{data['postal_code']}, #{data['country']}"
      end
      return nil
    end
    def pr.city
      data = self[:data]
      if data['address_components']
        return data['address_components'][0]['long_name']
      end
      return nil
    end
    def pr.longitude
      self[:data]['longitude'] || self[:data]['geometry']['location']['lng']
    end
    def pr.latitude
      self[:data]['latitude'] || self[:data]['geometry']['location']['lat']
    end
    return [pr]
  end
end

class ResolvStub
  PreparedResponses = {
    'www.google.com' => '216.58.216.4'
  }

  def self::getaddress(ipaddress)
    return PreparedResponses[ipaddress]
  end
end

class LocationTest < ActiveSupport::TestCase
  # Use stubs instead of real external resources
  Location::geocoder = GeocoderStub
  Location::resolver = ResolvStub

  test "location is geocoded with city, longitude, and latitude" do
    l = Location.new(:city => 'foo', :longitude => 0.0, :latitude => 0.0)
    assert l.geocoded?, "Location with enough information shows not geocoded"
  end

  test "location is not geocoded without city" do
    l = Location.new(:city => nil, :longitude => 0.0, :latitude => 0.0)
    assert_not l.geocoded?, "Location without city shows geocoded"
  end

  test "location is not geocoded without coordinates" do
    l = Location.new(:city => 'foo', :longitude => nil, :latitude => nil)
    assert_not l.geocoded?, "Location without coordinate shows geocoded"
  end

  test "looking up an IP address should return a valid location" do
    l = Location.new(:host => '8.8.8.8')
    l.geocode_from_host!
    assert l.geocoded?
  end

  test "looking up FQDN shuold return a valid location" do
    l = Location.new(:host => 'www.google.com')
    l.geocode_from_host!
    assert l.geocoded?
  end

  test "looking up a city name should return a valid location" do
    l = Location.new(:city => 'Paris, France')
    l.geocode_from_city!
    assert l.geocoded?
  end
end
