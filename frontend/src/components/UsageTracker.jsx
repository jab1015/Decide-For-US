export default function UsageTracker({ used = 0, max = 3 }) {
  const remaining = max - used
  const percent = Math.min((used / max) * 100, 100)

  return (
    <div className="bg-white rounded-xl border border-nearvibe-100 shadow-sm p-3 min-w-[140px]">
      <div className="flex items-center justify-between mb-1.5">
        <span className="text-xs text-gray-500 font-medium">Free uses</span>
        <span className={`text-xs font-bold ${
          remaining > 0 ? 'text-nearvibe-600' : 'text-energy-600'
        }`}>
          {remaining}/{max} left
        </span>
      </div>
      <div className="w-full h-2 bg-gray-100 rounded-full overflow-hidden">
        <div
          className={`h-full rounded-full transition-all duration-500 ${
            remaining > 1
              ? 'bg-nearvibe-400'
              : remaining === 1
              ? 'bg-energy-400'
              : 'bg-red-400'
          }`}
          style={{ width: `${percent}%` }}
        />
      </div>
      <p className="text-[10px] text-gray-400 mt-1.5 text-center">
        Resets weekly
      </p>
    </div>
  )
}
