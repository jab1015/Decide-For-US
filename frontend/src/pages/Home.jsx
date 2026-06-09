import { Link } from 'react-router-dom'

export default function Home() {
  return (
    <div className="flex flex-col items-center text-center min-h-[calc(100vh-12rem)] justify-center gap-8">
      {/* Hero Section */}
      <div className="space-y-4">
        <div className="inline-flex items-center gap-2 bg-nearvibe-100 text-nearvibe-800 px-4 py-1.5 rounded-full text-sm font-medium">
          <span className="w-2 h-2 bg-nearvibe-500 rounded-full animate-pulse" />
          Find your vibe, near you
        </div>
        <h1 className="text-4xl md:text-5xl font-bold text-gray-900 leading-tight">
          What to do
          <span className="block bg-gradient-to-r from-nearvibe-500 to-energy-500 bg-clip-text text-transparent">
            right now?
          </span>
        </h1>
        <p className="text-lg text-gray-500 max-w-md mx-auto">
          Tell us your mood, budget, and how much time you have. We'll find the perfect activity nearby.
        </p>
      </div>

      {/* Feature Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 w-full max-w-lg">
        <div className="bg-white rounded-xl p-4 shadow-sm border border-nearvibe-100 text-left">
          <span className="text-2xl">⚡</span>
          <h3 className="font-semibold text-gray-800 mt-2">Quick & Easy</h3>
          <p className="text-sm text-gray-500 mt-1">3 taps to find something fun</p>
        </div>
        <div className="bg-white rounded-xl p-4 shadow-sm border border-nearvibe-100 text-left">
          <span className="text-2xl">📍</span>
          <h3 className="font-semibold text-gray-800 mt-2">Local Vibes</h3>
          <p className="text-sm text-gray-500 mt-1">Activities near your location</p>
        </div>
        <div className="bg-white rounded-xl p-4 shadow-sm border border-nearvibe-100 text-left">
          <span className="text-2xl">💑</span>
          <h3 className="font-semibold text-gray-800 mt-2">Date Night</h3>
          <p className="text-sm text-gray-500 mt-1">Premium romantic planning</p>
        </div>
      </div>

      {/* CTA Buttons */}
      <div className="flex flex-col sm:flex-row gap-3 w-full max-w-sm">
        <Link
          to="/discover"
          className="flex-1 bg-nearvibe-600 text-white font-semibold py-3 px-6 rounded-xl hover:bg-nearvibe-700 transition-all text-center shadow-lg shadow-nearvibe-200"
        >
          Find Activities
        </Link>
        <Link
          to="/premium"
          className="flex-1 bg-white text-nearvibe-600 font-semibold py-3 px-6 rounded-xl border-2 border-nearvibe-200 hover:border-nearvibe-400 transition-all text-center"
        >
          Go Premium
        </Link>
      </div>

      {/* Free Tier Info */}
      <p className="text-sm text-gray-400">
        ✨ Free users get <strong className="text-nearvibe-600">3 suggestions</strong> per week
      </p>
    </div>
  )
}