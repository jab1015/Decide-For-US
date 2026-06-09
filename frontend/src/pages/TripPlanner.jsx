import { useState } from 'react'
import { useAuth } from '../hooks/useAuth'
import api from '../api/client'

const interestOptions = [
  { value: 'outdoors', label: '🌲 Outdoors' },
  { value: 'food', label: '🍽️ Food & Dining' },
  { value: 'arts', label: '🎨 Arts & Culture' },
  { value: 'shopping', label: '🛍️ Shopping' },
  { value: 'nightlife', label: '🌙 Nightlife' },
  { value: 'music', label: '🎵 Music' },
  { value: 'sports', label: '⚽ Sports' },
  { value: 'family', label: '👨‍👩‍👧‍👦 Family' },
]

export default function TripPlanner() {
  const { user } = useAuth()
  const [destination, setDestination] = useState('')
  const [days, setDays] = useState(1)
  const [interests, setInterests] = useState([])
  const [loading, setLoading] = useState(false)
  const [results, setResults] = useState(null)
  const [error, setError] = useState('')

  const toggleInterest = (value) => {
    setInterests((prev) =>
      prev.includes(value)
        ? prev.filter((i) => i !== value)
        : [...prev, value]
    )
  }

  const handlePlanTrip = async () => {
    if (!destination) return
    setLoading(true)
    setResults(null)
    setError('')
    try {
      const data = await api.getTripItinerary({
        destination,
        days,
        interests: interests.length > 0 ? interests : ['outdoors', 'food', 'arts'],
      })
      setResults(data)
    } catch (err) {
      setError(err.message || 'Failed to plan trip')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="text-center space-y-2">
        <span className="text-4xl">🗺️</span>
        <h1 className="text-2xl font-bold text-gray-900">Trip Planner</h1>
        <p className="text-sm text-gray-500">Build a full itinerary for your adventure</p>
      </div>

      {/* Premium badge */}
      <div className="bg-gradient-to-r from-purple-50 to-violet-50 border border-purple-200 rounded-xl p-3 text-center">
        <span className="text-xs font-medium text-purple-600">✨ Premium Feature &nbsp;|&nbsp; {user?.email}</span>
      </div>

      {/* Trip Config */}
      <div className="bg-white rounded-2xl p-5 shadow-sm border border-nearvibe-100 space-y-4">
        {/* Destination */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">📍 Destination</label>
          <input
            type="text"
            value={destination}
            onChange={(e) => setDestination(e.target.value)}
            placeholder="e.g., Austin, TX"
            className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:border-nearvibe-400 focus:ring-2 focus:ring-nearvibe-100 outline-none transition-all text-sm"
          />
        </div>

        {/* Days */}
        <div>
          <label className="flex items-center justify-between text-sm font-medium text-gray-700 mb-2">
            <span>📅 Number of Days</span>
            <span className="text-nearvibe-600 font-semibold">{days} {days === 1 ? 'day' : 'days'}</span>
          </label>
          <input
            type="range"
            min="1"
            max="7"
            value={days}
            onChange={(e) => setDays(Number(e.target.value))}
            className="w-full h-2 bg-nearvibe-100 rounded-full appearance-none cursor-pointer accent-nearvibe-600"
          />
          <div className="flex justify-between text-xs text-gray-400 mt-1">
            <span>1 day</span>
            <span>7 days</span>
          </div>
        </div>

        {/* Interests */}
        <div>
          <label className="text-sm font-medium text-gray-700 block mb-2">🎯 Interests</label>
          <div className="flex flex-wrap gap-2">
            {interestOptions.map((interest) => (
              <button
                key={interest.value}
                onClick={() => toggleInterest(interest.value)}
                className={`px-3 py-1.5 rounded-full text-sm font-medium border transition-all ${
                  interests.includes(interest.value)
                    ? 'bg-nearvibe-600 text-white border-nearvibe-600 shadow-sm'
                    : 'bg-white text-gray-600 border-gray-200 hover:border-nearvibe-300'
                }`}
              >
                {interest.label}
              </button>
            ))}
          </div>
        </div>

        <button
          onClick={handlePlanTrip}
          disabled={loading || !destination}
          className="w-full bg-gradient-to-r from-nearvibe-600 to-teal-600 text-white font-semibold py-3 rounded-xl hover:from-nearvibe-700 hover:to-teal-700 transition-all disabled:opacity-50 shadow-lg shadow-nearvibe-200"
        >
          {loading ? (
            <span className="flex items-center justify-center gap-2">
              <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
              </svg>
              Building itinerary...
            </span>
          ) : (
            '🗺️ Plan My Trip'
          )}
        </button>

        {error && (
          <p className="text-sm text-red-500 bg-red-50 rounded-lg p-3">{error}</p>
        )}
      </div>

      {/* Itinerary Results */}
      {loading && (
        <div className="space-y-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="bg-white rounded-xl shadow-sm border border-nearvibe-100 overflow-hidden animate-pulse flex">
              <div className="w-16 bg-nearvibe-100 flex items-center justify-center">
                <div className="h-3 w-10 bg-gray-200 rounded" />
              </div>
              <div className="flex-1 p-4 space-y-2">
                <div className="h-4 bg-gray-200 rounded w-3/4" />
                <div className="h-3 bg-gray-200 rounded w-1/2" />
              </div>
            </div>
          ))}
        </div>
      )}

      {results && !loading && (
        <div className="space-y-8">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-semibold text-gray-800">
              🗺️ {destination} Itinerary
            </h2>
            <span className="text-xs text-gray-400">{days} {days === 1 ? 'day' : 'days'}</span>
          </div>

          {results.itinerary ? (
            results.itinerary.map((dayPlan, dayIdx) => (
              <div key={dayIdx}>
                <h3 className="font-bold text-nearvibe-700 text-sm mb-3 flex items-center gap-2">
                  <span className="w-7 h-7 bg-nearvibe-600 text-white rounded-full flex items-center justify-center text-xs font-bold">
                    {dayIdx + 1}
                  </span>
                  Day {dayIdx + 1}
                </h3>

                <div className="relative">
                  <div className="absolute left-7 top-0 bottom-0 w-0.5 bg-nearvibe-200" />

                  <div className="space-y-4">
                    {(dayPlan.activities || dayPlan).map((item, idx) => (
                      <div key={idx} className="relative pl-16">
                        <div className="absolute left-0 top-0 bg-nearvibe-600 text-white text-xs font-bold px-2 py-1 rounded-lg min-w-[3rem] text-center shadow-sm">
                          {item.time || `#${idx + 1}`}
                        </div>

                        <div className="bg-white rounded-xl shadow-sm border border-nearvibe-100 p-4 hover:shadow-md transition-all">
                          <div className="flex items-start justify-between gap-2">
                            <h4 className="font-semibold text-gray-900 text-sm">{item.name || item.title}</h4>
                            {item.energy_level && (
                              <span className={`text-xs font-medium px-2 py-0.5 rounded-full capitalize ${
                                item.energy_level === 'low' ? 'bg-green-100 text-green-700' :
                                item.energy_level === 'medium' ? 'bg-energy-100 text-energy-700' :
                                'bg-red-100 text-red-700'
                              }`}>
                                ⚡ {item.energy_level}
                              </span>
                            )}
                          </div>
                          {item.venue && <p className="text-xs text-gray-500 mt-1">{item.venue}</p>}
                          {item.address && <p className="text-xs text-gray-400 mt-0.5">📍 {item.address}</p>}
                          {item.description && <p className="text-xs text-gray-500 mt-1">{item.description}</p>}
                          <div className="flex gap-3 mt-2 text-xs text-gray-400">
                            {item.estimated_duration && <span>⏱️ {item.estimated_duration}</span>}
                            {item.budget && <span>💵 {item.budget}</span>}
                          </div>
                          {item.website_url && (
                            <a
                              href={item.website_url}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="inline-flex items-center gap-1 text-xs text-nearvibe-600 font-medium mt-2 hover:text-nearvibe-800"
                            >
                              🌐 Visit Website
                            </a>
                          )}
                          {item.companion_activity && (
                            <div className="mt-2 pt-2 border-t border-nearvibe-50">
                              <p className="text-xs text-nearvibe-600">
                                🎯 <span className="text-gray-500">{item.companion_activity}</span>
                              </p>
                            </div>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            ))
          ) : (
            <div className="space-y-4">
              {Array.isArray(results) && results.map((item, idx) => (
                <div key={idx} className="relative pl-16">
                  <div className="absolute left-0 top-0 bg-nearvibe-600 text-white text-xs font-bold px-2 py-1 rounded-lg">
                    {item.time || `#${idx + 1}`}
                  </div>
                  <div className="bg-white rounded-xl shadow-sm border border-nearvibe-100 p-4">
                    <h4 className="font-semibold text-gray-900 text-sm">{item.name || item.title}</h4>
                    {item.venue && <p className="text-xs text-gray-500 mt-1">{item.venue}</p>}
                    {item.address && <p className="text-xs text-gray-400 mt-0.5">📍 {item.address}</p>}
                    {item.website_url && (
                      <a href={item.website_url} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1 text-xs text-nearvibe-600 font-medium mt-2">
                        🌐 Visit Website
                      </a>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  )
}
