# Weather Forecast Application

A Ruby on Rails application that displays weather forecasts based on user-provided addresses.

## Features
- Accept address as input
- Retrieve current temperature from OpenWeatherMap API
- Display forecast details to the user
- 30-minute caching of forecast data by zip code
- Cache status indicator
- Bonus: High/low temperatures and extended forecast

## Technologies
- Ruby 3.2.2
- Rails 8.0.1
- PostgreSQL
- OpenWeatherMap API
- Redis for caching

## Setup
1. Clone this repository
2. Install dependencies: `bundle install`
3. Setup database: `rails db:create db:migrate`
4. Configure environment:
  - Create `.env` file with your OpenWeatherMap API key:
    ```
    OPENWEATHER_API_KEY=your_api_key_here
    ```
5. Start server: `rails server`
6. Visit `http://localhost:3000`

## Testing
Run the test suite with:
- rspec

## Design Patterns
- Service Objects for API interactions
- Repository Pattern for data access
- Decorator Pattern for formatting weather data

## Code Standards
- Comprehensive test coverage
- Clear documentation
- Proper encapsulation and separation of concerns
- Industry-standard naming conventions
- RESTful design

## Project Structure
- Services handle API interactions and business logic
- Controllers coordinate data flow
- Simple views display forecast information
- Caching layer improves performance