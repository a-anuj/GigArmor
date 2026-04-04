/**
 * zoneMapping.js
 * Maps user GPS coordinates to the nearest GigArmor Dark Store Zone.
 * Uses Haversine distance (in km) to find the closest centroid.
 */

// Static zone centroids — extend as backend zones grow
const ZONE_CENTROIDS = [
    { id: 1, name: 'Koramangala Dark Store',  lat: 12.9352, lon: 77.6245 },
    { id: 2, name: 'Indiranagar Hub',          lat: 12.9784, lon: 77.6408 },
    { id: 3, name: 'Whitefield Spoke',          lat: 12.9698, lon: 77.7500 },
    { id: 4, name: 'HSR Layout Store',          lat: 12.9116, lon: 77.6389 },
    { id: 5, name: 'Marathahalli Hub',          lat: 12.9591, lon: 77.6972 },
    { id: 6, name: 'Electronic City Store',     lat: 12.8399, lon: 77.6770 },
    { id: 7, name: 'JP Nagar Dark Store',       lat: 12.8993, lon: 77.5900 },
    { id: 8, name: 'Coimbatore RS Puram',       lat: 11.0045, lon: 76.9616 },
];

const DEFAULT_ZONE = 'Indiranagar Hub';

/**
 * Haversine distance between two GPS points (km).
 */
function haversineKm(lat1, lon1, lat2, lon2) {
    const R = 6371;
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Given { lat, lon }, return the name of the nearest dark store zone.
 * Falls back to DEFAULT_ZONE if no coords are provided.
 */
export function getNearestZoneName(coords) {
    if (!coords) return DEFAULT_ZONE;
    const { lat, lon } = coords;
    let nearest = ZONE_CENTROIDS[0];
    let minDist = Infinity;
    for (const zone of ZONE_CENTROIDS) {
        const d = haversineKm(lat, lon, zone.lat, zone.lon);
        if (d < minDist) { minDist = d; nearest = zone; }
    }
    return nearest.name;
}
