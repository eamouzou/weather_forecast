require 'rails_helper'
require 'cgi'

RSpec.describe "Forecasts", type: :request do
  let(:valid_address) { "New York" }
  let(:valid_zip) { "10001" }
  let(:invalid_address) { "XYZ123InvalidLocation" }

  describe "GET /forecasts" do
    it "renders the index page with form" do
      get "/forecasts"
      expect(response).to have_http_status(:success)
      expect(response.body).to include('form')
      expect(response.body).to include('address')
    end

    context "with GET parameters (mocked)" do
      before do
        allow_any_instance_of(AddressParser).to receive(:parse)
          .with(anything)
          .and_return({ lat: 40.7, lon: -74.0 })

        allow_any_instance_of(WeatherService).to receive(:get_current_temperature)
          .and_return({
            temperature: 72.5,
            feels_like: 70.0,
            description: "clear sky",
            from_cache: false
          })

        allow_any_instance_of(WeatherService).to receive(:get_forecast)
          .and_return({
            daily_forecast: [
              { date: "2025-03-05", high: 75, low: 65, description: "sunny", humidity: 50 }
            ],
            from_cache: false
          })
      end

      it "shows weather data when valid address provided" do
        get "/forecasts", params: { address: valid_address }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Current Weather')
        expect(response.body).to include('5-Day Forecast')
      end

      it "shows weather data when valid ZIP provided" do
        get "/forecasts", params: { address: valid_zip }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Current Weather')
      end
    end
  end

  describe "POST /forecasts" do
    it "redirects to show page with address" do
      post "/forecasts", params: { address: valid_address }

      expect(response).to redirect_to(forecast_path(address: valid_address))
    end
  end

  describe "GET /forecasts/:id" do
    before do
      allow_any_instance_of(AddressParser).to receive(:parse)
        .with(anything)
        .and_return({ lat: 40.7, lon: -74.0 })

      allow_any_instance_of(WeatherService).to receive(:get_current_temperature)
        .and_return({
          temperature: 72.5,
          feels_like: 70.0,
          description: "clear sky",
          from_cache: false
        })

      allow_any_instance_of(WeatherService).to receive(:get_forecast)
        .and_return({
          daily_forecast: [
            { date: "2025-03-05", high: 75, low: 65, description: "sunny", humidity: 50 }
          ],
          from_cache: false
        })
    end

    it "shows detailed forecast for valid address" do
      get "/forecasts/#{CGI.escape(valid_address)}"

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Current Weather')
      expect(response.body).to include('5-Day Forecast')
    end

    it "redirects on invalid address" do
      allow_any_instance_of(AddressParser).to receive(:parse)
        .with(invalid_address)
        .and_raise(StandardError, "Invalid address")

      get "/forecasts/#{CGI.escape(invalid_address)}"

      expect(response).to redirect_to(root_path)
      expect(flash[:error]).to be_present
    end
  end

  describe "cache behavior" do
    before do
      allow_any_instance_of(AddressParser).to receive(:parse)
        .with(anything)
        .and_return({ lat: 40.7, lon: -74.0 })

      allow_any_instance_of(WeatherService).to receive(:get_current_temperature)
        .and_return({
          temperature: 72.5,
          feels_like: 70.0,
          description: "sunny",
          from_cache: true
        })

      allow_any_instance_of(WeatherService).to receive(:get_forecast)
        .and_return({
          daily_forecast: [
            { date: "2025-03-05", high: 75, low: 65, description: "sunny", humidity: 50 }
          ],
          from_cache: true
        })
    end

    it "shows cached data correctly" do
      get "/forecasts", params: { address: "Any Address" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Cached Result')
    end
  end
end
