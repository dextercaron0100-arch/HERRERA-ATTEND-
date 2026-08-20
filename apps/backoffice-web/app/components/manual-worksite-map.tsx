'use client';

import type { Circle, CircleMarker, Map as LeafletMap } from 'leaflet';
import { useEffect, useRef, useState } from 'react';

type ManualWorksiteMapProps = {
  latitude: string;
  longitude: string;
  radiusMeters: string;
  onLocationChange: (latitude: number, longitude: number) => void;
};

const DEFAULT_CENTER: [number, number] = [14.5995, 120.9842];

export function ManualWorksiteMap({ latitude, longitude, radiusMeters, onLocationChange }: ManualWorksiteMapProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<LeafletMap | null>(null);
  const markerRef = useRef<CircleMarker | null>(null);
  const radiusRef = useRef<Circle | null>(null);
  const onLocationChangeRef = useRef(onLocationChange);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    onLocationChangeRef.current = onLocationChange;
  }, [onLocationChange]);

  useEffect(() => {
    let cancelled = false;
    async function initialize() {
      if (!containerRef.current || mapRef.current) return;
      const leaflet = await import('leaflet');
      if (cancelled || !containerRef.current) return;
      const initialLatitude = parseCoordinate(latitude, -90, 90) ?? DEFAULT_CENTER[0];
      const initialLongitude = parseCoordinate(longitude, -180, 180) ?? DEFAULT_CENTER[1];
      const map = leaflet.map(containerRef.current, { zoomControl: true }).setView([initialLatitude, initialLongitude], 17);
      leaflet.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors',
        maxZoom: 19,
      }).addTo(map);
      map.on('click', event => onLocationChangeRef.current(event.latlng.lat, event.latlng.lng));
      mapRef.current = map;
      setReady(true);
    }
    void initialize();
    return () => {
      cancelled = true;
      mapRef.current?.remove();
      mapRef.current = null;
      markerRef.current = null;
      radiusRef.current = null;
    };
    // The map is initialized once; coordinate changes are handled by the effect below.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!ready || !mapRef.current) return;
    const selectedLatitude = parseCoordinate(latitude, -90, 90);
    const selectedLongitude = parseCoordinate(longitude, -180, 180);
    if (selectedLatitude === null || selectedLongitude === null) return;
    const selectedRadius = Math.max(1, Math.min(5000, Number(radiusMeters) || 100));
    const point: [number, number] = [selectedLatitude, selectedLongitude];
    void import('leaflet').then(leaflet => {
      if (!mapRef.current) return;
      if (!markerRef.current) {
        markerRef.current = leaflet.circleMarker(point, {
          radius: 8,
          color: '#ffffff',
          weight: 3,
          fillColor: '#075bd8',
          fillOpacity: 1,
        }).addTo(mapRef.current);
      } else {
        markerRef.current.setLatLng(point);
      }
      if (!radiusRef.current) {
        radiusRef.current = leaflet.circle(point, {
          radius: selectedRadius,
          color: '#075bd8',
          fillColor: '#2d7ce5',
          fillOpacity: 0.14,
          weight: 2,
        }).addTo(mapRef.current);
      } else {
        radiusRef.current.setLatLng(point).setRadius(selectedRadius);
      }
      mapRef.current.panTo(point, { animate: true, duration: 0.3 });
    });
  }, [latitude, longitude, radiusMeters, ready]);

  return (
    <div className="manualMapShell">
      <div ref={containerRef} className="manualMap" aria-label="Select the worksite center on the map" />
      <div className="manualMapHint">Click anywhere on the map to set the worksite center. The blue circle is the mobile login and clock-in range.</div>
    </div>
  );
}

function parseCoordinate(value: string, minimum: number, maximum: number) {
  if (!value.trim()) return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed >= minimum && parsed <= maximum ? parsed : null;
}
