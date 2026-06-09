import { useState } from 'react'
import { useSearchParams, useNavigate, Link } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import api from '../api/client'

const features = [
  { icon: '♾️', title: 'Unlimited Suggestions', desc: 'No weekly limits on finding activities', free: true },
  { icon: '💑', title: 'Date Night Mode', desc: 'Romantic activity planning with vibe settings', free: false },
  { icon: '🗺️', title: 'Trip Itineraries', desc: 'Full day and weekend trip plans', free: false },
  { icon: '📊', title: 'Advanced Filters', desc: 'More filter options and saved preferences', free: false },
  { icon: '📍', title: 'Custom Locations', desc: 'Set any location, not just current place', free: false },
  { icon: '🎯', title: 'Priority Support', desc: 'Fast response when you need help', free: false },
]

const plans = [
  {
    name: 'Monthly',
    price: '$9.99',
    period: '/month',
    popular: true,
    items: ['Unlimited activity suggestions', 'Date Night mode', 'Trip planner', 'Advanced filters', 'Custom locations', 'Priority support'],
  },
  {
    name: 'Yearly',
    price: '$39.99',
    period: '/year',
    popular: false,
    badge: 'Best Value',
    items: ['Everything in Monthly', '2 months free', 'Early access to features', 'Priority support'],
  },
]

export default function Premium() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const showUpgradePrompt = searchParams.get('upgrade') === '1'
  const isPremium = user?.is_premium

  const handleSubscribe = async (plan) => {
    if (!user) {
      navigate('/auth')
      return
    }
    setLoading(true)
    setError('')
    try {
      const data = await api.subscribe()
      // Redirect to Stripe Checkout
      if (data.url) {
        window.location.href = data.url
      }
    } catch (err) {
      setError(err.message || 'Failed to start subscription')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="text-center space-y-2">
        {showUpgradePrompt && (
          <div className="bg-energy-50 border border-energy-200 rounded-xl p-4 mb-4">
            <span className="text-xl">⭐</span>
            <h3 className="font-semibold text-energy-800 mt-1">Upgrade to Premium</h3>
            <p className="text-sm text-energy-600">
              Unlock Date Night & Trip Planning!
            </p>
          </div>
        )}
        <span className="text-4xl">⭐</span>
        <h1 className="text-3xl font-bold text-gray-900">Go Premium</h1>
        <p className="text-gray-500 max-w-sm mx-auto">
          Unlock the full NearVibe experience — date nights, trip planning, and unlimited activities.
        </p>
      </div>

      {isPremium ? (
        <div className="bg-nearvibe-50 border border-nearvibe-200 rounded-2xl p-6 text-center">
          <span className="text-4xl">🎉</span>
          <h2 className="text-xl font-bold text-nearvibe-800 mt-2">You're a Premium Member!</h2>
          <p className="text-nearvibe-600 mt-1">Enjoy unlimited access to all features.</p>
          <button
            onClick={() => navigate('/date-night')}
            className="mt-4 bg-nearvibe-600 text-white font-semibold py-2.5 px-6 rounded-xl hover:bg-nearvibe-700 transition-all"
          >
            Plan a Date Night
          </button>
        </div>
      ) : (
        <>
          {/* Feature Comparison */}
          <div className="bg-white rounded-2xl p-5 shadow-sm border border-nearvibe-100">
            <h2 className="font-semibold text-gray-800 mb-4 text-center">Free vs Premium</h2>
            <div className="divide-y divide-gray-100">
              {features.map((f) => (
                <div key={f.title} className="flex items-center justify-between py-3">
                  <div className="flex items-center gap-2">
                    <span>{f.icon}</span>
                    <div>
                      <p className="text-sm font-medium text-gray-800">{f.title}</p>
                      <p className="text-xs text-gray-400">{f.desc}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                      f.free
                        ? 'bg-green-100 text-green-700'
                        : 'bg-gray-100 text-gray-400'
                    }`}>
                      {f.free ? 'Free' : 'Premium'}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Pricing Cards */}
          <div className="space-y-4">
            {plans.map((plan) => (
              <div
                key={plan.name}
                className={`relative bg-white rounded-2xl p-6 shadow-sm border-2 transition-all ${
                  plan.popular ? 'border-nearvibe-400 shadow-lg shadow-nearvibe-100' : 'border-gray-100'
                }`}
              >
                {plan.badge && (
                  <span className="absolute -top-3 left-1/2 -translate-x-1/2 bg-energy-500 text-white text-xs font-bold px-4 py-1 rounded-full">
                    {plan.badge}
                  </span>
                )}
                {plan.popular && (
                  <span className="absolute -top-3 left-1/2 -translate-x-1/2 bg-nearvibe-600 text-white text-xs font-bold px-4 py-1 rounded-full">
                    Most Popular
                  </span>
                )}
                <div className="text-center">
                  <h3 className="font-bold text-gray-900 text-lg">{plan.name}</h3>
                  <div className="mt-2">
                    <span className="text-4xl font-bold text-gray-900">{plan.price}</span>
                    <span className="text-gray-400 text-sm">{plan.period}</span>
                  </div>
                </div>
                <ul className="mt-4 space-y-2">
                  {plan.items.map((f) => (
                    <li key={f} className="text-sm text-gray-600 flex items-center gap-2">
                      <span className="text-nearvibe-500">✓</span> {f}
                    </li>
                  ))}
                </ul>
                <button
                  onClick={() => handleSubscribe(plan.name.toLowerCase())}
                  disabled={loading}
                  className={`w-full mt-5 font-semibold py-3 rounded-xl transition-all text-sm ${
                    plan.popular
                      ? 'bg-nearvibe-600 text-white hover:bg-nearvibe-700 shadow-md disabled:opacity-50'
                      : 'bg-white text-nearvibe-600 border-2 border-nearvibe-200 hover:border-nearvibe-400 disabled:opacity-50'
                  }`}
                >
                  {loading ? 'Redirecting to checkout...' : `Subscribe ${plan.name}`}
                </button>
              </div>
            ))}
          </div>

          {error && (
            <p className="text-sm text-red-500 bg-red-50 rounded-xl p-3 text-center">{error}</p>
          )}
        </>
      )}

      {/* Free tier reminder */}
      <div className="bg-white/60 rounded-2xl p-5 text-center border border-dashed border-gray-200">
        <p className="text-sm text-gray-500">
          Still deciding?{' '}
          <Link to="/discover" className="text-nearvibe-600 font-medium hover:text-nearvibe-800">
            Try 3 free suggestions
          </Link>
        </p>
      </div>
    </div>
  )
}
