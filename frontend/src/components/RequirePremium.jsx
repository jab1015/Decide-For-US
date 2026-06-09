import { Navigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

export default function RequirePremium({ children }) {
  const { isPremium, user, loading } = useAuth()

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="animate-spin h-8 w-8 border-4 border-nearvibe-200 border-t-nearvibe-600 rounded-full" />
      </div>
    )
  }

  if (!user) {
    return <Navigate to="/auth" replace />
  }

  if (!isPremium) {
    return <Navigate to="/premium?upgrade=1" replace />
  }

  return children
}