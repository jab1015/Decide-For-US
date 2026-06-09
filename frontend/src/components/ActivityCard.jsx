export default function ActivityCard({ activity }) {
  const url = activity.website_url || activity.venue_url

  return (
    <div className="bg-white rounded-xl shadow-sm border border-nearvibe-100 overflow-hidden hover:shadow-md transition-all">
      {/* Image placeholder */}
      <div className="h-32 bg-gradient-to-br from-nearvibe-100 to-energy-100 flex items-center justify-center">
        <span className="text-4xl">📍</span>
      </div>

      <div className="p-4 space-y-3">
        {/* Title & Energy Badge */}
        <div className="flex items-start justify-between gap-2">
          <div>
            <h3 className="font-semibold text-gray-900">{activity.name}</h3>
            <p className="text-sm text-gray-500">{activity.venue}</p>
          </div>
          {activity.energy_level && (
            <span className={`text-xs font-medium px-2 py-0.5 rounded-full border capitalize whitespace-nowrap ${
              activity.energy_level === 'low'
                ? 'bg-green-100 text-green-700 border-green-200'
                : activity.energy_level === 'medium'
                ? 'bg-energy-100 text-energy-700 border-energy-200'
                : 'bg-red-100 text-red-700 border-red-200'
            }`}>
              ⚡ {activity.energy_level}
            </span>
          )}
        </div>

        {/* Description */}
        {activity.description && (
          <p className="text-sm text-gray-500">{activity.description}</p>
        )}

        {/* Address with map pin */}
        {activity.address && (
          <div className="flex items-start gap-2 text-sm text-gray-500">
            <span className="mt-0.5">📍</span>
            <span>{activity.address}</span>
          </div>
        )}

        {/* Duration & Budget */}
        <div className="flex gap-3 text-xs text-gray-500">
          {activity.estimated_duration && <span>⏱️ {activity.estimated_duration}</span>}
          {activity.budget && <span>💵 {activity.budget}</span>}
        </div>

        {/* Venue Link */}
        {url && (
          <a
            href={url}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1 text-sm text-nearvibe-600 font-medium hover:text-nearvibe-800 transition-colors"
          >
            🌐 Open Website
            <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
            </svg>
          </a>
        )}

        {/* Companion Activity */}
        {activity.companion_activity && (
          <div className="mt-2 pt-3 border-t border-nearvibe-50">
            <div className="flex items-start gap-2 bg-nearvibe-50 rounded-lg p-2.5">
              <span className="text-sm">🎯</span>
              <div>
                <p className="text-xs font-medium text-nearvibe-700">Also nearby:</p>
                <p className="text-sm text-gray-600">{activity.companion_activity}</p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}