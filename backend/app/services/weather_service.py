"""
HustleHalt — OpenWeatherMap Integration Service
Powers the M_weather premium multiplier and Rain/Heat parametric triggers

OWM free tier gives 1000 calls/day — we poll every 15 min per zone = 8 zones × 96 polls = 768/day, fits cleanly.
"""
import logging
import math
import httpx

from app.config import settings

logger = logging.getLogger(__name__)

OWM_BASE = "https://api.openweathermap.org/data/2.5/weather"

# Fallback mock data keyed by zone id — used when USE_REAL_WEATHER_API=false or API is down
_MOCK_WEATHER: dict[int, dict] = {
    1: {"rainfall_mm_hr": 38.0, "temperature_c": 24.0, "humidity_pct": 85.0, "condition": "Heavy Rain"},
    2: {"rainfall_mm_hr": 0.0,  "temperature_c": 27.0, "humidity_pct": 60.0, "condition": "Partly Cloudy"},
    3: {"rainfall_mm_hr": 55.0, "temperature_c": 22.0, "humidity_pct": 92.0, "condition": "Severe Monsoon"},
    4: {"rainfall_mm_hr": 0.0,  "temperature_c": 28.0, "humidity_pct": 45.0, "condition": "Clear"},
    5: {"rainfall_mm_hr": 15.0, "temperature_c": 25.0, "humidity_pct": 70.0, "condition": "Moderate Rain"},
    6: {"rainfall_mm_hr": 42.0, "temperature_c": 23.0, "humidity_pct": 88.0, "condition": "Thunderstorm"},
    7: {"rainfall_mm_hr": 2.0,  "temperature_c": 32.0, "humidity_pct": 55.0, "condition": "Hazy"},
    8: {"rainfall_mm_hr": 0.0,  "temperature_c": 39.0, "humidity_pct": 40.0, "condition": "Extreme Heat"},
}

_DEFAULT_MOCK = {"rainfall_mm_hr": 5.0, "temperature_c": 28.0, "humidity_pct": 65.0, "condition": "Moderate Overcast"}


def _calculate_wet_bulb(temp_c: float, humidity_pct: float) -> float:
    """
    Stull (2011) approximation for wet-bulb temperature — fast, accurate to ±0.3°C
    Used for the Heat trigger (T5): threshold is 38°C wet-bulb per README
    """
    rh = humidity_pct
    wb = (
        temp_c * math.atan(0.151977 * (rh + 8.313659) ** 0.5)
        + math.atan(temp_c + rh)
        - math.atan(rh - 1.676331)
        + 0.00391838 * rh ** 1.5 * math.atan(0.023101 * rh)
        - 4.686035
    )
    return round(wb, 2)


def _rainfall_to_multiplier(rainfall_mm_hr: float) -> tuple[float, str]:
    """
    Maps current rainfall intensity to the M_weather premium multiplier.
    Thresholds are exactly as defined in the README Section 5.
    """
    if rainfall_mm_hr >= 25:
        # Heavy rain / severe monsoon territory
        if rainfall_mm_hr >= 40:
            return 3.5, "Severe Monsoon / Cyclonic Activity"
        return 2.8, "Heavy Rain (25–40 mm/hr, depression forming)"
    elif rainfall_mm_hr >= 10:
        return 2.0, "Moderate Rain (10–25 mm/hr, 3+ days)"
    elif rainfall_mm_hr > 0:
        return 1.4, "Light Rain (<10 mm/hr)"
    else:
        return 1.0, "Clear / No Precipitation"


def fetch_zone_weather(lat: float, lon: float, zone_id: int) -> dict:
    """
    Calls OWM current weather endpoint for a zone's lat/lon.
    Returns structured weather data with wet-bulb temp and M_weather multiplier.
    Falls back gracefully to mock data on any failure.
    """
    if not settings.USE_REAL_WEATHER_API or not settings.OPENWEATHERMAP_API_KEY:
        logger.info(f"Zone {zone_id}: using mock weather data (real API disabled)")
        data = _MOCK_WEATHER.get(zone_id, _DEFAULT_MOCK)
        m_weather, condition = _rainfall_to_multiplier(data["rainfall_mm_hr"])
        return {
            **data,
            "wet_bulb_c": _calculate_wet_bulb(data["temperature_c"], data["humidity_pct"]),
            "m_weather": m_weather,
            "weather_condition": condition,
            "source": "mock",
        }

    try:
        resp = httpx.get(
            OWM_BASE,
            params={
                "lat": lat,
                "lon": lon,
                "appid": settings.OPENWEATHERMAP_API_KEY,
                "units": "metric",  # Celsius
            },
            timeout=5.0,
        )
        resp.raise_for_status()
        data = resp.json()

        # OWM gives rain volume per last 1h in `rain.1h` — convert to mm/hr
        rain = data.get("rain", {})
        rainfall_mm_hr = rain.get("1h", 0.0)

        temp_c = data["main"]["temp"]
        humidity_pct = data["main"]["humidity"]
        wet_bulb_c = _calculate_wet_bulb(temp_c, humidity_pct)
        condition_text = data["weather"][0]["description"].title()

        m_weather, mapped_condition = _rainfall_to_multiplier(rainfall_mm_hr)

        logger.info(
            f"Zone {zone_id} OWM: rain={rainfall_mm_hr}mm/hr, temp={temp_c}°C, "
            f"wb={wet_bulb_c}°C, M_weather={m_weather}"
        )

        return {
            "rainfall_mm_hr": rainfall_mm_hr,
            "temperature_c": round(temp_c, 1),
            "humidity_pct": humidity_pct,
            "wet_bulb_c": wet_bulb_c,
            "condition": condition_text,
            "m_weather": m_weather,
            "weather_condition": mapped_condition,
            "source": "openweathermap",
        }

    except Exception as exc:
        logger.warning(f"Zone {zone_id} OWM call failed ({exc}), falling back to mock data")
        data = _MOCK_WEATHER.get(zone_id, _DEFAULT_MOCK)
        m_weather, condition = _rainfall_to_multiplier(data["rainfall_mm_hr"])
        return {
            **data,
            "wet_bulb_c": _calculate_wet_bulb(data["temperature_c"], data["humidity_pct"]),
            "m_weather": m_weather,
            "weather_condition": condition,
            "source": "mock_fallback",
        }
