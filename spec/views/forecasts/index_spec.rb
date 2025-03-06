# spec/views/forecasts/index_spec.rb
require 'rails_helper'

RSpec.describe "forecasts/index", type: :view do
  it "displays the search form" do
    render
    
    expect(rendered).to have_selector('form[action="/forecasts"]')
    expect(rendered).to have_field('address')
    expect(rendered).to have_button('Get Weather')
  end
  
  it "provides instructions for the user" do
    render
    
    expect(rendered).to have_content('Enter a full address, city name, or a 5-digit ZIP code')
  end
  
  context "with weather data" do
    before do
      assign(:current_weather, {
        temperature: 75.5,
        feels_like: 73.2,
        description: 'partly cloudy',
        from_cache: false
      })
      
      assign(:forecast, {
        daily_forecast: [
          {date: '2025-03-05', high: 80, low: 65, description: 'sunny', humidity: 60}
        ],
        from_cache: false
      })
      
      assign(:location, {
        address: 'New York',
        zip_code: '10001'
      })
    end
    
    it "renders the weather data partial" do
      render
      
      expect(rendered).to have_content('Current Weather')
      expect(rendered).to have_content('5-Day Forecast')
    end
  end
  
  context "with flash errors" do
    before do
      flash[:error] = "Error retrieving weather data"
    end
    
    it "displays error messages" do
      render
      
      expect(rendered).to have_selector('.alert.alert-danger')
      expect(rendered).to have_content('Error retrieving weather data')
    end
  end
end
