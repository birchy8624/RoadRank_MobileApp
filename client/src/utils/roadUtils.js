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
 * Simplify a path using distance-based filtering for better shape preservation
 * Only keeps points that are at least minDistance apart
 * @param {Array<[number, number]>} path - Array of [lat, lng] points
 * @param {number} minDistanceKm - Minimum distance between points in km
 * @returns {Array<[number, number]>}
 */
export function simplifyPathByDistance(path, minDistanceKm = 0.05) {
  if (path.length <= 2) return path;

  const simplified = [path[0]];
  let lastKept = path[0];

  for (let i = 1; i < path.length - 1; i++) {
    const [lat1, lng1] = lastKept;
    const [lat2, lng2] = path[i];
    const dist = haversineDistance(lat1, lng1, lat2, lng2);

    if (dist >= minDistanceKm) {
      simplified.push(path[i]);
      lastKept = path[i];
    }
  }

  // Always include the last point
  simplified.push(path[path.length - 1]);

  return simplified;
}

/**
 * Simplify a path by reducing the number of points while maintaining shape
 * @param {Array<[number, number]>} path - Array of [lat, lng] points
 * @param {number} maxPoints - Maximum number of points to keep
 * @returns {Array<[number, number]>}
 */
export function simplifyPath(path, maxPoints = 25) {
  if (path.length <= maxPoints) return path;

  // First apply distance-based filtering (50m minimum between points)
  let simplified = simplifyPathByDistance(path, 0.05);

  // If still too many points, sample evenly
  if (simplified.length > maxPoints) {
    const step = Math.ceil(simplified.length / maxPoints);
    const sampled = [];
    for (let i = 0; i < simplified.length; i += step) {
      sampled.push(simplified[i]);
    }
    // Always include the last point
    if (sampled[sampled.length - 1] !== simplified[simplified.length - 1]) {
      sampled.push(simplified[simplified.length - 1]);
    }
    simplified = sampled;
  }

  return simplified;
}

/**
 * Decode a polyline encoded string to coordinates
 * @param {string} encoded - Polyline encoded string
 * @param {number} precision - Precision (5 for OSRM, 6 for Google)
 * @returns {Array<[number, number]>} Array of [lat, lng] points
 */
function decodePolyline(encoded, precision = 5) {
  const factor = Math.pow(10, precision);
  const coordinates = [];
  let lat = 0;
  let lng = 0;
  let index = 0;

  while (index < encoded.length) {
    let shift = 0;
    let result = 0;
    let byte;

    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    lat += (result & 1) ? ~(result >> 1) : (result >> 1);

    shift = 0;
    result = 0;

    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    lng += (result & 1) ? ~(result >> 1) : (result >> 1);

    coordinates.push([lat / factor, lng / factor]);
  }

  return coordinates;
}

/**
 * Snap a drawn path to the nearest roads using OSRM Match API
 * Optimized for speed with reduced points and polyline encoding
 * @param {Array<[number, number]>} path - Array of [lat, lng] points
 * @returns {Promise<{ success: boolean, snappedPath?: Array<[number, number]>, error?: string }>}
 */
export async function snapToRoad(path) {
  if (!path || path.length < 2) {
    return { success: false, error: 'Path must have at least 2 points' };
  }

  try {
    // Aggressively simplify path for faster API response (max 25 points)
    const simplifiedPath = simplifyPath(path, 25);

    // OSRM expects coordinates as lng,lat (opposite of Leaflet's lat,lng)
    const coordinates = simplifiedPath
      .map(([lat, lng]) => `${lng},${lat}`)
      .join(';');

    // Use larger radius (50m) for faster matching with fewer retries
    const radiuses = simplifiedPath.map(() => 50).join(';');

    // Use polyline encoding (faster) and simplified overview
    const url = `https://router.project-osrm.org/match/v1/driving/${coordinates}?overview=simplified&geometries=polyline&radiuses=${radiuses}&gaps=ignore`;

    // Add timeout for faster failure
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);

    const response = await fetch(url, { signal: controller.signal });
    clearTimeout(timeoutId);

    if (!response.ok) {
      throw new Error(`OSRM API error: ${response.status}`);
    }

    const data = await response.json();

    if (data.code !== 'Ok' || !data.matchings || data.matchings.length === 0) {
      return {
        success: true,
        snappedPath: path,
        warning: 'Could not snap to road network. Using original path.'
      };
    }

    // Decode polyline to coordinates
    const snappedCoordinates = decodePolyline(data.matchings[0].geometry);

    return {
      success: true,
      snappedPath: snappedCoordinates
    };
  } catch (error) {
    if (error.name === 'AbortError') {
      console.warn('Road snapping timed out');
      return {
        success: true,
        snappedPath: path,
        warning: 'Road snapping timed out. Using original path.'
      };
    }
    console.error('Road snapping error:', error);
    return {
      success: true,
      snappedPath: path,
      warning: 'Road snapping service unavailable. Using original path.'
    };
  }
}

export { MAX_ROAD_DISTANCE_KM };
