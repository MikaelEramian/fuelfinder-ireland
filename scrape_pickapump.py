import requests
import json
import time

# Grid points covering Republic of Ireland
# lat/lng pairs with radius 50km each to cover the whole country
GRID_POINTS = [
    # Donegal / Northwest
    (55.0, -8.2), (55.0, -7.7), (55.0, -7.2),
    (54.8, -8.5), (54.8, -8.0), (54.8, -7.5), (54.8, -7.0),
    # Sligo / Leitrim / Mayo north
    (54.3, -8.8), (54.3, -8.3), (54.3, -7.8), (54.3, -7.3),
    (54.0, -9.5), (54.0, -9.0), (54.0, -8.5), (54.0, -8.0), (54.0, -7.5), (54.0, -7.0),
    # Galway / Roscommon / Westmeath
    (53.5, -9.5), (53.5, -9.0), (53.5, -8.5), (53.5, -8.0), (53.5, -7.5), (53.5, -7.0), (53.5, -6.5),
    (53.3, -9.5), (53.3, -9.0), (53.3, -8.5), (53.3, -8.0), (53.3, -7.5), (53.3, -7.0), (53.3, -6.5), (53.3, -6.0),
    # Dublin / Meath / Kildare / Wicklow
    (53.0, -7.5), (53.0, -7.0), (53.0, -6.5), (53.0, -6.0),
    # Limerick / Tipperary / Kilkenny
    (52.7, -9.0), (52.7, -8.5), (52.7, -8.0), (52.7, -7.5), (52.7, -7.0), (52.7, -6.5),
    (52.5, -9.5), (52.5, -9.0), (52.5, -8.5), (52.5, -8.0), (52.5, -7.5), (52.5, -7.0), (52.5, -6.5),
    # Cork / Kerry / Waterford
    (52.0, -10.0), (52.0, -9.5), (52.0, -9.0), (52.0, -8.5), (52.0, -8.0), (52.0, -7.5), (52.0, -7.0), (52.0, -6.5),
    (51.7, -10.0), (51.7, -9.5), (51.7, -9.0), (51.7, -8.5), (51.7, -8.0), (51.7, -7.5), (51.7, -7.0), (51.7, -6.5),
    (51.5, -9.5), (51.5, -9.0), (51.5, -8.5),
    # Wexford / South Wicklow
    (52.3, -7.0), (52.3, -6.5), (52.3, -6.0),
]

API_URL = "https://api.pickapump.com/v1/stations/nearby"
ALL_STATIONS = {}

print(f"Scraping PickAPump with {len(GRID_POINTS)} grid points...")
print("This will take a few minutes.\n")

for i, (lat, lng) in enumerate(GRID_POINTS):
    try:
        resp = requests.get(API_URL, params={"lat": lat, "lng": lng, "radius": 50}, timeout=15)
        if resp.status_code == 200:
            stations = resp.json()
            new_count = 0
            for s in stations:
                sid = s.get("id")
                if sid and sid not in ALL_STATIONS:
                    ALL_STATIONS[sid] = s
                    new_count += 1
            print(f"[{i+1}/{len(GRID_POINTS)}] lat={lat}, lng={lng} -> {len(stations)} stations ({new_count} new) | Total: {len(ALL_STATIONS)}")
        else:
            print(f"[{i+1}/{len(GRID_POINTS)}] lat={lat}, lng={lng} -> HTTP {resp.status_code}")
    except Exception as e:
        print(f"[{i+1}/{len(GRID_POINTS)}] lat={lat}, lng={lng} -> Error: {e}")
    
    time.sleep(0.5)  # be nice to their server

# Filter ROI only
roi_stations = {k: v for k, v in ALL_STATIONS.items() if v.get("country") == "ROI"}
print(f"\nTotal stations scraped: {len(ALL_STATIONS)}")
print(f"ROI stations: {len(roi_stations)}")

# Save raw JSON for reference
with open("pickapump_all.json", "w") as f:
    json.dump(list(ALL_STATIONS.values()), f, indent=2)

with open("pickapump_roi.json", "w") as f:
    json.dump(list(roi_stations.values()), f, indent=2)

print("Saved pickapump_all.json and pickapump_roi.json")

# Generate SQL
def escape_sql(s):
    if s is None:
        return "NULL"
    return "'" + str(s).replace("'", "''").strip() + "'"

sql_lines = []
sql_lines.append("-- =============================================")
sql_lines.append("-- PickAPump Data Import for FuelFinder Ireland")
sql_lines.append(f"-- {len(roi_stations)} ROI stations")
sql_lines.append("-- =============================================\n")

# Clear existing seed data
sql_lines.append("-- Clear existing seed data")
sql_lines.append("DELETE FROM prices;")
sql_lines.append("DELETE FROM stations;\n")

# Insert stations
sql_lines.append("-- Insert stations")
for s in roi_stations.values():
    name = escape_sql(s.get("stationName"))
    brand = escape_sql(s.get("brand")) if s.get("brand") else "NULL"
    address_parts = []
    if s.get("address"):
        address_parts.append(s["address"])
    if s.get("town"):
        address_parts.append(s["town"])
    address = escape_sql(", ".join(address_parts)) if address_parts else "NULL"
    county = escape_sql(s.get("county")) if s.get("county") else "NULL"
    lat = s.get("coords", {}).get("lat", 0)
    lng = s.get("coords", {}).get("lng", 0)
    
    sql_lines.append(
        f"INSERT INTO stations (id, name, brand, address, county, latitude, longitude) VALUES ("
        f"'{s['id']}', {name}, {brand}, {address}, {county}, {lat}, {lng});"
    )

sql_lines.append("")
sql_lines.append("-- Insert prices")

price_count = 0
for s in roi_stations.values():
    prices = s.get("prices")
    if not prices:
        continue
    if prices.get("currency") != "euro":
        continue
    
    station_id = s["id"]
    reported_at = prices.get("date_added", prices.get("date_updated"))
    
    # Petrol price (convert from cents to euros: 189.9 -> 1.899)
    if prices.get("petrol"):
        petrol_eur = round(prices["petrol"] / 100, 3)
        sql_lines.append(
            f"INSERT INTO prices (station_id, fuel_type, price, reported_at) VALUES ("
            f"'{station_id}', 'petrol', {petrol_eur}, '{reported_at}');"
        )
        price_count += 1
    
    # Diesel price
    if prices.get("diesel"):
        diesel_eur = round(prices["diesel"] / 100, 3)
        sql_lines.append(
            f"INSERT INTO prices (station_id, fuel_type, price, reported_at) VALUES ("
            f"'{station_id}', 'diesel', {diesel_eur}, '{reported_at}');"
        )
        price_count += 1

sql_lines.append(f"\n-- Import complete: {len(roi_stations)} stations, {price_count} prices")

sql_content = "\n".join(sql_lines)
with open("import_data.sql", "w", encoding="utf-8") as f:
    f.write(sql_content)

print(f"\nGenerated import_data.sql with {len(roi_stations)} stations and {price_count} price entries")
print("\nNext steps:")
print("1. Open your Supabase dashboard -> SQL Editor")
print("2. Paste the contents of import_data.sql")
print("3. Run it")
print("4. Restart your app and the real data should appear on the map!")
