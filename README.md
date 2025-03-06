# Weather Forecast Application

A Ruby on Rails application that retrieves and displays weather forecasts based on user-provided addresses or ZIP codes, with 30-minute caching for improved performance.

## Features

- 📍 Accept addresses or ZIP codes as input
- 🌡️ Display current temperature and conditions
- 📆 Show 5-day weather forecast with high/low temperatures
- 🔄 Cache results for 30 minutes with visual status indicators
- 🔍 Location autocomplete with smart suggestions
- 🕒 Recent search history tracking
- 📱 Responsive design for all devices

## Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Architecture](#architecture)
- [Testing](#testing)
- [API Limits](#api-limits)
- [Future Enhancements](#future-enhancements)

## Installation

### Prerequisites

- Ruby 3.2.2+
- Rails 8.0.1+
- PostgreSQL database
- OpenWeatherMap API

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/weather_forecast.git
   cd weather_forecast
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Setup the database:
   ```bash
   rails db:create
   rails db:migrate
   ```

4. Start the server:
   ```bash
   rails server
   ```

5. Visit [http://localhost:3000](http://localhost:3000) in your browser

## Configuration

### API Keys

The application uses the OpenWeatherMap API. You'll need to obtain an API key:

1. Register at [OpenWeatherMap](https://openweathermap.org/api) to get a free API key
2. Set your API key in one of the following ways:

   **Environment Variable (recommended):**
   ```bash
   export OPENWEATHER_API_KEY=your_api_key
   ```

   **Config File:**
   Update `config/initializers/weather_api.rb` with your API key:
   ```ruby
   Rails.application.config.after_initialize do
     Rails.application.config.weather_api = {
       api_key: ENV['OPENWEATHER_API_KEY'] || 'your_api_key_here',
       base_url: 'https://api.openweathermap.org/data/2.5'
     }
   end
   ```

### Caching Configuration

The application uses Rails' built-in caching with a 30-minute expiration:
- In development: Memory store with 64MB capacity
- In production: Should be configured to use Redis or Memcached

## Usage

1. Visit the homepage and enter a location in the search box
   - You can enter a city name (e.g., "New York")
   - A full address (e.g., "123 Main St, Boston, MA")
   - Or a 5-digit ZIP code (e.g., "10001")

2. The application will display:
   - Current temperature and conditions
   - Detailed weather metrics (wind, pressure, humidity)
   - 5-day forecast with high/low temperatures
   - An indicator showing if the data is from cache

3. Recent searches are saved for quick access

## Architecture

### Object Decomposition

The application follows a service-oriented architecture with clear separation of concerns:

```
┌─────────────────┐       ┌─────────────────┐      ┌─────────────────┐
│  Controllers    │       │    Services     │      │      APIs       │
│  ┌───────────┐  │       │  ┌───────────┐  │      │  ┌───────────┐  │
│  │ Forecasts │──┼───────┼──► Address   │  │      │  │OpenWeather│  │
│  │ Controller│  │       │  │ Parser    │──┼──────┼──► Geocoding │  │
│  └───────────┘  │       │  └───────────┘  │      │  └───────────┘  │
│                 │       │                 │      │                 │
│                 │       │  ┌───────────┐  │      │  ┌───────────┐  │
│                 │       │  │ Geocoding │──┼──────┼──►OpenWeather│  │
│                 │       │  │ Service   │  │      │  │   API     │  │
│                 │       │  └───────────┘  │      │  └───────────┘  │
│                 │       │                 │      │                 │
│                 │       │  ┌───────────┐  │      │                 │
│                 │       │  │ Weather   │──┼──────┘                 │
│                 │       │  │ Service   │  │                        │
│                 │       │  └───────────┘  │                        │
└─────────────────┘       └─────────────────┘                        │
                                                                     │
┌────────────────┐        ┌────────────────┐                         │
│     Views      │        │    Helpers     │                         │
│  ┌──────────┐  │        │  ┌──────────┐  │                         │
│  │  Index   │  │        │  │  Weather │  │                         │
│  └──────────┘  │        │  │  Helper  │  │                         │
│  ┌──────────┐  │        │  └──────────┘  │                         │
│  │   Show   │  │        └────────────────┘                         │
│  └──────────┘  │                                                   │
│  ┌──────────┐  │        ┌────────────────┐                         │
│  │ Weather  │  │        │    Caching     │                         │
│  │  Partial │  │        │  ┌──────────┐  │                         │
│  └──────────┘  │        │  │ Rails    │  │                         │
└────────────────┘        │  │ Cache    │  │                         │
                          │  └──────────┘  │                         │
                          └────────────────┘                         │
                                                                     │
                                                                     │
```

### Key Components

1. **ForecastsController**: Handles user requests, manages flow between services and views
2. **AddressParser**: Determines if input is a ZIP code or address, routes accordingly
3. **GeocodingService**: Converts addresses/ZIP codes to coordinates via OpenWeatherMap API
4. **WeatherService**: Fetches weather data and manages caching
5. **WeatherHelper**: Provides view helpers for formatting weather data
6. **Views**: Present weather data with responsive design

### Design Patterns

- **Service Objects Pattern**: Clear separation of business logic from controllers
- **Adapter Pattern**: GeocodingService and WeatherService adapt external APIs to our domain
- **Decorator Pattern**: WeatherHelper adds presentation logic to weather data
- **Repository Pattern**: Services abstract data access behind consistent interfaces
- **Template Method Pattern**: WeatherService uses a template method for caching

## Testing

The application includes comprehensive tests using RSpec:

- **Controller Tests**: Verify controller actions and response handling
- **Service Tests**: Ensure services correctly interact with APIs
- **Helper Tests**: Validate formatting functions
- **View Tests**: Check proper rendering of data
- **Request Tests**: End-to-end verification of functionality

Run the test suite with:

```bash
bundle exec rspec
```

## API Limits

### OpenWeatherMap Free Tier

- 60 API calls per minute
- 1,000 API calls per day for One Call API 3.0

### Implemented Optimizations:

- **Caching**: Results are cached for 30 minutes to reduce API calls
- **Minimal API Requests**: Each weather check requires 2 API calls (geocoding + weather)
- **Recent Searches**: Allows users to quickly access previous searches without new API calls

## Future Enhancements

### Performance Improvements

- Background processing for API calls using Sidekiq
- More granular caching with partial updates
- Advanced cache invalidation strategies

### Feature Extensions

- User accounts to save favorite locations
- Weather alerts for saved locations
- Historical weather data comparison
- Weather maps and visualizations
- Dark mode toggle

### Architecture Improvements

- API rate limiting and throttling
- GraphQL API for more efficient data retrieval
- React/Vue frontend for more interactive experience
