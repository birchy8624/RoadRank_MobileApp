/**
 * Utility functions for road drawing: distance calculation and road snapping
 */

const MAX_ROAD_DISTANCE_KM = 5;

/**
 * Calculate the distance between two points using the Haversine formula
 * @param {number} lat1 - Latitude of point 1
 * @param {number} lon1 - Longitude of point 1
 * @param {number} lat2 - Latitude of point 2
 * @param {number} lon2 - Longitude of point 2
 * @returns {number} Distance in kilometers
 */
export function haversineDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in kilometers
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(deg) {
  return deg * (Math.PI / 180);
}

/**
 * Calculate the total distance of a path
 * @param {Array<[number, number]>} path - Array of [lat, lng] points
 * @returns {number} Total distance in kilometers
 */
export function calculatePathDistance(path) {
  if (!path || path.length < 2) return 0;

  let totalDistance = 0;
  for (let i = 0; i < path.length - 1; i++) {
    const [lat1, lng1] = path[i];
    const [lat2, lng2] = path[i + 1];
    totalDistance += haversineDistance(lat1, lng1, lat2, lng2);
  }
  return totalDistance;
}

/**
 * Check if a path exceeds the maximum allowed distance
 * @param {Array<[number, number]>} path - Array of [lat, lng] points
 * @returns {{ valid: boolean, distance: number, maxDistance: number }}
 */
export function validatePathDistance(path) {
  const distance = calculatePathDistance(path);
  return {
    valid: distance <= MAX_ROAD_DISTANCE_KM,
    distance: Math.round(distance * 100) / 100,
    maxDistance: MAX_ROAD_DISTANCE_KM
  };
}

/**
 * Simplify a path by reducing the number of points while maintaining shape
 * This helps reduce API calls and improves snapping performance
 * Uses the Ramer-Douglas-Peucker algorithm concept (simplified version)
 * @param {Array<[number, number]>} path - Array of [lat, lng] points
 * @param {number} maxPoints - Maximum number of points to keep
 * @returns {Array<[number, number]>}
 */
export function simplifyPath(path, maxPoints = 100) {
  if (path.length <= maxPoints) return path;

  // Keep every nth point to reduce to maxPoints
  const step = Math.ceil(path.length / maxPoints);
  const simplified = [];

  for (let i = 0; i < path.length; i += step) {
    simplified.push(path[i]);
  }

  // Always include the last point
  if (simplified[simplified.length - 1] !== path[path.length - 1]) {
    simplified.push(path[path.length - 1]);
  }

  return simplified;
}

/**
 * Snap a drawn path to the nearest roads using OSRM Match API
 * @param {Array<[number, number]>} path - Array of [lat, lng] points
 * @returns {Promise<{ success: boolean, snappedPath?: Array<[number, number]>, error?: string }>}
 */
export async function snapToRoad(path) {
  if (!path || path.length < 2) {
    return { success: false, error: 'Path must have at least 2 points' };
  }

  try {
    // Simplify path to reduce API call size (OSRM has limits)
    const simplifiedPath = simplifyPath(path, 100);

    // OSRM expects coordinates as lng,lat (opposite of Leaflet's lat,lng)
    const coordinates = simplifiedPath
      .map(([lat, lng]) => `${lng},${lat}`)
      .join(';');

    // Use OSRM Match API for map matching (snapping to roads)
    // radiuses parameter sets the search radius for each point (in meters)
    const radiuses = simplifiedPath.map(() => 25).join(';');

    const url = `https://router.project-osrm.org/match/v1/driving/${coordinates}?overview=full&geometries=geojson&radiuses=${radiuses}`;

    const response = await fetch(url);

    if (!response.ok) {
      throw new Error(`OSRM API error: ${response.status}`);
    }

    const data = await response.json();

    if (data.code !== 'Ok' || !data.matchings || data.matchings.length === 0) {
      // If snapping fails, return the original path
      // This can happen if the drawn path is not near any roads
      return {
        success: true,
        snappedPath: path,
        warning: 'Could not snap to road network. Using original path.'
      };
    }

    // Extract the snapped coordinates from the response
    // OSRM returns coordinates as [lng, lat], convert back to [lat, lng]
    const snappedCoordinates = data.matchings[0].geometry.coordinates.map(
      ([lng, lat]) => [lat, lng]
    );

    return {
      success: true,
      snappedPath: snappedCoordinates
    };
  } catch (error) {
    console.error('Road snapping error:', error);
    // Return original path if snapping fails
    return {
      success: true,
      snappedPath: path,
      warning: 'Road snapping service unavailable. Using original path.'
    };
  }
}

export { MAX_ROAD_DISTANCE_KM };
