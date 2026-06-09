#!/bin/bash

# Array of SQL statements to create tables
statements=(
  "CREATE TABLE IF NOT EXISTS users (id TEXT PRIMARY KEY, email TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, age INTEGER, role TEXT DEFAULT 'user', created_at DATETIME DEFAULT CURRENT_TIMESTAMP)"
  "CREATE TABLE IF NOT EXISTS age_verification (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, parent_email TEXT, status TEXT DEFAULT 'pending', verified_at DATETIME, FOREIGN KEY (user_id) REFERENCES users (id))"
  "CREATE TABLE IF NOT EXISTS subscriptions (id TEXT PRIMARY KEY, user_id TEXT UNIQUE NOT NULL, plan TEXT DEFAULT 'free', status TEXT DEFAULT 'active', current_period_end DATETIME, FOREIGN KEY (user_id) REFERENCES users (id))"
  "CREATE TABLE IF NOT EXISTS activity_suggestions (id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT, address TEXT, website_url TEXT, distance REAL, time_needed INTEGER, energy_level TEXT, budget REAL, category TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)"
  "CREATE TABLE IF NOT EXISTS usage_tracking (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, week_start DATE NOT NULL, count INTEGER DEFAULT 0, UNIQUE(user_id, week_start), FOREIGN KEY (user_id) REFERENCES users (id))"
  "CREATE TABLE IF NOT EXISTS itineraries (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, title TEXT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (user_id) REFERENCES users (id))"
  "CREATE TABLE IF NOT EXISTS itinerary_items (id TEXT PRIMARY KEY, itinerary_id TEXT NOT NULL, activity_id TEXT NOT NULL, item_order INTEGER, FOREIGN KEY (itinerary_id) REFERENCES itineraries (id), FOREIGN KEY (activity_id) REFERENCES activity_suggestions (id))"
  "CREATE TABLE IF NOT EXISTS date_night_plans (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, primary_activity_id TEXT NOT NULL, companion_activity_id TEXT NOT NULL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (user_id) REFERENCES users (id), FOREIGN KEY (primary_activity_id) REFERENCES activity_suggestions (id), FOREIGN KEY (companion_activity_id) REFERENCES activity_suggestions (id))"
)

# Execute each statement
for stmt in "${statements[@]}"; do
  echo "Executing: $stmt"
  team-db "$stmt"
done
