import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

const Color kPrimaryGreen = Color(0xFF00C853);
const Color kDarkBackground = Color(0xFF121212);
const Color kDarkSurface = Color(0xFF1E1E1E);
const Color kDarkCard = Color(0xFF2C2C2C);

const double kDefaultMapZoom = 14.0;
const double kMinMapZoom = 5.5;
const double kMaxMapZoom = 18.0;
const double kIrelandFallbackZoom = 5.5;

// Initial animation zoom when user is found
const double kInitialUserZoom = 13.0;

// Ireland center fallback when GPS unavailable or user is abroad
const double kIrelandCenterLat = 53.5;
const double kIrelandCenterLng = -7.5;

// Ireland Bounding Box (Wider for breathing room)
const double kIrelandSWLat = 51.0;
const double kIrelandSWLng = -11.0;
const double kIrelandNELat = 55.6;
const double kIrelandNELng = -5.0;

const double kMinFuelPrice = 1.000;
const double kMaxFuelPrice = 3.000;

const int kMaxRetries = 3;
const Duration kRetryBaseDelay = Duration(milliseconds: 500);
const Duration kMapQueryDebounce = Duration(milliseconds: 300);

enum LoadState { loading, loaded, error, offline }

enum FuelType { petrol, diesel, both }

enum DistanceUnit { km, miles }

enum AppThemeMode { dark, light, system }
