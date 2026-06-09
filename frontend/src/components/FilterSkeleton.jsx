export default function FilterSkeleton() {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-nearvibe-100 overflow-hidden animate-pulse">
      <div className="h-32 bg-gray-100" />
      <div className="p-4 space-y-3">
        <div className="flex gap-2">
          <div className="flex-1 space-y-2">
            <div className="h-4 bg-gray-200 rounded w-3/4" />
            <div className="h-3 bg-gray-200 rounded w-1/2" />
          </div>
          <div className="h-6 w-16 bg-gray-200 rounded-full" />
        </div>
        <div className="h-3 bg-gray-200 rounded w-2/3" />
        <div className="flex gap-3">
          <div className="h-3 bg-gray-200 rounded w-20" />
          <div className="h-3 bg-gray-200 rounded w-16" />
        </div>
        <div className="h-4 bg-gray-200 rounded w-28" />
        <div className="pt-3 border-t border-gray-100">
          <div className="h-12 bg-gray-100 rounded-lg" />
        </div>
      </div>
    </div>
  )
}
