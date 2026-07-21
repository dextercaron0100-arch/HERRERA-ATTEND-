const EARTH_RADIUS_M = 6_371_000;
const radians = (degrees:number) => degrees * Math.PI / 180;
export function distanceMeters(lat1:number, lon1:number, lat2:number, lon2:number):number {
  const dLat=radians(lat2-lat1), dLon=radians(lon2-lon1);
  const a=Math.sin(dLat/2)**2 + Math.cos(radians(lat1))*Math.cos(radians(lat2))*Math.sin(dLon/2)**2;
  return EARTH_RADIUS_M * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
}
export function decideAttendance(distance:number, radius:number, accuracy:number, maxAccuracy:number){
  const reasons:string[]=[];
  if (accuracy > maxAccuracy) reasons.push('LOW_GPS_ACCURACY');
  if (distance > radius) reasons.push('OUTSIDE_GEOFENCE');
  if (accuracy > maxAccuracy) return { decision:'REVIEW' as const, reasonCodes:reasons };
  if (distance > radius) return { decision:'REJECTED' as const, reasonCodes:reasons };
  return { decision:'ACCEPTED' as const, reasonCodes:['WITHIN_GEOFENCE'] };
}
