import React from 'react';
import { Link } from 'react-router-dom';
import { useDashboard } from '../hooks/useDashboard';
import { Card } from '../components/common/Card';
import { Button } from '../components/common/Button';
import { Loading } from '../components/common/Loading';
import { formatDate } from '../utils/date.utils';
import { formatTime } from '../utils/time.utils';
import { Swimmer, Performance } from '../types/swimmer.types';
import { Meeting } from '../types/meeting.types';

export const DashboardPage: React.FC = () => {
  const { data, isLoading, error } = useDashboard();

  if (isLoading) return <Loading text="Loading dashboard..." />;
  if (error) return <div className="text-red-600">Error loading dashboard</div>;

  const stats = data?.stats || {};
  const swimmers = data?.swimmers || [];
  const meetings = data?.meetings || [];
  const recentPerformances = data?.recent_performances || [];

  return (
    <div>
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <div className="flex space-x-4">
          <Link to="/swimmers/new">
            <Button>Add Swimmer</Button>
          </Link>
          <Link to="/meetings/new">
            <Button variant="secondary">Upload Meeting</Button>
          </Link>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <Card>
          <div className="text-center">
            <div className="text-4xl font-bold text-blue-600">{stats.total_swimmers || 0}</div>
            <div className="text-gray-600 mt-2">Swimmers</div>
          </div>
        </Card>

        <Card>
          <div className="text-center">
            <div className="text-4xl font-bold text-green-600">{stats.total_performances || 0}</div>
            <div className="text-gray-600 mt-2">Performances</div>
          </div>
        </Card>

        <Card>
          <div className="text-center">
            <div className="text-4xl font-bold text-purple-600">{stats.total_meets || 0}</div>
            <div className="text-gray-600 mt-2">Meetings</div>
          </div>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Swimmers */}
        <Card title="Your Swimmers">
          {swimmers.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              <p className="mb-4">No swimmers yet</p>
              <Link to="/swimmers/new">
                <Button>Add Your First Swimmer</Button>
              </Link>
            </div>
          ) : (
            <div className="space-y-4">
              {swimmers.slice(0, 5).map((swimmer: Swimmer) => (
                <Link
                  key={swimmer.id}
                  to={`/swimmers/${swimmer.se_membership_id}`}
                  className="block p-4 hover:bg-gray-50 rounded-lg transition-colors"
                >
                  <div className="font-medium text-gray-900">
                    {swimmer.first_name} {swimmer.last_name}
                  </div>
                  <div className="text-sm text-gray-600">
                    {swimmer.club} • {swimmer.sex}
                  </div>
                </Link>
              ))}
              {swimmers.length > 5 && (
                <Link to="/swimmers" className="block text-center text-blue-600 hover:text-blue-700 font-medium">
                  View All Swimmers
                </Link>
              )}
            </div>
          )}
        </Card>

        {/* Recent Performances */}
        <Card title="Recent Performances">
          {recentPerformances.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              No performances yet
            </div>
          ) : (
            <div className="space-y-4">
              {recentPerformances.slice(0, 5).map((perf: Performance, index: number) => (
                <div key={index} className="p-4 bg-gray-50 rounded-lg">
                  <div className="flex justify-between items-start">
                    <div>
                      <div className="font-medium text-gray-900">
                        {perf.distance_m}m {perf.stroke} ({perf.course_type})
                      </div>
                      <div className="text-sm text-gray-600">{formatDate(perf.date)}</div>
                    </div>
                    <div className="text-lg font-semibold text-blue-600">
                      {formatTime(perf.time_seconds)}
                    </div>
                  </div>
                  <div className="text-sm text-gray-600 mt-1">{perf.meet_name}</div>
                </div>
              ))}
            </div>
          )}
        </Card>
      </div>

      {/* Meetings */}
      {meetings.length > 0 && (
        <Card title="Upcoming Meetings" className="mt-8">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {meetings.slice(0, 6).map((meeting: Meeting) => (
              <Link
                key={meeting.id}
                to={`/meetings/${meeting.id}`}
                className="p-4 border border-gray-200 rounded-lg hover:border-blue-500 transition-colors"
              >
                <div className="font-medium text-gray-900">{meeting.name}</div>
                <div className="text-sm text-gray-600 mt-1">
                  {meeting.season} • {meeting.pool_required}
                </div>
              </Link>
            ))}
          </div>
          {meetings.length > 6 && (
            <Link to="/meetings" className="block text-center text-blue-600 hover:text-blue-700 font-medium mt-4">
              View All Meetings
            </Link>
          )}
        </Card>
      )}
    </div>
  );
};
