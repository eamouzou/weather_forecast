# Weather Forecast Application - Development Plan

## Service Classes
- WeatherService: Handles API interactions with OpenWeatherMap
- AddressParser: Processes user addresses into geocodable format

## Controllers
- ForecastsController: Manages user requests and responses

## Models/POJOs
- Forecast: Represents weather data

## Data Flow
1. User enters address
2. AddressParser converts to coordinates
3. WeatherService fetches forecast data
4. Controller serves data to view
5. Cache layer stores results for future requests

## Planned Features
- Current temperature
- High/low temperatures
- Extended forecast
- Cache indicator