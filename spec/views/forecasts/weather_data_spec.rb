# spec/views/forecasts/weather_data_spec.rb
RSpec.describe "forecasts/_weather_data", type: :view do
    context "with weather data" do
        before do
            assign(:current_weather, {
            temperature: 75.5,
            feels_like: 73.2,
            temp_min: 70.1,
            temp_max: 78.3,
            humidity: 65,
            description: 'partly cloudy',
            from_cache: false
            })
        
            assign(:forecast, {
            daily_forecast: [
                {date: '2025-03-05', high: 80, low: 65, description: 'sunny', humidity: 60},
                {date: '2025-03-06', high: 75, low: 62, description: 'cloudy', humidity: 70}
            ],
            from_cache: false
            })
            
            assign(:location, {
            address: 'New York',
            zip_code: '10001'
            })
        end
      
        it "displays current temperature information" do
            render partial: 'forecasts/weather_data'
            
            expect(rendered).to have_content('76°F') # Rounded from 75.5
            expect(rendered).to have_content('Feels like: 73°F')
            expect(rendered).to have_content('H: 78°F')
            expect(rendered).to have_content('L: 70°F')
        end
      
        it "displays location information" do
            render partial: 'forecasts/weather_data'
            
            expect(rendered).to have_content('New York')
            expect(rendered).to have_content('ZIP: 10001')
        end
      
        it "displays weather conditions" do
            render partial: 'forecasts/weather_data'
            
            expect(rendered).to have_content('partly cloudy')
            expect(rendered).to have_content('Humidity: 65%')
        end
      
        it "displays forecast data" do
            render partial: 'forecasts/weather_data'
            
            expect(rendered).to have_selector('table')
            expect(rendered).to have_content('sunny')
            expect(rendered).to have_content('cloudy')
            expect(rendered).to have_content('80°F')
            expect(rendered).to have_content('62°F')
        end
        
        it "indicates that data is fresh" do
            render partial: 'forecasts/weather_data'
            
            expect(rendered).to have_content('Fresh Data')
            expect(rendered).not_to have_content('Cached Result')
        end
    end
      
    context "with cached data" do
        before do
            assign(:current_weather, {
                temperature: 75.5,
                feels_like: 73.2,
                description: 'partly cloudy',
                from_cache: true
            })
            
            assign(:forecast, {
                daily_forecast: [
                {date: '2025-03-05', high: 80, low: 65, description: 'sunny', humidity: 60}
                ],
                from_cache: true
            })

            assign(:location, {
                address: 'New York',
                zip_code: '10001'
            })
        end
        
        it "indicates that data is cached" do
            render partial: 'forecasts/weather_data'
            
            expect(rendered).to have_content('Cached Result')
            expect(rendered).not_to have_content('Fresh Data')
        end
    end
    
    context "without weather data" do
        before do
            assign(:current_weather, nil)
            assign(:forecast, nil)
        end
        
        it "displays a message when no data is available" do
            render partial: 'forecasts/weather_data'
            
            expect(rendered).to have_content('No weather data available')
        end
    end
    
    context "with partial weather data" do
        before do
            assign(:current_weather, {
            description: 'partly cloudy',
            from_cache: false
            })
            
            assign(:forecast, {
            daily_forecast: [],
            from_cache: false
            })
            
            assign(:location, {
            address: 'New York'
            })
        end
      
        it "handles missing temperature data gracefully" do
            render partial: 'forecasts/weather_data'
            
            expect(rendered).to have_content('N/A°F')
        end
      
        it "handles empty forecast data gracefully" do
            render partial: 'forecasts/weather_data'
            
            expect(rendered).to have_content('No forecast data available')
        end
    end
end
