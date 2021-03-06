require 'test_helper'

class ShippingQuoteTest < ActiveSupport::TestCase
  PETSY = {country: 'US',state: 'CA', city: 'Beverly Hills', zip: '90210'}
  ADA = {country: 'US',state: 'WA', city: 'Seattle', zip: '98101'}
  TOTAL_QUOTES_FROM_BOTH_UPS_USPS = 12


  ### Tests for initializing ###
  test "should initialize a quote with the required arguments" do

    VCR.use_cassette("active_shipping") do
      package = ActiveShipping::Package.new(7.5 * 16,           # weight
      [12,12,12],         # dimensions
      units: :imperial)   # options
      origin = ActiveShipping::Location.new(PETSY)
      destination = ActiveShipping::Location.new(ADA)

      parcel = ShippingQuote.new(package, origin, destination)

      assert_instance_of ShippingQuote, parcel
    end
  end

  ### Parcel wrapping ###

  # carriers supported: UPS, USPS
  test "#requesting_quote(carrier) should return a JSON of quotes" do

    VCR.use_cassette("active_shipping") do
      carrier = "ups"
      package = ActiveShipping::Package.new(7.5 * 16,           # weight
      [12,12,12],         # dimensions
      units: :imperial)   # options
      origin = ActiveShipping::Location.new(PETSY)
      destination = ActiveShipping::Location.new(ADA)
      parcel = ShippingQuote.new(package, origin, destination)
      quotes = parcel.requesting_quote(carrier) # array of arrays


      assert Array, quotes
      quotes.each do |quote|
        assert Hash, quote
      end
    end
  end

  #Not implemented because the package, origin, destination will be send here from elsewhere in our API
  # test "#requesting_quote(carrier) accepts only arguments with the required data" do
  # end

  test "#requesting_quote will only return valid data from ups" do
    VCR.use_cassette("active_shipping") do
      carrier = "ups"
      package = ActiveShipping::Package.new(7.5 * 16,           # weight
      [12,12,12],         # dimensions
      units: :imperial)   # options
      origin = ActiveShipping::Location.new(PETSY)
      destination = ActiveShipping::Location.new(ADA)
      parcel = ShippingQuote.new(package, origin, destination)

      quotes = parcel.requesting_quote(carrier) # array of arrays

      assert_not_nil quotes

      quotes.each do |quote|
        assert String, quote[0]
        assert Integer, quote[1]
      end
    end
  end

  test "requesting_quote from unknown carrier will return nil" do
    VCR.use_cassette("active_shipping") do
      carrier = "Lucy's cargo"
      package = ActiveShipping::Package.new(7.5 * 16,           # weight
      [12,12,12],         # dimensions
      units: :imperial)   # options
      origin = ActiveShipping::Location.new(PETSY)
      destination = ActiveShipping::Location.new(ADA)
      parcel = ShippingQuote.new(package, origin, destination)

      nil_quotes = parcel.requesting_quote(carrier)

      assert_nil nil_quotes
    end
  end

  # for each of the carriers, except ups above, only one test
  test "#requesting_quote will only return valid data from usps" do
    VCR.use_cassette("active_shipping") do
      carrier = "usps"
      package = ActiveShipping::Package.new(7.5 * 16,           # weight
      [12,12,12],         # dimensions
      units: :imperial)   # options

      origin = ActiveShipping::Location.new(PETSY)
      destination = ActiveShipping::Location.new(ADA)

      parcel = ShippingQuote.new(package, origin, destination)


      quotes = parcel.requesting_quote(carrier) # array of hash
      assert_not_nil quotes
      assert Array, quotes

      quotes.each do |quote|
        assert_instance_of Hash, quote
        assert_equal 2, quote.length #
        assert String, quote[:name]
        assert Integer, quote[:cost]
      end
    end
  end

  test "#carrier_quotes should return supported carriers quotes as an array of quotes" do
    VCR.use_cassette("active_shipping") do
      petsy_carriers = ["ups", "usps"] # the carriers approved by our customer (petsy)
      package = ActiveShipping::Package.new(7.5 * 16,           # weight
                                            [12,12,12],         # dimensions
                                            units: :imperial)   # options
      origin = ActiveShipping::Location.new(PETSY)
      destination = ActiveShipping::Location.new(ADA)

      parcel = ShippingQuote.new(package, origin, destination)

      quotes = parcel.carrier_quotes(petsy_carriers) # array of arrays

      assert Array, quotes
      assert_equal TOTAL_QUOTES_FROM_BOTH_UPS_USPS, quotes.length

      quotes.each do |quote| # to ensure the array is put together correctly
        assert_instance_of Hash, quote
        assert_equal 2, quote.length
        assert String, quote[:name]
        assert Integer, quote[:cost]
      end
    end
  end

  test "should use #setup to initialize the package and origin" do
    VCR.use_cassette("active_shipping") do
      weight = 8
      origin = {city: 'Chicago', state: 'IL'}
      destination = {city: 'Seattle', state: 'Wa'}
      shipment = ShippingQuote.setup(weight, origin, destination)
      assert_equal shipment.origin.to_s, "Chicago, IL"
      assert_equal shipment.destination.to_s, "Seattle, Wa"
      assert_equal shipment.package.weight.to_s, "8 grams"
      assert_instance_of ShippingQuote, shipment
    end
  end
  test "#setup cannot initialize without the appropriate number of arguments" do
    VCR.use_cassette("active_shipping") do
      weight = 8
      origin = {city: 'Chicago', state: 'IL'}
      assert_raise do
        shipment = ShippingQuote.setup(weight, origin)
      end
    end
  end

end
