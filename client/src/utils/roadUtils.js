/**
 * Utility functions for road drawing: distance calculation and road snapping
 */

const MAX_ROAD_DISTANCE_KM = 20;

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
 * Calculate perpendicular distance from a point to a line segment
 * Used by Ramer-Douglas-Peucker algorithm
 * @param {[number, number]} point - The point [lat, lng]
 * @param {[number, number]} lineStart - Start of line segment [lat, lng]
 * @param {[number, number]} lineEnd - End of line segment [lat, lng]
 * @returns {number} Distance in kilometers
 */
function perpendicularDistance(point, lineStart, lineEnd) {
  const [lat, lng] = point;
  const [lat1, lng1] = lineStart;
  const [lat2, lng2] = lineEnd;

  // If line start and end are the same point, return distance to that point
  if (lat1 === lat2 && lng1 === lng2) {
    return haversineDistance(lat, lng, lat1, lng1);
  }

  // Calculate the perpendicular distance using cross product method
  // Convert to approximate Cartesian for small areas (good enough for simplification)
  const dx = lng2 - lng1;
  const dy = lat2 - lat1;
  const lineLengthSquared = dx * dx + dy * dy;

  // Project point onto line
  const t = Math.max(0, Math.min(1, ((lng - lng1) * dx + (lat - lat1) * dy) / lineLengthSquared));
  const projLng = lng1 + t * dx;
  const projLat = lat1 + t * dy;

  return haversineDistance(lat, lng, projLat, projLng);
}

/**
 * Ramer-Douglas-Peucker algorithm for path simplification
 * Preserves shape much better than even sampling, especially for curves and turns
 * @param {Array<[number, number]>} path - Array of [lat, lng] points
 * @param {number} epsilon - Tolerance in kilometers (points within this distance are removed)
 * @returns {Array<[number, number]>}
 */
function rdpSimplify(path, epsilon) {
  if (path.length <= 2) return path;

  // Find the point with maximum distance from the line between first and last
  let maxDistance = 0;
  let maxIndex = 0;

  for (let i = 1; i < path.length - 1; i++) {
    const distance = perpendicularDistance(path[i], path[0], path[path.length - 1]);
    if (distance > maxDistance) {
      maxDistance = distance;
      maxIndex = i;
    }
  }

  // If max distance exceeds epsilon, recursively simplify
  if (maxDistance > epsilon) {
    const left = rdpSimplify(path.slice(0, maxIndex + 1), epsilon);
    const right = rdpSimplify(path.slice(maxIndex), epsilon);

    // Combine results (remove duplicate point at junction)
    return left.slice(0, -1).concat(right);
  }

  // All points are within epsilon, return just endpoints
  return [path[0], path[path.length - 1]];
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
 * Adaptively simplify a path based on its total length
 * Uses Ramer-Douglas-Peucker for shape preservation
 * @param {Array<[number, number]>} path - Array of [lat, lng] points
 * @param {number} maxPoints - Maximum number of points to keep
 * @returns {Array<[number, number]>}
 */
export function simplifyPath(path, maxPoints = 100) {
  if (path.length <= 2) return path;

  // Calculate total path distance to determine simplification strategy
  const pathDistance = calculatePathDistance(path);

  // Adaptive parameters based on path length
  let epsilon;      // RDP tolerance in km
  let minDistance;  // Minimum distance between points in km

  if (pathDistance <= 2) {
    // Short paths (< 2km): high precision
    epsilon = 0.005;     // 5m tolerance
    minDistance = 0.02;  // 20m minimum between points
  } else if (pathDistance <= 5) {
    // Medium paths (2-5km): moderate precision
    epsilon = 0.01;      // 10m tolerance
    minDistance = 0.03;  // 30m minimum between points
  } else if (pathDistance <= 10) {
    // Long paths (5-10km): balanced precision
    epsilon = 0.02;      // 20m tolerance
    minDistance = 0.05;  // 50m minimum between points
  } else {
    // Very long paths (10-20km): optimize for API limits
    epsilon = 0.03;      // 30m tolerance
    minDistance = 0.08;  // 80m minimum between points
  }

  // Step 1: Apply distance-based filtering first (fast, removes clustered points)
  let simplified = simplifyPathByDistance(path, minDistance);

  // Step 2: Apply RDP algorithm for shape-preserving simplification
  if (simplified.length > maxPoints) {
    // Iteratively increase epsilon until we're under maxPoints
    let currentEpsilon = epsilon;
    while (simplified.length > maxPoints && currentEpsilon < 0.5) {
      simplified = rdpSimplify(simplified, currentEpsilon);
      currentEpsilon *= 1.5;  // Increase tolerance by 50% each iteration
    }
  }

  // Step 3: If still too many points, fall back to even sampling
  if (simplified.length > maxPoints) {
    const step = Math.ceil(simplified.length / maxPoints);
    const sampled = [simplified[0]];
    for (let i = step; i < simplified.length - 1; i += step) {
      sampled.push(simplified[i]);
    }
    sampled.push(simplified[simplified.length - 1]);
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
 * Optimized for roads up to 20km with adaptive simplification
 * @param {Array<[number, number]>} path - Array of [lat, lng] points
 * @returns {Promise<{ success: boolean, snappedPath?: Array<[number, number]>, error?: string }>}
 */
export async function snapToRoad(path) {
  if (!path || path.length < 2) {
    return { success: false, error: 'Path must have at least 2 points' };
  }

  try {
    // Calculate path distance to determine optimal settings
    const pathDistance = calculatePathDistance(path);

    // Adaptive max points based on path length (more points for longer paths)
    const maxPoints = pathDistance > 10 ? 100 : pathDistance > 5 ? 80 : 50;

    // Use smart simplification with RDP algorithm for shape preservation
    const simplifiedPath = simplifyPath(path, maxPoints);

    // OSRM expects coordinates as lng,lat (opposite of Leaflet's lat,lng)
    const coordinates = simplifiedPath
      .map(([lat, lng]) => `${lng},${lat}`)
      .join(';');

    // Adaptive radius: larger for longer paths to handle GPS inaccuracies
    const radius = pathDistance > 10 ? 75 : 50;
    const radiuses = simplifiedPath.map(() => radius).join(';');

    // Use full overview for longer paths to get accurate snapped geometry
    const overview = pathDistance > 5 ? 'full' : 'simplified';
    const url = `https://router.project-osrm.org/match/v1/driving/${coordinates}?overview=${overview}&geometries=polyline&radiuses=${radiuses}&gaps=ignore`;

    // Add timeout (30 seconds for longer roads up to 20km)
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 30000);

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
