import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import api from '../api/client'

export default function Settings() {
  const navigate = useNavigate()
  const { user, logout, refreshUser, isPremium } = useAuth()
  const [usage, setUsage] = useState(null)
  const [ageVerified, setAgeVerified] = useState(user?.age_verification?.status === 'approved')
  const [showAgeModal, setShowAgeModal] = useState(false)
  const [birthYear, setBirthYear] = useState('')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (user) {
      api.getUsage().then(setUsage).catch(() => {})
      setAgeVerified(user?.age_verification?.status === 'approved')
    }
  }, [user])

  const handleAgeVerification = async () => {
    if (!birthYear) return
    setLoading(true)
    try {
      const age = new Date().getFullYear() - parseInt(birthYear)
      await api.verifyAge({ age })
      setAgeVerified(age >= 18)
      setShowAgeModal(false)
      await refreshUser()
    } catch (err) {
      alert(err.message || 'Verification failed')
    } finally {
      setLoading(false)
    }
  }

  const handleLogout = () => {
    logout()
    navigate('/')
  }

  if (!user) {
    return (
      <div className="text-center py-20">
        <span className="text-4xl">🔒</span>
        <h2 className="text-xl font-bold text-gray-900 mt-3">Sign in to view settings</h2>
        <button
          onClick={() => navigate('/auth')}
          className="mt-4 bg-nearvibe-600 text-white font-semibold py-2.5 px-6 rounded-xl hover:bg-nearvibe-700"
        >
          Sign In
        </button>
      </div>
    )
  }

  const used = usage?.count || 0
  const limit = usage?.limit || 3
  const percent = Math.min((used / limit) * 100, 100)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Settings</h1>
        <p className="text-sm text-gray-500">Manage your profile and preferences</p>
      </div>

      {/* Profile Section */}
      <div className="bg-white rounded-2xl p-5 shadow-sm border border-nearvibe-100 space-y-4">
        <h2 className="font-semibold text-gray-800 flex items-center gap-2">
          <span>👤</span> Profile
        </h2>
        <div className="space-y-2">
          <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
            <span className="text-sm text-gray-600">Email</span>
            <span className="text-sm font-medium text-gray-900">{user.email}</span>
          </div>
          {user.age !== undefined && (
            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
              <span className="text-sm text-gray-600">Age</span>
              <span className="text-sm font-medium text-gray-900">{user.age}</span>
            </div>
          )}
        </div>
      </div>

      {/* Subscription Status */}
      <div className="bg-white rounded-2xl p-5 shadow-sm border border-nearvibe-100 space-y-4">
        <h2 className="font-semibold text-gray-800 flex items-center gap-2">
          <span>⭐</span> Subscription
        </h2>
        <div className={`rounded-xl p-4 ${isPremium ? 'bg-nearvibe-50 border border-nearvibe-200' : 'bg-energy-50 border border-energy-200'}`}>
          <div className="flex items-center justify-between">
            <div>
              <p className="font-semibold text-gray-800">
                {isPremium ? 'Premium Member' : 'Free Plan'}
              </p>
              <p className="text-sm text-gray-500">
                {isPremium
                  ? 'Unlimited access to all features'
                  : `${limit - used} of ${limit} free uses remaining this week`
                }
              </p>
            </div>
            <span className={`text-xs font-bold px-3 py-1 rounded-full ${
              isPremium ? 'bg-nearvibe-600 text-white' : 'bg-energy-500 text-white'
            }`}>
              {isPremium ? 'ACTIVE' : 'FREE'}
            </span>
          </div>

          {!isPremium && (
            <div className="mt-3">
              <div className="w-full h-2 bg-gray-200 rounded-full overflow-hidden">
                <div
                  className={`h-full rounded-full transition-all ${
                    limit - used > 1 ? 'bg-nearvibe-400' : 'bg-energy-400'
                  }`}
                  style={{ width: `${percent}%` }}
                />
              </div>
              <p className="text-xs text-gray-400 mt-1.5 text-right">
                {used} / {limit} used
              </p>
            </div>
          )}

          {!isPremium && (
            <button
              onClick={() => navigate('/premium')}
              className="w-full mt-3 bg-nearvibe-600 text-white font-medium py-2.5 rounded-xl hover:bg-nearvibe-700 transition-all text-sm"
            >
              Upgrade to Premium
            </button>
          )}
        </div>
      </div>

      {/* Age Verification */}
      <div className="bg-white rounded-2xl p-5 shadow-sm border border-nearvibe-100 space-y-4">
        <h2 className="font-semibold text-gray-800 flex items-center gap-2">
          <span>🔞</span> Age Verification
        </h2>
        {ageVerified ? (
          <div className="bg-green-50 border border-green-200 rounded-xl p-3 text-sm text-green-700 flex items-center gap-2">
            <span>✅</span> Age verified
            {user?.age_verification?.status === 'pending' && (
              <span className="text-energy-600">(pending approval)</span>
            )}
          </div>
        ) : (
          <div>
            {user?.age_verification?.status === 'pending' ? (
              <div className="bg-energy-50 border border-energy-200 rounded-xl p-3 text-sm text-energy-700">
                <span>⏳</span> Age verification pending. 
                {user.age < 18 && ' Parental consent may be required.'}
              </div>
            ) : user?.age_verification?.status === 'rejected' ? (
              <div className="bg-red-50 border border-red-200 rounded-xl p-3 text-sm text-red-700">
                <span>❌</span> Age verification rejected
              </div>
            ) : (
              <button
                onClick={() => setShowAgeModal(true)}
                className="w-full bg-nearvibe-600 text-white font-medium py-2.5 rounded-xl hover:bg-nearvibe-700 transition-all text-sm"
              >
                Verify My Age
              </button>
            )}
          </div>
        )}
      </div>

      {/* Account Actions */}
      <div className="bg-white rounded-2xl p-5 shadow-sm border border-nearvibe-100 space-y-4">
        <h2 className="font-semibold text-gray-800 flex items-center gap-2">
          <span>🔧</span> Account
        </h2>
        <button
          onClick={handleLogout}
          className="w-full bg-white text-red-500 font-medium py-2.5 rounded-xl border border-red-200 hover:bg-red-50 transition-all text-sm"
        >
          Sign Out
        </button>
      </div>

      {/* Age Verification Modal */}
      {showAgeModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-6 max-w-sm w-full shadow-xl space-y-4">
            <h3 className="font-bold text-gray-900 text-lg">Age Verification</h3>
            <p className="text-sm text-gray-500">
              NearVibe complies with Texas law. We need to verify your age.
            </p>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Year of Birth</label>
              <select
                value={birthYear}
                onChange={(e) => setBirthYear(e.target.value)}
                className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:border-nearvibe-400 focus:ring-2 focus:ring-nearvibe-100 outline-none transition-all text-sm"
              >
                <option value="">Select year</option>
                {Array.from({ length: 100 }, (_, i) => {
                  const year = new Date().getFullYear() - i
                  return <option key={year} value={year}>{year}</option>
                })}
              </select>
            </div>
            <div className="flex gap-3">
              <button
                onClick={() => setShowAgeModal(false)}
                className="flex-1 py-2.5 rounded-xl border border-gray-200 text-gray-700 font-medium hover:bg-gray-50 transition-all text-sm"
              >
                Cancel
              </button>
              <button
                onClick={handleAgeVerification}
                disabled={!birthYear || loading}
                className="flex-1 bg-nearvibe-600 text-white font-medium py-2.5 rounded-xl hover:bg-nearvibe-700 transition-all text-sm disabled:opacity-50"
              >
                {loading ? 'Verifying...' : 'Verify'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
