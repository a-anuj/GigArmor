/**
 * useGeolocation.js
 * Returns { lat, lon, loading, error }
 * Gracefully falls back to Bangalore city center on denial or error.
 */
import { useState, useEffect } from 'react';

const DEFAULT_COORDS = { lat: 12.9716, lon: 77.5946 }; // Bangalore city center

export function useGeolocation() {
    const [coords, setCoords] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        if (!navigator.geolocation) {
            setCoords(DEFAULT_COORDS);
            setError('Geolocation not supported — using default zone.');
            setLoading(false);
            return;
        }

        navigator.geolocation.getCurrentPosition(
            (pos) => {
                setCoords({ lat: pos.coords.latitude, lon: pos.coords.longitude });
                setLoading(false);
            },
            (err) => {
                console.warn('[useGeolocation] Permission denied or error:', err.message);
                setCoords(DEFAULT_COORDS);
                setError('Location access denied — using default Bangalore zone.');
                setLoading(false);
            },
            { timeout: 8000, maximumAge: 60000 }
        );
    }, []);

    return { coords, loading, error };
}
