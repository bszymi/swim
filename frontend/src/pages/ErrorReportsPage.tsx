import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { errorReportsService, type ErrorReport } from '../services/errorReports.service';
import { useAuth } from '../hooks/useAuth';

export default function ErrorReportsPage() {
  const [reports, setReports] = useState<ErrorReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<'all' | 'pending' | 'resolved'>('all');
  const navigate = useNavigate();
  const { user } = useAuth();

  useEffect(() => {
    if (!user?.is_admin) {
      navigate('/dashboard');
      return;
    }

    loadReports();
  }, [filter, user, navigate]);

  const loadReports = async () => {
    try {
      setLoading(true);
      const status = filter === 'all' ? undefined : filter;
      const data = await errorReportsService.getAll(status);
      setReports(data);
      setError(null);
    } catch (err: any) {
      if (err.response?.status === 403) {
        setError('Unauthorized. Admin access required.');
        setTimeout(() => navigate('/dashboard'), 2000);
      } else {
        setError('Failed to load error reports');
      }
      console.error('Error loading reports:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleResolve = async (reportId: number) => {
    if (!confirm('Mark this error report as resolved?')) {
      return;
    }

    try {
      await errorReportsService.updateStatus(reportId, 'resolved');
      await loadReports();
    } catch (err) {
      console.error('Error resolving report:', err);
      alert('Failed to resolve report');
    }
  };

  const handleReopen = async (reportId: number) => {
    if (!confirm('Reopen this error report?')) {
      return;
    }

    try {
      await errorReportsService.updateStatus(reportId, 'pending');
      await loadReports();
    } catch (err) {
      console.error('Error reopening report:', err);
      alert('Failed to reopen report');
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-GB', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-xl">Loading error reports...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-xl text-red-500">{error}</div>
      </div>
    );
  }

  const pendingCount = reports.filter((r) => r.status === 'pending').length;
  const resolvedCount = reports.filter((r) => r.status === 'resolved').length;

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">Error Reports</h1>
        <button
          onClick={() => navigate('/dashboard')}
          className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
        >
          Back to Dashboard
        </button>
      </div>

      <div className="mb-6 flex gap-4">
        <button
          onClick={() => setFilter('all')}
          className={`px-4 py-2 rounded ${
            filter === 'all'
              ? 'bg-blue-600 text-white'
              : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
          }`}
        >
          All ({reports.length})
        </button>
        <button
          onClick={() => setFilter('pending')}
          className={`px-4 py-2 rounded ${
            filter === 'pending'
              ? 'bg-orange-600 text-white'
              : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
          }`}
        >
          Pending ({pendingCount})
        </button>
        <button
          onClick={() => setFilter('resolved')}
          className={`px-4 py-2 rounded ${
            filter === 'resolved'
              ? 'bg-green-600 text-white'
              : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
          }`}
        >
          Resolved ({resolvedCount})
        </button>
      </div>

      {reports.length === 0 ? (
        <div className="bg-white shadow-md rounded-lg p-8 text-center">
          <p className="text-gray-600">
            {filter === 'all'
              ? 'No error reports yet.'
              : `No ${filter} error reports.`}
          </p>
        </div>
      ) : (
        <div className="bg-white shadow-md rounded-lg overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Meeting
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Reported By
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Description
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Reported
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {reports.map((report) => (
                <tr key={report.id}>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <button
                      onClick={() => navigate(`/meetings/${report.meeting_id}`)}
                      className="text-sm font-medium text-blue-600 hover:text-blue-800"
                    >
                      {report.meeting_name}
                    </button>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700">
                    {report.user_email}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-700 max-w-md">
                    <div className="line-clamp-3">{report.description}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                        report.status === 'pending'
                          ? 'bg-orange-100 text-orange-800'
                          : 'bg-green-100 text-green-800'
                      }`}
                    >
                      {report.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {formatDate(report.created_at)}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    {report.status === 'pending' ? (
                      <button
                        onClick={() => handleResolve(report.id)}
                        className="text-green-600 hover:text-green-900"
                      >
                        Resolve
                      </button>
                    ) : (
                      <button
                        onClick={() => handleReopen(report.id)}
                        className="text-orange-600 hover:text-orange-900"
                      >
                        Reopen
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
