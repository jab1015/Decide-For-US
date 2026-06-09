import { useState } from 'react'
import { useAuth } from '../hooks/useAuth'
import api from '../api/client'
import ActivityCard from '../components/ActivityCard'

const romanticLevels = [
  { value: 1, label: 'Casual', icon: '☕', desc: 'Low-key coffee dates, walks in the park' },
  { value: 2, label: 'Cozy', icon: '🕯️', desc: 'Quiet dinners, intimate settings' },
  { value: 3, label: 'Romantic', icon: '🌹', desc: 'Candlelit dinners, sunset views' },
  { value: 4, label: 'Passionate', icon: '💫', desc: 'Adventurous dates, unique experiences' },
  { value: 5, label: 'Extravagant', icon: '💎', desc: 'Fine dining, premium VIP experiences' },
]

export default function DateNight() {
  const { user } = useAuth()
  const [romanticLevel, setRomanticLevel] = useState(3)
  const [location, setLocation] = useState('')
  const [budget, setBudget] = useState('moderate')
  const [results, setResults] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handlePlanDate = async () => {
    setLoading(true)
    setResults(null)
    setError('')
    try {
      const data = await api.getDateNight({
        romantic_level: romanticLevel,
        location: location || 'Austin, TX',
        budget,
      })
      setResults(data)
    } catch (err) {
      setError(err.message || 'Failed to plan date night')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="text-center space-y-2">
        <span className="text-4xl">💑</span>
        <h1 className="text-2xl font-bold text-gray-900">Date Night Planner</h1>
        <p className="text-sm text-gray-500">Premium feature — plan the perfect evening</p>
      </div>

      {/* Premium badge */}
      <div className="bg-gradient-to-r from-pink-50 to-rose-50 border border-pink-200 rounded-xl p-3 text-center">
        <span className="text-xs font-medium text-pink-600">✨ Premium Feature &nbsp;|&nbsp; {user?.email}</span>
      </div>

      {/* Planner Card */}
      <div className="bg-white rounded-2xl p-5 shadow-sm border border-nearvibe-100 space-y-4">
        {/* Romantic Level Slider */}
        <div>
          <label className="flex items-center justify-between text-sm font-medium text-gray-700 mb-2">
            <span>🌹 Romantic Vibe</span>
            <span className="text-pink-600 font-semibold">{romanticLevels[romanticLevel - 1]?.label}</span>
          </label>
          <input
            type="range"
            min="1"
            max="5"
            value={romanticLevel}
            onChange={(e) => setRomanticLevel(Number(e.target.value))}
            className="w-full h-2 bg-pink-100 rounded-full appearance-none cursor-pointer accent-pink-500"
          />
          <div className="flex justify-between text-xs text-gray-400 mt-1">
            <span>Casual</span>
            <span>Romantic</span>
            <span>Extravagant</span>
          </div>
          <div className="mt-2 p-3 bg-pink-50 rounded-lg">
            <p className="text-sm text-pink-700 text-center font-medium">
              {romanticLevels[romanticLevel - 1]?.icon} {romanticLevels[romanticLevel - 1]?.desc}
            </p>
          </div>
        </div>

        {/* Location */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">📍 Location</label>
          <input
            type="text"
            value={location}
            onChange={(e) => setLocation(e.target.value)}
            placeholder="e.g., Austin, TX (optional — uses your area)"
            className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:border-pink-400 focus:ring-2 focus:ring-pink-100 outline-none transition-all text-sm"
          />
        </div>

        {/* Budget */}
        <div>
          <label className="text-sm font-medium text-gray-700 block mb-2">💵 Budget</label>
          <div className="grid grid-cols-3 gap-2">
            {['cheap', 'moderate', 'expensive'].map((b) => (
              <button
                key={b}
                onClick={() => setBudget(b)}
                className={`py-2 rounded-lg text-sm font-medium capitalize border transition-all ${
                  budget === b
                    ? 'bg-pink-500 text-white border-pink-500 shadow-sm'
                    : 'bg-white text-gray-600 border-gray-200 hover:border-pink-300'
                }`}
              >
                {b}
              </button>
            ))}
          </div>
        </div>

        <button
          onClick={handlePlanDate}
          disabled={loading}
          className="w-full bg-gradient-to-r from-pink-500 to-rose-500 text-white font-semibold py-3 rounded-xl hover:from-pink-600 hover:to-rose-600 transition-all disabled:opacity-50 shadow-lg shadow-pink-200"
        >
          {loading ? (
            <span className="flex items-center justify-center gap-2">
              <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
              </svg>
              Planning...
            </span>
          ) : (
            '🌹 Plan My Date Night'
          )}
        </button>

        {error && (
          <p className="text-sm text-red-500 bg-red-50 rounded-lg p-3">{error}</p>
        )}
      </div>

      {/* Results */}
      {loading && (
        <div className="space-y-4">
          {[1, 2].map((i) => (
            <div key={i} className="bg-white rounded-xl shadow-sm border border-nearvibe-100 overflow-hidden animate-pulse">
              <div className="h-32 bg-gray-100" />
              <div className="p-4 space-y-3">
                <div className="h-4 bg-gray-200 rounded w-3/4" />
                <div className="h-3 bg-gray-200 rounded w-1/2" />
              </div>
            </div>
          ))}
        </div>
      )}

      {results && !loading && results.length > 0 && (
        <div className="space-y-4">
          <h2 className="text-lg font-semibold text-gray-800">Your Date Night Plans</h2>
          {results.map((a) => (
            <ActivityCard key={a.id} activity={a} />
          ))}
        </div>
      )}
    </div>
  )
}
