import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import { api } from '../api/client'

export default function Auth() {
  const navigate = useNavigate()
  const { login, register, refreshUser } = useAuth()

  const [isLogin, setIsLogin] = useState(true)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [age, setAge] = useState('')
  const [parentEmail, setParentEmail] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [showParentConsent, setShowParentConsent] = useState(false)
  const [ageVerificationStatus, setAgeVerificationStatus] = useState(null)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      if (isLogin) {
        await login(email, password)
        navigate('/discover')
      } else {
        const ageNum = parseInt(age)
        const data = await register(email, password, ageNum)

        if (ageNum < 18) {
          setShowParentConsent(true)
          setAgeVerificationStatus('pending')
        } else {
          // Auto-verify age for 18+
          await api.verifyAge({ age: ageNum }).catch(() => {})
          await refreshUser()
          navigate('/discover')
        }
      }
    } catch (err) {
      setError(err.message || 'Something went wrong')
    } finally {
      setLoading(false)
    }
  }

  const handleParentalConsent = async () => {
    if (!parentEmail) return
    setLoading(true)
    setError('')
    try {
      await api.parentalConsent({ parentEmail })
      setAgeVerificationStatus('pending')
      alert('Parental consent request sent! Your parent/guardian will receive an email.')
      navigate('/settings')
    } catch (err) {
      setError(err.message || 'Failed to send consent request')
    } finally {
      setLoading(false)
    }
  }

  if (showParentConsent) {
    return (
      <div className="min-h-[calc(100vh-8rem)] flex items-center justify-center">
        <div className="w-full max-w-sm space-y-6">
          <div className="text-center">
            <span className="text-4xl">📋</span>
            <h1 className="text-2xl font-bold text-gray-900 mt-2">Parental Consent Required</h1>
            <p className="text-sm text-gray-500 mt-1">
              Since you're under 18, we need a parent or guardian to approve your account (Texas law compliance).
            </p>
          </div>

          <div className="bg-white rounded-2xl p-6 shadow-sm border border-nearvibe-100 space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Parent/Guardian Email
              </label>
              <input
                type="email"
                value={parentEmail}
                onChange={(e) => setParentEmail(e.target.value)}
                placeholder="parent@example.com"
                className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:border-nearvibe-400 focus:ring-2 focus:ring-nearvibe-100 outline-none transition-all text-sm"
              />
              <p className="text-xs text-gray-400 mt-1">
                We'll email them with a consent request link
              </p>
            </div>

            {error && (
              <p className="text-sm text-red-500 bg-red-50 rounded-lg p-3">{error}</p>
            )}

            <button
              onClick={handleParentalConsent}
              disabled={loading || !parentEmail}
              className="w-full bg-nearvibe-600 text-white font-semibold py-3 rounded-xl hover:bg-nearvibe-700 transition-all disabled:opacity-50"
            >
              {loading ? 'Sending...' : 'Send Consent Request'}
            </button>

            <p className="text-xs text-gray-400 text-center">
              Your account will be limited until parental consent is approved
            </p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-[calc(100vh-8rem)] flex items-center justify-center">
      <div className="w-full max-w-sm space-y-6">
        <div className="text-center">
          <span className="text-4xl">✨</span>
          <h1 className="text-2xl font-bold text-gray-900 mt-2">
            {isLogin ? 'Welcome Back' : 'Join NearVibe'}
          </h1>
          <p className="text-sm text-gray-500 mt-1">
            {isLogin ? 'Sign in to continue' : 'Create your account'}
          </p>
        </div>

        <form onSubmit={handleSubmit} className="bg-white rounded-2xl p-6 shadow-sm border border-nearvibe-100 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="you@example.com"
              required
              className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:border-nearvibe-400 focus:ring-2 focus:ring-nearvibe-100 outline-none transition-all text-sm"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
              minLength={6}
              className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:border-nearvibe-400 focus:ring-2 focus:ring-nearvibe-100 outline-none transition-all text-sm"
            />
          </div>

          {!isLogin && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Date of Birth (Age)</label>
              <select
                value={age}
                onChange={(e) => setAge(e.target.value)}
                required
                className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:border-nearvibe-400 focus:ring-2 focus:ring-nearvibe-100 outline-none transition-all text-sm"
              >
                <option value="">Select your age</option>
                {Array.from({ length: 83 }, (_, i) => {
                  const a = i + 13
                  return (
                    <option key={a} value={a}>{a} years old</option>
                  )
                })}
              </select>
            </div>
          )}

          {error && (
            <p className="text-sm text-red-500 bg-red-50 rounded-lg p-3">{error}</p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-nearvibe-600 text-white font-semibold py-3 rounded-xl hover:bg-nearvibe-700 transition-all disabled:opacity-50 shadow-sm"
          >
            {loading ? 'Loading...' : isLogin ? 'Sign In' : 'Create Account'}
          </button>

          <p className="text-xs text-gray-400 text-center">
            {isLogin ? "Don't have an account? " : 'Already have an account? '}
            <button
              type="button"
              onClick={() => { setIsLogin(!isLogin); setError('') }}
              className="text-nearvibe-600 font-medium hover:text-nearvibe-800"
            >
              {isLogin ? 'Sign up' : 'Sign in'}
            </button>
          </p>

          <p className="text-xs text-gray-400 text-center mt-2">
            By continuing, you agree to our Terms of Service and Privacy Policy
          </p>
        </form>

        <p className="text-center text-sm text-gray-500">
          <Link to="/" className="text-nearvibe-600 hover:text-nearvibe-800 font-medium">
            Back to Home
          </Link>
        </p>
      </div>
    </div>
  )
}
