// app/assets/javascripts/location_autocomplete.js

document.addEventListener('DOMContentLoaded', function() {
    // Find the address input and autocomplete container
    const addressInput = document.getElementById('address-input');
    const suggestionsContainer = document.getElementById('address-suggestions');
    
    if (!addressInput || !suggestionsContainer) return;
    
    // Store recent and fetched locations
    let fetchedLocations = [];
    let recentSearches = loadRecentSearches();
    
    // Track input changes for autocomplete
    addressInput.addEventListener('input', function() {
      const query = this.value.trim();
      
      if (query.length < 3) {
        hideSuggestions();
        return;
      }
      
      // Find matching locations from recent searches
      const matchingRecent = recentSearches.filter(location => 
        location.toLowerCase().includes(query.toLowerCase())
      );
      
      // Find matching locations from already fetched data
      const matchingFetched = fetchedLocations.filter(location => 
        location.toLowerCase().includes(query.toLowerCase())
      );
      
      // Combine unique results
      const suggestions = [...new Set([
        ...matchingRecent,
        ...matchingFetched
      ])].slice(0, 5); // Limit to 5 suggestions
      
      if (suggestions.length > 0) {
        showSuggestions(suggestions);
      } else {
        fetchSuggestions(query);
      }
    });
    
    // Handle clicks outside the suggestions
    document.addEventListener('click', function(event) {
      if (!addressInput.contains(event.target) && !suggestionsContainer.contains(event.target)) {
        hideSuggestions();
      }
    });
    
    // Fetch location suggestions from OpenWeatherMap API
    function fetchSuggestions(query) {
      const apiKey = document.querySelector('meta[name="weather-api-key"]').content;
      if (!apiKey) return;
      
      const url = `https://api.openweathermap.org/geo/1.0/direct?q=${encodeURIComponent(query)}&limit=5&appid=${apiKey}`;
      
      fetch(url)
        .then(response => response.json())
        .then(data => {
          const suggestions = data.map(place => {
            // Format the place name with city, state, country
            let name = place.name;
            if (place.state) name += `, ${place.state}`;
            if (place.country) name += `, ${place.country}`;
            return name;
          });
          
          // Store fetched locations for future reference
          fetchedLocations = [...new Set([...fetchedLocations, ...suggestions])];
          
          if (suggestions.length > 0) {
            showSuggestions(suggestions);
          } else {
            hideSuggestions();
          }
        })
        .catch(() => {
          hideSuggestions();
        });
    }
    
    // Display suggestions
    function showSuggestions(suggestions) {
      suggestionsContainer.innerHTML = '';
      
      suggestions.forEach(suggestion => {
        const item = document.createElement('div');
        item.classList.add('p-2', 'hover:bg-blue-100', 'cursor-pointer');
        item.textContent = suggestion;
        
        item.addEventListener('click', function() {
          addressInput.value = suggestion;
          addToRecentSearches(suggestion);
          hideSuggestions();
        });
        
        suggestionsContainer.appendChild(item);
      });
      
      suggestionsContainer.classList.remove('hidden');
    }
    
    // Hide suggestions dropdown
    function hideSuggestions() {
      suggestionsContainer.classList.add('hidden');
    }
    
    // Store selected locations in localStorage
    function addToRecentSearches(location) {
      if (!recentSearches.includes(location)) {
        recentSearches.unshift(location);
        
        if (recentSearches.length > 10) {
          recentSearches.pop();
        }
        
        localStorage.setItem('recentSearches', JSON.stringify(recentSearches));
      }
    }
    
    // Load recent searches from localStorage
    function loadRecentSearches() {
      try {
        const saved = localStorage.getItem('recentSearches');
        return saved ? JSON.parse(saved) : [];
      } catch (e) {
        return [];
      }
    }
  });
  