import { useState, useEffect } from 'react'
import { useAuth } from '../hooks/useAuth'
import api from '../api/client'
import UsageTracker from '../components/UsageTracker'
import ActivityCard from '../components/ActivityCard'
import FilterSkeleton from '../components/FilterSkeleton'

const energyLevels = ['low', 'medium', 'high']
const budgetOptions = [
  { value: 'free', label: 'Free', icon: '🆓' },
  { value: 'cheap', label: 'Cheap', icon: '💰' },
  { value: 'moderate', label: 'Moderate', icon: '💵' },
  { value: 'expensive', label: 'Splurge', icon: '💎' },
]

export default function Discover() {
  const { user } = useAuth()
  const [distance, setDistance] = useState(10)
  const [timeAvailable, setTimeAvailable] = useState(2)
  const [energyLevel, setEnergyLevel] = useState('medium')
  const [budget, setBudget] = useState('free')
  const [loading, setLoading] = useState(false)
  const [results, setResults] = useState(null)
  const [usage, setUsage] = useState({ count: 0, limit: 3, is_premium: false })

  useEffect(() => {
    if (user) {
      api.getUsage()
        .then(setUsage)
        .catch(() => {})
    }
  }, [user])

  const handleSearch = async () => {
    setLoading(true)
    setResults(null)

    try {
      const suggestions = await api.getSuggestions({
        lat: 30.2672,
        lng: -97.7431,
        distance,
        time: timeAvailable,
        energy_level: energyLevel,
        budget,
      })
      setResults({ suggestions })
      // Refresh usage after search
      if (user) {
        api.getUsage().then(setUsage).catch(() => {})
      }
    } catch (err) {
      if (err.status === 402) {
        // Usage limit reached
        alert('You\'ve used all your free suggestions this week! Upgrade to Premium for unlimited access.')
      } else {
        console.error('Search failed:', err)
      }
    } finally {
      setLoading(false)
    }
  }

  const isPremium = user?.is_premium || usage?.is_premium
  const used = isPremium ? 0 : usage?.count || 0
  const max = isPremium ? 999 : usage?.limit || 3

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Discover</h1>
          <p className="text-sm text-gray-500">Find your vibe today</p>
        </div>
        {!isPremium && <UsageTracker used={used} max={max} />}
        {isPremium && (
          <span className="text-xs bg-nearvibe-100 text-nearvibe-700 font-medium px-3 py-1 rounded-full">
            ⭐ Premium
          </span>
        )}
      </div>

      {/* Filters Card */}
      <div className="bg-white rounded-2xl p-5 shadow-sm border border-nearvibe-100 space-y-5">
        {/* Distance */}
        <div>
          <label className="flex items-center justify-between text-sm font-medium text-gray-700 mb-2">
            <span>📍 Distance</span>
            <span className="text-nearvibe-600 font-semibold">{distance} miles</span>
          </label>
          <input
            type="range"
            min="1"
            max="50"
            value={distance}
            onChange={(e) => setDistance(Number(e.target.value))}
            className="w-full h-2 bg-nearvibe-100 rounded-full appearance-none cursor-pointer accent-nearvibe-600"
          />
          <div className="flex justify-between text-xs text-gray-400 mt-1">
            <span>1 mi</span>
            <span>50 mi</span>
          </div>
        </div>

        {/* Time Available */}
        <div>
          <label className="flex items-center justify-between text-sm font-medium text-gray-700 mb-2">
            <span>⏱️ Time Available</span>
            <span className="text-nearvibe-600 font-semibold">{timeAvailable} {timeAvailable === 1 ? 'hour' : 'hours'}</span>
          </label>
          <input
            type="range"
            min="1"
            max="8"
            value={timeAvailable}
            onChange={(e) => setTimeAvailable(Number(e.target.value))}
            className="w-full h-2 bg-nearvibe-100 rounded-full appearance-none cursor-pointer accent-nearvibe-600"
          />
          <div className="flex justify-between text-xs text-gray-400 mt-1">
            <span>1 hr</span>
            <span>8 hrs</span>
          </div>
        </div>

        {/* Energy Level */}
        <div>
          <label className="text-sm font-medium text-gray-700 mb-2 block">
            ⚡ Energy Level
          </label>
          <div className="flex gap-2">
            {energyLevels.map((level) => (
              <button
                key={level}
                onClick={() => setEnergyLevel(level)}
                className={`flex-1 py-2 px-3 rounded-lg text-sm font-medium capitalize border transition-all ${
                  energyLevel === level
                    ? 'bg-nearvibe-600 text-white border-nearvibe-600 shadow-sm'
                    : 'bg-white text-gray-600 border-gray-200 hover:border-nearvibe-300'
                }`}
              >
                {level}
              </button>
            ))}
          </div>
        </div>

        {/* Budget */}
        <div>
          <label className="text-sm font-medium text-gray-700 mb-2 block">
            💵 Budget
          </label>
          <div className="grid grid-cols-4 gap-2">
            {budgetOptions.map((opt) => (
              <button
                key={opt.value}
                onClick={() => setBudget(opt.value)}
                className={`py-2 px-2 rounded-lg text-xs font-medium text-center border transition-all ${
                  budget === opt.value
                    ? 'bg-nearvibe-600 text-white border-nearvibe-600 shadow-sm'
                    : 'bg-white text-gray-600 border-gray-200 hover:border-nearvibe-300'
                }`}
              >
                <span className="block text-base mb-0.5">{opt.icon}</span>
                {opt.label}
              </button>
            ))}
          </div>
        </div>

        {/* Search Button */}
        <button
          onClick={handleSearch}
          disabled={loading}
          className="w-full bg-gradient-to-r from-nearvibe-600 to-nearvibe-500 text-white font-semibold py-3 px-6 rounded-xl hover:from-nearvibe-700 hover:to-nearvibe-600 transition-all disabled:opacity-50 disabled:cursor-not-allowed shadow-lg shadow-nearvibe-200"
        >
          {loading ? (
            <span className="flex items-center justify-center gap-2">
              <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
              </svg>
              Finding activities...
            </span>
          ) : (
            '🔍 Find Activities'
          )}
        </button>
      </div>

      {/* Results */}
      {loading && (
        <div className="space-y-4">
          {[1, 2, 3].map((i) => (
            <FilterSkeleton key={i} />
          ))}
        </div>
      )}

      {results && !loading && results.suggestions?.length > 0 && (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-semibold text-gray-800">
              Suggestions for You
            </h2>
            <span className="text-xs text-gray-400">
              within {distance} miles • {energyLevel} energy • {budget}
            </span>
          </div>
          <div className="space-y-4">
            {results.suggestions.map((activity) => (
              <ActivityCard key={activity.id} activity={activity} />
            ))}
          </div>
        </div>
      )}

      {results && !loading && results.suggestions?.length === 0 && (
        <div className="text-center py-12 text-gray-400">
          <span className="text-4xl block mb-3">😕</span>
          <p className="font-medium">No activities found</p>
          <p className="text-sm mt-1">Try adjusting your filters</p>
        </div>
      )}

      {!results && !loading && (
        <div className="text-center py-12 text-gray-400">
          <span className="text-4xl block mb-3">🔍</span>
          <p className="font-medium">Set your filters and find activities</p>
          <p className="text-sm mt-1">We'll suggest things to do near you</p>
        </div>
      )}
    </div>
  )
}
