-- FuelFinder Ireland Database Schema

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Stations Table
CREATE TABLE stations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  brand TEXT,
  address TEXT NOT NULL,
  county TEXT,
  phone TEXT,
  brand_logo_url TEXT,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_stations_bounds ON stations(is_active, latitude, longitude);

-- Prices Table
CREATE TABLE prices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  station_id UUID NOT NULL REFERENCES stations(id) ON DELETE CASCADE,
  fuel_type TEXT NOT NULL CHECK (fuel_type IN ('petrol', 'diesel')),
  price NUMERIC(5,3) NOT NULL,
  confidence INTEGER DEFAULT 1,
  reported_by UUID,
  reported_at TIMESTAMPTZ DEFAULT NOW(),
  reported_location_lat DOUBLE PRECISION,
  reported_location_lng DOUBLE PRECISION
);

CREATE INDEX idx_prices_station_fuel ON prices(station_id, fuel_type, reported_at DESC);

-- Profiles Table
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  display_name TEXT,
  is_premium BOOLEAN DEFAULT FALSE,
  premium_until TIMESTAMPTZ,
  total_saved NUMERIC(8,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "stations_select" ON stations FOR SELECT USING (true);
CREATE POLICY "prices_select" ON prices FOR SELECT USING (true);
CREATE POLICY "prices_insert" ON prices FOR INSERT WITH CHECK (true);
CREATE POLICY "profiles_select" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_update" ON profiles FOR UPDATE USING (auth.uid() = id);

-- get_stations_in_bounds function
CREATE OR REPLACE FUNCTION get_stations_in_bounds(
  min_lat DOUBLE PRECISION,
  max_lat DOUBLE PRECISION,
  min_lng DOUBLE PRECISION,
  max_lng DOUBLE PRECISION
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  brand TEXT,
  address TEXT,
  county TEXT,
  phone TEXT,
  brand_logo_url TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  petrol_price NUMERIC,
  petrol_updated_at TIMESTAMPTZ,
  diesel_price NUMERIC,
  diesel_updated_at TIMESTAMPTZ
) AS $$
  SELECT
    s.id, s.name, s.brand, s.address, s.county, s.phone, s.brand_logo_url,
    s.latitude, s.longitude,
    pp.price AS petrol_price, pp.reported_at AS petrol_updated_at,
    dp.price AS diesel_price, dp.reported_at AS diesel_updated_at
  FROM stations s
  LEFT JOIN LATERAL (
    SELECT price, reported_at FROM prices
    WHERE station_id = s.id AND fuel_type = 'petrol'
    ORDER BY reported_at DESC LIMIT 1
  ) pp ON true
  LEFT JOIN LATERAL (
    SELECT price, reported_at FROM prices
    WHERE station_id = s.id AND fuel_type = 'diesel'
    ORDER BY reported_at DESC LIMIT 1
  ) dp ON true
  WHERE s.is_active = true
    AND s.latitude BETWEEN min_lat AND max_lat
    AND s.longitude BETWEEN min_lng AND max_lng;
$$ LANGUAGE sql STABLE;

-- Seed Data
INSERT INTO stations (name, brand, address, county, latitude, longitude) VALUES
  -- Dublin (12)
  ('Circle K Drumcondra', 'Circle K', 'Drumcondra Road Upper, Dublin 9', 'Dublin', 53.3711, -6.2573),
  ('Applegreen M50 Palmerstown', 'Applegreen', 'M50, Palmerstown, Dublin 20', 'Dublin', 53.3435, -6.3741),
  ('Maxol Fairview', 'Maxol', 'Fairview Strand, Dublin 3', 'Dublin', 53.3643, -6.2355),
  ('Circle K Rathmines', 'Circle K', 'Rathmines Road Lower, Dublin 6', 'Dublin', 53.3250, -6.2632),
  ('Applegreen Stillorgan', 'Applegreen', 'N11, Stillorgan, Co. Dublin', 'Dublin', 53.2897, -6.2058),
  ('Maxol Glasnevin', 'Maxol', 'Ballymun Road, Glasnevin, Dublin 9', 'Dublin', 53.3812, -6.2670),
  ('Circle K Blanchardstown', 'Circle K', 'Blanchardstown Road North, Dublin 15', 'Dublin', 53.3917, -6.3885),
  ('Texaco Donnybrook', 'Texaco', 'Donnybrook Road, Dublin 4', 'Dublin', 53.3199, -6.2374),
  ('Applegreen Finglas', 'Applegreen', 'Jamestown Road, Finglas, Dublin 11', 'Dublin', 53.3907, -6.2973),
  ('Maxol Raheny', 'Maxol', 'Howth Road, Raheny, Dublin 5', 'Dublin', 53.3807, -6.1771),
  ('Circle K Swords', 'Circle K', 'Main Street, Swords, Co. Dublin', 'Dublin', 53.4597, -6.2181),
  ('Applegreen Lucan', 'Applegreen', 'N4, Lucan, Co. Dublin', 'Dublin', 53.3540, -6.4490),
  -- Cork (6)
  ('Circle K Mahon', 'Circle K', 'Mahon Point, Cork', 'Cork', 51.8887, -8.3943),
  ('Maxol Douglas', 'Maxol', 'Douglas Road, Cork', 'Cork', 51.8762, -8.4360),
  ('Applegreen Ballincollig', 'Applegreen', 'Main Street, Ballincollig, Cork', 'Cork', 51.8873, -8.5893),
  ('Circle K Blackpool', 'Circle K', 'Dublin Street, Blackpool, Cork', 'Cork', 51.9074, -8.4726),
  ('Texaco Wilton', 'Texaco', 'Wilton Road, Cork', 'Cork', 51.8828, -8.5007),
  ('Maxol Glanmire', 'Maxol', 'Dublin Hill, Glanmire, Cork', 'Cork', 51.9081, -8.4018),
  -- Galway (5)
  ('Circle K Galway East', 'Circle K', 'Dublin Road, Galway', 'Galway', 53.2753, -8.9956),
  ('Applegreen Oranmore', 'Applegreen', 'N6, Oranmore, Galway', 'Galway', 53.2687, -8.9240),
  ('Maxol Salthill', 'Maxol', 'Salthill Road, Galway', 'Galway', 53.2607, -9.0724),
  ('Circle K Knocknacarra', 'Circle K', 'Knocknacarra Road, Galway', 'Galway', 53.2714, -9.0918),
  ('Texaco Tuam Road', 'Texaco', 'Tuam Road, Galway', 'Galway', 53.2880, -8.9977),
  -- Limerick (4)
  ('Circle K Ennis Road', 'Circle K', 'Ennis Road, Limerick', 'Limerick', 52.6723, -8.6406),
  ('Applegreen Castletroy', 'Applegreen', 'Dublin Road, Castletroy, Limerick', 'Limerick', 52.6741, -8.5405),
  ('Maxol Dooradoyle', 'Maxol', 'Dooradoyle Road, Limerick', 'Limerick', 52.6434, -8.6531),
  ('Texaco Raheen', 'Texaco', 'Raheen Business Park, Limerick', 'Limerick', 52.6478, -8.6768),
  -- Waterford (3)
  ('Circle K Waterford', 'Circle K', 'Cork Road, Waterford', 'Waterford', 52.2465, -7.1270),
  ('Applegreen Tramore Road', 'Applegreen', 'Tramore Road, Waterford', 'Waterford', 52.2415, -7.1052),
  ('Maxol Waterford', 'Maxol', 'Dunmore Road, Waterford', 'Waterford', 52.2523, -7.0775);

-- Seed prices for all 30 stations
DO $$
DECLARE
  s RECORD;
  base_petrol NUMERIC := 1.699;
  base_diesel NUMERIC := 1.649;
  i INT := 0;
BEGIN
  FOR s IN SELECT id FROM stations ORDER BY created_at LOOP
    INSERT INTO prices (station_id, fuel_type, price)
    VALUES (s.id, 'petrol', base_petrol + (i % 7) * 0.010);
    INSERT INTO prices (station_id, fuel_type, price)
    VALUES (s.id, 'diesel', base_diesel + (i % 7) * 0.010);
    i := i + 1;
  END LOOP;
END $$;
