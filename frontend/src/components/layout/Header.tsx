import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import { Button } from '../common/Button';

export const Header: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [adminMenuOpen, setAdminMenuOpen] = useState(false);

  const handleLogout = async () => {
    await logout();
    navigate('/');
  };

  return (
    <header className="bg-white shadow-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          {/* Logo */}
          <Link to="/dashboard" className="text-2xl font-bold text-blue-600">
            Swim
          </Link>

          {/* Desktop Navigation */}
          <nav className="hidden md:flex space-x-8">
            <Link to="/dashboard" className="text-gray-700 hover:text-blue-600 transition-colors">
              Dashboard
            </Link>
            <Link to="/swimmers" className="text-gray-700 hover:text-blue-600 transition-colors">
              Swimmers
            </Link>
            <Link to="/meetings" className="text-gray-700 hover:text-blue-600 transition-colors">
              Meetings
            </Link>
            {user?.is_admin && (
              <div className="relative">
                <button
                  onClick={() => setAdminMenuOpen(!adminMenuOpen)}
                  className="text-purple-600 hover:text-purple-700 font-semibold transition-colors flex items-center gap-1"
                >
                  Admin
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                  </svg>
                </button>
                {adminMenuOpen && (
                  <div className="absolute left-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-50 border border-gray-200">
                    <Link
                      to="/admin/users"
                      className="block px-4 py-2 text-sm text-gray-700 hover:bg-purple-50"
                      onClick={() => setAdminMenuOpen(false)}
                    >
                      Users
                    </Link>
                    <Link
                      to="/admin/error-reports"
                      className="block px-4 py-2 text-sm text-gray-700 hover:bg-purple-50"
                      onClick={() => setAdminMenuOpen(false)}
                    >
                      Error Reports
                    </Link>
                  </div>
                )}
              </div>
            )}
          </nav>

          {/* User Menu */}
          <div className="hidden md:flex items-center space-x-4">
            <span className="text-gray-700">{user?.email}</span>
            <Button variant="ghost" size="sm" onClick={handleLogout}>
              Logout
            </Button>
          </div>

          {/* Mobile menu button */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="md:hidden p-2 rounded-md text-gray-700 hover:bg-gray-100"
          >
            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
        </div>
      </div>

      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <div className="md:hidden border-t border-gray-200">
          <div className="px-2 pt-2 pb-3 space-y-1">
            <Link
              to="/dashboard"
              className="block px-3 py-2 rounded-md text-gray-700 hover:bg-gray-100"
              onClick={() => setMobileMenuOpen(false)}
            >
              Dashboard
            </Link>
            <Link
              to="/swimmers"
              className="block px-3 py-2 rounded-md text-gray-700 hover:bg-gray-100"
              onClick={() => setMobileMenuOpen(false)}
            >
              Swimmers
            </Link>
            <Link
              to="/meetings"
              className="block px-3 py-2 rounded-md text-gray-700 hover:bg-gray-100"
              onClick={() => setMobileMenuOpen(false)}
            >
              Meetings
            </Link>
            {user?.is_admin && (
              <>
                <div className="px-3 py-2 text-sm font-semibold text-purple-600">Admin</div>
                <Link
                  to="/admin/users"
                  className="block px-6 py-2 rounded-md text-gray-700 hover:bg-purple-50"
                  onClick={() => setMobileMenuOpen(false)}
                >
                  Users
                </Link>
                <Link
                  to="/admin/error-reports"
                  className="block px-6 py-2 rounded-md text-gray-700 hover:bg-purple-50"
                  onClick={() => setMobileMenuOpen(false)}
                >
                  Error Reports
                </Link>
              </>
            )}
            <div className="border-t border-gray-200 pt-2">
              <div className="px-3 py-2 text-sm text-gray-600">{user?.email}</div>
              <button
                onClick={() => {
                  setMobileMenuOpen(false);
                  handleLogout();
                }}
                className="block w-full text-left px-3 py-2 rounded-md text-gray-700 hover:bg-gray-100"
              >
                Logout
              </button>
            </div>
          </div>
        </div>
      )}
    </header>
  );
};
