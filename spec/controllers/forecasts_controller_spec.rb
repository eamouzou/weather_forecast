require 'rails_helper'

RSpec.describe ForecastsController, type: :controller do
    render_views

    describe "GET #index" do
        it "returns http success" do
            get :index

            expect(response).to have_http_status(:success)
        end

        it "renders the index template" do
            get :index

            expect(response).to render_template(:index)
        end

        it "includes address form" do
            get :index

            expect(response.body).to include('form')
            expect(response.body).to include('address')
            expect(response.body).to include('submit')
        end
    end

    describe "Form submission on index page" do
        it "submits to the correct path" do
            get :index

            expect(response.body).to include('action="/forecasts"')
        end

        it "handles GET parameters for address" do
            allow(AddressParser).to receive(:new).and_return(double(parse: { lat: 40.7, lon: -74.0 }))
            allow_any_instance_of(WeatherService).to receive(:get_current_temperature).and_return({})
            allow_any_instance_of(WeatherService).to receive(:get_forecast).and_return({})

            get :index, params: { address: 'New York' }

            # Should trigger weather lookup directly from index with param
            expect(assigns(:current_weather)).not_to be_nil
        end

        it "correctly processes weather data from lookup via GET params" do
            coordinates = { lat: 40.7128, lon: -74.0060 }
            weather_data = {
              temperature: 72.5,
              feels_like: 70.0,
              description: "clear sky",
              from_cache: false
            }
            forecast_data = {
              daily_forecast: [
                { date: "2025-03-05", high: 75, low: 65 }
              ],
              from_cache: false
            }

            allow(AddressParser).to receive(:new).and_return(double(parse: coordinates))
            allow_any_instance_of(WeatherService).to receive(:get_current_temperature)
              .with(lat: coordinates[:lat], lon: coordinates[:lon])
              .and_return(weather_data)
            allow_any_instance_of(WeatherService).to receive(:get_forecast)
              .with(lat: coordinates[:lat], lon: coordinates[:lon])
              .and_return(forecast_data)

            get :index, params: { address: 'New York' }

            expect(assigns(:current_weather)).to eq(weather_data)
            expect(assigns(:current_weather)[:temperature]).to eq(72.5)
            expect(assigns(:forecast)[:daily_forecast][0][:high]).to eq(75)
            expect(assigns(:forecast)[:daily_forecast][0][:low]).to eq(65)
        end

        it "redirects to show action on form submission" do
            post :create, params: { address: 'New York' }

            expect(response).to redirect_to(forecast_path(address: 'New York'))
        end
    end

    describe "GET #show" do
        let(:address_parser) { instance_double(AddressParser) }
        let(:weather_service) { instance_double(WeatherService) }
        let(:coordinates) { { lat: 40.7128, lon: -74.0060, zip_code: '10001' } }
        let(:weather_data) { {
        temperature: 75.5,
        feels_like: 73.2,
        temp_min: 70.1,
        temp_max: 78.3,
        humidity: 65,
        description: 'partly cloudy',
        from_cache: false
        } }
        let(:forecast_data) { {
        daily_forecast: [
            { date: '2025-03-05', high: 80, low: 65, description: 'sunny', humidity: 60 },
            { date: '2025-03-06', high: 75, low: 62, description: 'cloudy', humidity: 70 }
        ],
        from_cache: false
        } }

        before do
            allow(AddressParser).to receive(:new).and_return(address_parser)
            allow(WeatherService).to receive(:new).and_return(weather_service)
            allow(address_parser).to receive(:parse).with('New York').and_return(coordinates)
            allow(weather_service).to receive(:get_current_temperature)
                .with(lat: coordinates[:lat], lon: coordinates[:lon])
                .and_return(weather_data)
            allow(weather_service).to receive(:get_forecast)
                .with(lat: coordinates[:lat], lon: coordinates[:lon])
                .and_return(forecast_data)
        end

        it "returns http success with valid address" do
            get :show, params: { address: 'New York' }

            expect(response).to have_http_status(:success)
        end

        it "assigns complete weather data" do
            get :show, params: { address: 'New York' }

            expect(assigns(:current_weather)).to eq(weather_data)
            expect(assigns(:current_weather)[:temperature]).to eq(75.5)
            expect(assigns(:current_weather)[:description]).to eq('partly cloudy')
            expect(assigns(:current_weather)[:from_cache]).to eq(false)

            expect(assigns(:forecast)).to eq(forecast_data)
            expect(assigns(:forecast)[:daily_forecast].length).to eq(2)
            expect(assigns(:forecast)[:daily_forecast][0][:date]).to eq('2025-03-05')
            expect(assigns(:forecast)[:daily_forecast][0][:high]).to eq(80)
        end

        it "assigns location data" do
            get :show, params: { address: 'New York' }

            expect(assigns(:location)).to include(address: 'New York')
            expect(assigns(:location)).to include(zip_code: '10001')
        end

        it "handles cached weather data correctly" do
            cached_weather = weather_data.merge(from_cache: true)
            cached_forecast = forecast_data.merge(from_cache: true)

            allow(weather_service).to receive(:get_current_temperature)
                .with(lat: coordinates[:lat], lon: coordinates[:lon])
                .and_return(cached_weather)

            allow(weather_service).to receive(:get_forecast)
                .with(lat: coordinates[:lat], lon: coordinates[:lon])
                .and_return(cached_forecast)

            get :show, params: { address: 'New York' }

            expect(assigns(:current_weather)[:from_cache]).to eq(true)
            expect(assigns(:forecast)[:from_cache]).to eq(true)
        end

        it "redirects to root with flash error when address parsing fails" do
            allow(address_parser).to receive(:parse).with('Invalid').and_raise(StandardError, "Invalid address")

            get :show, params: { address: 'Invalid' }

            expect(response).to redirect_to(root_path)
            expect(flash[:error]).to match(/Invalid address/)
        end

        it "redirects when weather service fails" do
            allow(weather_service).to receive(:get_current_temperature)
                .and_raise(StandardError, "API error")

            get :show, params: { address: 'New York' }

            expect(response).to redirect_to(root_path)
            expect(flash[:error]).to match(/API error/)
        end
    end
end
