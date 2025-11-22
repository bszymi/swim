import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from './contexts/AuthContext';
import { ProtectedRoute } from './components/auth/ProtectedRoute';
import { MainLayout } from './components/layout/MainLayout';
import { HomePage } from './pages/HomePage';
import { LoginPage } from './pages/LoginPage';
import { SignupPage } from './pages/SignupPage';
import ForgotPasswordPage from './pages/ForgotPasswordPage';
import ResetPasswordPage from './pages/ResetPasswordPage';
import { DashboardPage } from './pages/DashboardPage';
import { SwimmersPage } from './pages/SwimmersPage';
import { NewSwimmerPage } from './pages/NewSwimmerPage';
import { MeetingsPage } from './pages/MeetingsPage';
import { NewMeetingPage } from './pages/NewMeetingPage';
import { MeetingReviewPage } from './pages/MeetingReviewPage';
import { MeetingDetailPage } from './pages/MeetingDetailPage';
import { SwimmerDetailPage } from './pages/SwimmerDetailPage';
import AdminUsersPage from './pages/AdminUsersPage';
import EditMeetingPage from './pages/EditMeetingPage';
import ErrorReportsPage from './pages/ErrorReportsPage';

// Create a client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
      staleTime: 5 * 60 * 1000, // 5 minutes
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <Router>
          <Routes>
            {/* Public routes */}
            <Route path="/" element={<HomePage />} />
            <Route path="/login" element={<LoginPage />} />
            <Route path="/signup" element={<SignupPage />} />
            <Route path="/forgot-password" element={<ForgotPasswordPage />} />
            <Route path="/reset-password/:token" element={<ResetPasswordPage />} />

            {/* Protected routes */}
            <Route element={<ProtectedRoute />}>
              <Route element={<MainLayout />}>
                <Route path="/dashboard" element={<DashboardPage />} />
                <Route path="/swimmers" element={<SwimmersPage />} />
                <Route path="/swimmers/new" element={<NewSwimmerPage />} />
                <Route path="/swimmers/:se_id" element={<SwimmerDetailPage />} />
                <Route path="/meetings" element={<MeetingsPage />} />
                <Route path="/meetings/new" element={<NewMeetingPage />} />
                <Route path="/meetings/:id/review" element={<MeetingReviewPage />} />
                <Route path="/meetings/:id/edit" element={<EditMeetingPage />} />
                <Route path="/meetings/:id" element={<MeetingDetailPage />} />
                <Route path="/admin/users" element={<AdminUsersPage />} />
                <Route path="/admin/error-reports" element={<ErrorReportsPage />} />
              </Route>
            </Route>
          </Routes>
        </Router>
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;
