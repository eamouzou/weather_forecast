# Weather Forecast Application

A Ruby on Rails application that retrieves and displays weather forecasts based on user-provided addresses or ZIP codes, with Redis caching and background job processing for improved performance and scalability.

## Features

- 📍 Accept addresses or ZIP codes as input
- 🌡️ Display current temperature and conditions
- 📆 Show 5-day weather forecast with high/low temperatures
- 🔄 Redis-based caching with visual status indicators
- 🔍 Location autocomplete with smart suggestions
- 🕒 Recent search history tracking
- 📱 Responsive design for all devices
- 🔧 Background jobs for asynchronous processing
- 🛡️ Enhanced error handling with custom error types

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
- Redis server
- OpenWeatherMap API

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/eamouzou/weather_forecast.git
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

4. Start Redis server:
   ```bash
   redis-server
   ```

5. Start Sidekiq worker:
   ```bash
   bundle exec sidekiq
   ```

6. Start the Rails server:
   ```bash
   rails server
   ```

7. Visit [http://localhost:3000](http://localhost:3000) in your browser

## Configuration

### API Keys

The application uses the OpenWeatherMap API. You'll need to obtain an API key:

1. Register at [OpenWeatherMap](https://openweathermap.org/api) to get a free API key
2. Set your API key in one of the following ways:

   **Environment Variable (recommended):**
   ```bash
   export OPENWEATHER_API_KEY=your_api_key
   ```

### Redis Configuration

Configure Redis connection settings:

```bash
export REDIS_URL=redis://localhost:6379/1
```

For production, set appropriate connection parameters and security credentials:

```bash
export REDIS_URL=redis://username:password@redis.example.com:6379/1
```

### Sidekiq Configuration

For Sidekiq monitoring in production:

```bash
export SIDEKIQ_USERNAME=admin
export SIDEKIQ_PASSWORD=secure_password
```

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

4. Background jobs automatically refresh cached data

5. Access the Sidekiq dashboard at [http://localhost:3000/sidekiq](http://localhost:3000/sidekiq) 

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
┌────────────────┐        ┌────────────────┐       ┌────────────────┐│
│     Views      │        │    Helpers     │       │ Background Jobs ││
│  ┌──────────┐  │        │  ┌──────────┐  │       │ ┌──────────┐   ││
│  │  Index   │  │        │  │  Weather │  │       │ │ Weather  │   ││
│  └──────────┘  │        │  │  Helper  │  │       │ │ Fetch Job│   ││
│  ┌──────────┐  │        │  └──────────┘  │       │ └──────────┘   ││
│  │   Show   │  │        └────────────────┘       │ ┌──────────┐   ││
│  └──────────┘  │                                 │ │  Cache   │   ││
│  ┌──────────┐  │        ┌────────────────┐       │ │Cleanup Job│  ││
│  │ Weather  │  │        │    Caching     │       │ └──────────┘   ││
│  │  Partial │  │        │  ┌──────────┐  │       └────────────────┘│
│  └──────────┘  │        │  │  Redis   │  │                         │
└────────────────┘        │  │  Cache   │  │                         │
                          │  └──────────┘  │                         │
                          └────────────────┘                         │
```

### Key Components

1. **ForecastsController**: Handles user requests, manages flow between services and views
2. **AddressParser**: Determines if input is a ZIP code or address, routes accordingly
3. **GeocodingService**: Converts addresses/ZIP codes to coordinates via OpenWeatherMap API
4. **WeatherService**: Fetches weather data and manages caching with custom error handling
5. **WeatherHelper**: Provides view helpers for formatting weather data
6. **WeatherFetchJob**: Background job for asynchronous weather data fetching
7. **CacheCleanupJob**: Maintenance job for Redis cache
8. **Redis**: Persistent caching for improved performance
9. **Sidekiq**: Background job processing

## Testing

The application includes comprehensive tests using RSpec:

- **Controller Tests**: Verify controller actions and response handling
- **Service Tests**: Ensure services correctly interact with APIs
- **Helper Tests**: Validate formatting functions
- **View Tests**: Check proper rendering of data
- **Request Tests**: End-to-end verification of functionality
- **Job Tests**: Confirm background jobs operate correctly

Run the test suite with:

```bash
bundle exec rspec
```

## Deployment

The application includes configuration for production deployment:

- **Procfile**: Defines process types for web and worker processes
- **Sidekiq Configuration**: Settings for production job processing
- **Redis Connection Pooling**: Efficient connection management

For Heroku deployment:

```bash
heroku create
heroku addons:create heroku-postgresql
heroku addons:create heroku-redis
heroku config:set OPENWEATHER_API_KEY=your_api_key
heroku config:set SIDEKIQ_USERNAME=admin
heroku config:set SIDEKIQ_PASSWORD=secure_password
git push heroku main
heroku run rails db:migrate
```

## API Limits

### OpenWeatherMap Free Tier

- 60 API calls per minute
- 1,000 API calls per day for One Call API 3.0

### Implemented Optimizations:

- **Redis Caching**: Results are cached for 30 minutes to reduce API calls
- **Background Jobs**: Async processing of API requests
- **Connection Pooling**: Efficient management of Redis connections
- **Recent Searches**: Allows users to quickly access previous searches without new API calls

## Future Enhancements

- User accounts with favorite locations
- Weather alerts and notifications
- Metrics and monitoring for Redis and Sidekiq
- Geolocation-based automatic weather detection
- Advanced forecast visualization with charts