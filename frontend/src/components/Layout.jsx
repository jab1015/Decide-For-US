import { Outlet, NavLink, useLocation, Link } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

const navItems = [
  { path: '/', label: 'Home', icon: '🏠' },
  { path: '/discover', label: 'Discover', icon: '🔍' },
  { path: '/premium', label: 'Premium', icon: '⭐' },
  { path: '/settings', label: 'Settings', icon: '⚙️' },
]

export default function Layout() {
  const location = useLocation()
  const { user } = useAuth()
  const isAuthPage = location.pathname === '/auth'

  return (
    <div className="min-h-screen bg-gradient-to-br from-nearvibe-50 via-white to-energy-50 flex flex-col">
      {/* Header - hidden on auth page */}
      {!isAuthPage && (
        <header className="bg-white/80 backdrop-blur-md border-b border-nearvibe-100 sticky top-0 z-50">
          <div className="max-w-2xl mx-auto px-4 h-14 flex items-center justify-between">
            <NavLink to="/" className="flex items-center gap-2 no-underline">
              <span className="text-2xl">✨</span>
              <span className="text-xl font-bold bg-gradient-to-r from-nearvibe-600 to-energy-500 bg-clip-text text-transparent">
                NearVibe
              </span>
            </NavLink>
            <div className="flex items-center gap-3">
              {user ? (
                <>
                  {user.is_premium && (
                    <span className="text-xs bg-nearvibe-100 text-nearvibe-700 font-medium px-2 py-0.5 rounded-full">
                      ⭐ Premium
                    </span>
                  )}
                  <Link
                    to="/settings"
                    className="text-sm text-gray-500 hover:text-nearvibe-600 transition-colors no-underline"
                  >
                    {user.email?.split('@')[0] || 'Profile'}
                  </Link>
                </>
              ) : (
                <>
                  <NavLink
                    to="/auth"
                    className="text-sm text-nearvibe-600 hover:text-nearvibe-800 transition-colors no-underline"
                  >
                    Sign In
                  </NavLink>
                  <NavLink
                    to="/auth"
                    className="text-sm bg-nearvibe-600 text-white px-4 py-1.5 rounded-full hover:bg-nearvibe-700 transition-all no-underline shadow-sm"
                  >
                    Get Started
                  </NavLink>
                </>
              )}
            </div>
          </div>
        </header>
      )}

      {/* Main Content */}
      <main className="flex-1 max-w-2xl mx-auto w-full px-4 py-6 pb-24">
        <Outlet />
      </main>

      {/* Bottom Navigation Bar */}
      {!isAuthPage && (
        <nav className="fixed bottom-0 left-0 right-0 bg-white/90 backdrop-blur-lg border-t border-nearvibe-100 z-50 safe-area-bottom">
          <div className="max-w-2xl mx-auto px-2">
            <div className="flex justify-around items-center h-16">
              {navItems.map((item) => {
                const isActive = location.pathname === item.path ||
                  (item.path !== '/' && location.pathname.startsWith(item.path))
                return (
                  <NavLink
                    key={item.path}
                    to={item.path}
                    className={`flex flex-col items-center gap-0.5 px-3 py-1.5 rounded-lg transition-all no-underline ${
                      isActive
                        ? 'text-nearvibe-600 scale-105'
                        : 'text-gray-400 hover:text-gray-600'
                    }`}
                  >
                    <span className="text-xl">{item.icon}</span>
                    <span className="text-[10px] font-medium">{item.label}</span>
                  </NavLink>
                )
              })}
            </div>
          </div>
        </nav>
      )}
    </div>
  )
}