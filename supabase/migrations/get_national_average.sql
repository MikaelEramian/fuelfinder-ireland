
CREATE OR REPLACE FUNCTION get_national_average()
RETURNS json
LANGUAGE plpgsql
AS $$
DECLARE
  petrol_avg float;
  diesel_avg float;
BEGIN
  SELECT avg(price) INTO petrol_avg
  FROM prices
  WHERE fuel_type = 'petrol' AND reported_at >= NOW() - INTERVAL '60 days';

  SELECT avg(price) INTO diesel_avg
  FROM prices
  WHERE fuel_type = 'diesel' AND reported_at >= NOW() - INTERVAL '60 days';

  RETURN json_build_object(
    'petrol', COALESCE(petrol_avg, 0.0),
    'diesel', COALESCE(diesel_avg, 0.0)
  );
END;
$$;
