"""
HustleHalt — AQICN Integration Service
Powers the AQI parametric trigger (T2) — threshold is AQI > 300 for 3+ hours per README

AQICN geo endpoint is free-tier and doesn't require the city name — lat/lon is enough.
"""
import logging
import httpx

from app.config import settings

logger = logging.getLogger(__name__)

AQICN_BASE = "https://api.waqi.info/feed/geo:{lat};{lon}/"

# Fallback mock data — used when USE_REAL_WEATHER_API=false or AQICN is down
_MOCK_AQI: dict[int, dict] = {
    1: {"aqi": 85,  "dominant_pollutant": "pm25"},
    2: {"aqi": 120, "dominant_pollutant": "pm25"},
    3: {"aqi": 60,  "dominant_pollutant": "o3"},
    4: {"aqi": 45,  "dominant_pollutant": "pm10"},
    5: {"aqi": 200, "dominant_pollutant": "pm25"},
    6: {"aqi": 310, "dominant_pollutant": "pm25"},   # Zone 6 — simulates a hazardous day
    7: {"aqi": 170, "dominant_pollutant": "no2"},
    8: {"aqi": 80,  "dominant_pollutant": "pm10"},
}

_DEFAULT_MOCK = {"aqi": 100, "dominant_pollutant": "pm25"}

# AQI categories per US EPA scale (used by AQICN)
AQI_CATEGORIES = [
    (50,  "Good"),
    (100, "Moderate"),
    (150, "Unhealthy for Sensitive Groups"),
    (200, "Unhealthy"),
    (300, "Very Unhealthy"),
    (500, "Hazardous"),
]


def _aqi_category(aqi: int) -> str:
    for threshold, label in AQI_CATEGORIES:
        if aqi <= threshold:
            return label
    return "Hazardous"


def fetch_zone_aqi(lat: float, lon: float, zone_id: int) -> dict:
    """
    Fetches current AQI for a zone using AQICN's geo endpoint.
    Returns AQI value, category, dominant pollutant, and whether T2 threshold is crossed.
    Falls back to mock data on API failure — won't break the server during a demo.
    """
    if not settings.USE_REAL_WEATHER_API or not settings.AQICN_API_TOKEN:
        logger.info(f"Zone {zone_id}: using mock AQI data (real API disabled)")
        data = _MOCK_AQI.get(zone_id, _DEFAULT_MOCK)
        return {
            **data,
            "category": _aqi_category(data["aqi"]),
            "trigger_threshold_crossed": data["aqi"] > 300,
            "source": "mock",
        }

    try:
        url = AQICN_BASE.format(lat=lat, lon=lon)
        resp = httpx.get(
            url,
            params={"token": settings.AQICN_API_TOKEN},
            timeout=5.0,
        )
        resp.raise_for_status()
        body = resp.json()

        if body.get("status") != "ok":
            raise ValueError(f"AQICN returned status={body.get('status')}")

        aqi_data = body["data"]
        # AQI can be '-' (no data) or a number
        raw_aqi = aqi_data.get("aqi", "-")
        aqi = int(raw_aqi) if str(raw_aqi).lstrip("-").isdigit() else 0

        dominants = aqi_data.get("dominentpol", "pm25")

        logger.info(f"Zone {zone_id} AQICN: aqi={aqi}, dominant={dominants}")

        return {
            "aqi": aqi,
            "dominant_pollutant": dominants,
            "category": _aqi_category(aqi),
            "trigger_threshold_crossed": aqi > 300,  # T2 threshold from README
            "source": "aqicn",
        }

    except Exception as exc:
        logger.warning(f"Zone {zone_id} AQICN call failed ({exc}), falling back to mock data")
        data = _MOCK_AQI.get(zone_id, _DEFAULT_MOCK)
        return {
            **data,
            "category": _aqi_category(data["aqi"]),
            "trigger_threshold_crossed": data["aqi"] > 300,
            "source": "mock_fallback",
        }
