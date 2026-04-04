/**
 * zoneMapping.js
 * Maps user GPS coordinates to the nearest GigArmor Dark Store Zone.
 * Uses Haversine distance (in km) to find the closest centroid.
 */

// Static zone centroids — extend as backend zones grow
const ZONE_CENTROIDS = [
    { id: 1,  name: 'Zone 1 — Koramangala',  lat: 12.9352, lon: 77.6245 },
    { id: 2,  name: 'Zone 2 — Indiranagar',   lat: 12.9784, lon: 77.6408 },
    { id: 3,  name: 'Zone 3 — HSR Layout',    lat: 12.9116, lon: 77.6389 },
    { id: 4,  name: 'Zone 4 — Whitefield',    lat: 12.9698, lon: 77.7500 },
    { id: 5,  name: 'Zone 5 — Marathahalli',  lat: 12.9591, lon: 77.6972 },
    { id: 6,  name: 'Zone 6 — Electronic City', lat: 12.8399, lon: 77.6770 },
    { id: 7,  name: 'Zone 7 — JP Nagar',      lat: 12.8993, lon: 77.5900 },
    { id: 8,  name: 'Zone 8 — Jayanagar',     lat: 12.9299, lon: 77.5820 },
    { id: 9,  name: 'Zone 9 — BTM Layout',    lat: 12.9165, lon: 77.6101 },
    { id: 10, name: 'Zone 10 — Bommanahalli', lat: 12.8985, lon: 77.6408 },
    { id: 11, name: 'Zone 11 — Bellandur',    lat: 12.9357, lon: 77.6855 },
    { id: 12, name: 'Zone 12 — Banashankari', lat: 12.9250, lon: 77.5460 },
    { id: 13, name: 'Zone 13 — T. Dasarahalli', lat: 13.0550, lon: 77.5142 },
    { id: 14, name: 'Zone 14 — Velachery',    lat: 12.9776, lon: 80.2209 },
];

const DEFAULT_ZONE = 'Zone 14 — Velachery';

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
