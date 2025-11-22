import { useParams, useNavigate, Link } from 'react-router-dom';
import { Button } from '../components/common/Button';
import { Card } from '../components/common/Card';
import { Loading } from '../components/common/Loading';
import { useSwimmer, useDeleteSwimmer } from '../hooks/useSwimmers';
import { useImportPerformances } from '../hooks/usePerformances';
import { formatDate, calculateAge } from '../utils/date.utils';
import { formatTime } from '../utils/time.utils';
import type { Performance } from '../types/swimmer.types';
import { useState, useEffect } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import { performancesService } from '../services/performances.service';
import { swimmersService } from '../services/swimmers.service';
import { useQuery } from '@tanstack/react-query';

export const SwimmerDetailPage: React.FC = () => {
  const { se_id } = useParams<{ se_id: string }>();
  const navigate = useNavigate();

  const { data, isLoading, error } = useSwimmer(se_id || '');
  const deleteSwimmer = useDeleteSwimmer();
  const importPerformances = useImportPerformances();

  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [showQualifications, setShowQualifications] = useState(false);
  const [selectedEvent, setSelectedEvent] = useState<{
    stroke: string;
    distance_m: number;
    course_type: string;
  } | null>(null);

  // Fetch future qualifications
  const { data: qualificationsData, isLoading: qualificationsLoading } = useQuery({
    queryKey: ['future-qualifications', se_id],
    queryFn: () => swimmersService.getFutureQualifications(se_id || ''),
    enabled: showQualifications && !!se_id,
  });

  // Handle ESC key to close modal
  useEffect(() => {
    const handleEscKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        if (selectedEvent) {
          setSelectedEvent(null);
        } else if (showDeleteConfirm) {
          setShowDeleteConfirm(false);
        }
      }
    };

    document.addEventListener('keydown', handleEscKey);
    return () => {
      document.removeEventListener('keydown', handleEscKey);
    };
  }, [selectedEvent, showDeleteConfirm]);

  const { data: historyData, isLoading: historyLoading } = useQuery({
    queryKey: ['performance-history', se_id, selectedEvent?.stroke, selectedEvent?.distance_m, selectedEvent?.course_type],
    queryFn: () => performancesService.getHistory(
      se_id || '',
      selectedEvent!.stroke,
      selectedEvent!.distance_m,
      selectedEvent!.course_type
    ),
    enabled: !!selectedEvent && !!se_id,
  });

  if (isLoading) {
    return <Loading />;
  }

  if (error || !data) {
    return (
      <div className="p-4 bg-red-50 border border-red-200 rounded-md">
        <p className="text-red-700">Failed to load swimmer details. Please try again.</p>
      </div>
    );
  }

  const { swimmer, lc_performances, sc_performances } = data;

  const handleDelete = async () => {
    try {
      await deleteSwimmer.mutateAsync(se_id || '');
      navigate('/swimmers');
    } catch (err) {
      console.error('Failed to delete swimmer:', err);
    }
  };

  const handleImportSwimmingData = async () => {
    if (!swimmer.id) return;
    try {
      // Import PBs first (quick)
      await importPerformances.mutateAsync({ swimmerId: swimmer.id, historic: false });

      // Then import historic data (slow, in background)
      await importPerformances.mutateAsync({ swimmerId: swimmer.id, historic: true });
    } catch (err) {
      console.error('Failed to import performances:', err);
    }
  };

  const renderPerformanceTable = (performances: Performance[], title: string, courseType: string) => {
    if (!performances || performances.length === 0) {
      return (
        <Card>
          <h3 className="text-lg font-semibold text-gray-900 mb-4">{title}</h3>
          <p className="text-gray-500 text-center py-8">No performances recorded</p>
        </Card>
      );
    }

    // Group by stroke and distance
    const grouped = performances.reduce((acc, perf) => {
      const key = `${perf.stroke}-${perf.distance_m}`;
      if (!acc[key]) {
        acc[key] = [];
      }
      acc[key].push(perf);
      return acc;
    }, {} as Record<string, Performance[]>);

    // Sort each group by time (fastest first)
    Object.keys(grouped).forEach(key => {
      grouped[key].sort((a, b) => a.time_seconds - b.time_seconds);
    });

    return (
      <Card>
        <h3 className="text-lg font-semibold text-gray-900 mb-4">{title}</h3>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Event
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Time
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Date
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Meet
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {Object.entries(grouped).map(([, perfs]) => (
                perfs.map((perf, idx) => (
                  <tr
                    key={perf.id}
                    className={`${idx === 0 ? 'bg-blue-50 cursor-pointer hover:bg-blue-100' : ''}`}
                    onClick={() => {
                      if (idx === 0) {
                        setSelectedEvent({
                          stroke: perf.stroke,
                          distance_m: perf.distance_m,
                          course_type: courseType
                        });
                      }
                    }}
                  >
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {perf.stroke} {perf.distance_m}m
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {formatTime(perf.time_seconds)}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {formatDate(perf.date)}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {perf.meet_name}
                    </td>
                  </tr>
                ))
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    );
  };

  return (
    <div>
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center gap-4 mb-4">
          <Link to="/swimmers">
            <Button variant="ghost" size="sm">
              ← Back to Swimmers
            </Button>
          </Link>
        </div>

        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900">
              {swimmer.first_name} {swimmer.last_name}
            </h1>
            <div className="mt-2 flex flex-wrap gap-4 text-sm text-gray-600">
              <span>Age: {calculateAge(swimmer.dob)} years</span>
              <span>•</span>
              <span>Sex: {swimmer.sex === 'M' ? 'Male' : 'Female'}</span>
              <span>•</span>
              <span>Club: {swimmer.club}</span>
              {swimmer.se_membership_id && (
                <>
                  <span>•</span>
                  <span>SE ID: {swimmer.se_membership_id}</span>
                </>
              )}
            </div>
          </div>

          <div className="flex gap-2">
            <Button
              onClick={() => setShowQualifications(!showQualifications)}
              variant="secondary"
            >
              {showQualifications ? 'Hide' : 'View'} Future Qualifications
            </Button>
            <Button
              onClick={handleImportSwimmingData}
              isLoading={importPerformances.isPending}
              disabled={importPerformances.isPending}
              variant="secondary"
            >
              Import Swimming Data
            </Button>
            <Button
              variant="danger"
              onClick={() => setShowDeleteConfirm(true)}
            >
              Delete
            </Button>
          </div>
        </div>
      </div>

      {/* Import Information */}
      {importPerformances.isPending && (
        <div className="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-md">
          <p className="text-blue-700 font-medium mb-1">
            Importing performances from Swimming England...
          </p>
          <p className="text-sm text-blue-600">
            This may take a few moments. Historic imports can take several minutes due to rate limiting.
          </p>
        </div>
      )}

      {/* Import Success Message */}
      {importPerformances.isSuccess && (
        <div className="mb-6 p-4 bg-green-50 border border-green-200 rounded-md">
          <p className="text-green-700">
            Successfully imported performances from Swimming England
          </p>
        </div>
      )}

      {/* Import Error Message */}
      {importPerformances.isError && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-md">
          <p className="text-red-700">
            Failed to import performances. Please try again.
          </p>
        </div>
      )}

      {/* Future Qualifications */}
      {showQualifications && (
        <Card className="mb-6">
          <h2 className="text-xl font-bold text-gray-900 mb-4">Future Qualifications</h2>
          {qualificationsLoading && <Loading text="Loading qualifications..." />}
          {qualificationsData && (
            <>
              {qualificationsData.total_meetings === 0 ? (
                <p className="text-gray-500 text-center py-8">
                  No future meeting qualifications found
                </p>
              ) : (
                <div className="space-y-6">
                  <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                    <p className="text-blue-900 font-semibold">
                      Qualified for {qualificationsData.total_events} events across {qualificationsData.total_meetings} meetings
                    </p>
                  </div>

                  {qualificationsData.qualifications.map((qual: {
                    meeting_id: number;
                    meeting_name: string;
                    season: string;
                    pool_required: string;
                    window_start: string;
                    window_end: string;
                    qualified_events: Array<{
                      stroke: string;
                      distance_m: number;
                      course_type: string;
                      swimmer_time_formatted: string;
                      qualifying_time_formatted: string;
                      time_difference: number;
                      converted: boolean;
                    }>;
                    total_events: number;
                  }) => (
                    <div key={qual.meeting_id} className="border border-gray-200 rounded-lg p-4">
                      <div className="mb-4">
                        <Link
                          to={`/meetings/${qual.meeting_id}`}
                          className="text-lg font-semibold text-blue-600 hover:text-blue-700"
                        >
                          {qual.meeting_name}
                        </Link>
                        <p className="text-sm text-gray-600 mt-1">
                          {qual.season} • {qual.pool_required} • {qual.total_events} qualifying events
                        </p>
                        <p className="text-sm text-gray-500">
                          Window: {new Date(qual.window_start).toLocaleDateString()} - {new Date(qual.window_end).toLocaleDateString()}
                        </p>
                      </div>

                      <div className="overflow-x-auto">
                        <table className="min-w-full divide-y divide-gray-200">
                          <thead className="bg-gray-50">
                            <tr>
                              <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Event</th>
                              <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Your Time</th>
                              <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Qualifying Time</th>
                              <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">Margin</th>
                            </tr>
                          </thead>
                          <tbody className="bg-white divide-y divide-gray-200">
                            {qual.qualified_events.map((event, idx) => (
                              <tr key={idx} className="hover:bg-gray-50">
                                <td className="px-4 py-3 whitespace-nowrap text-sm font-medium text-gray-900">
                                  {event.distance_m}m {event.stroke} ({event.course_type})
                                  {event.converted && (
                                    <span className="ml-2 text-xs text-blue-600">(converted)</span>
                                  )}
                                </td>
                                <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-700 font-semibold">
                                  {event.swimmer_time_formatted}
                                </td>
                                <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-600">
                                  {event.qualifying_time_formatted}
                                </td>
                                <td className="px-4 py-3 whitespace-nowrap text-sm">
                                  <span className={event.time_difference < 0 ? 'text-green-600 font-semibold' : 'text-gray-600'}>
                                    {event.time_difference < 0 ? '-' : '+'}{Math.abs(event.time_difference).toFixed(2)}s
                                  </span>
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </>
          )}
        </Card>
      )}

      {/* Statistics */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
        <Card>
          <div className="text-center">
            <p className="text-2xl font-bold text-blue-600">
              {lc_performances?.length || 0}
            </p>
            <p className="text-sm text-gray-600 mt-1">Long Course PBs</p>
          </div>
        </Card>
        <Card>
          <div className="text-center">
            <p className="text-2xl font-bold text-purple-600">
              {sc_performances?.length || 0}
            </p>
            <p className="text-sm text-gray-600 mt-1">Short Course PBs</p>
          </div>
        </Card>
        <Card>
          <div className="text-center">
            <p className="text-2xl font-bold text-green-600">
              {(lc_performances?.length || 0) + (sc_performances?.length || 0)}
            </p>
            <p className="text-sm text-gray-600 mt-1">Total PBs</p>
          </div>
        </Card>
      </div>

      {/* Performance Tables */}
      <div className="space-y-6">
        {renderPerformanceTable(lc_performances, 'Long Course (50m) Personal Bests', 'LC')}
        {renderPerformanceTable(sc_performances, 'Short Course (25m) Personal Bests', 'SC')}
      </div>

      {/* Performance History Modal */}
      {selectedEvent && (
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50 p-4">
          <Card className="max-w-4xl w-full max-h-[90vh] overflow-auto mx-4">
            <div className="flex justify-between items-start mb-4">
              <div>
                <h3 className="text-xl font-semibold text-gray-900">
                  {selectedEvent.stroke} {selectedEvent.distance_m}m ({selectedEvent.course_type})
                </h3>
                <p className="text-sm text-gray-600 mt-1">Performance History</p>
              </div>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setSelectedEvent(null)}
              >
                ✕
              </Button>
            </div>

            {historyLoading ? (
              <Loading />
            ) : historyData?.performances && historyData.performances.length > 0 ? (
              <>
                {/* Performance Graph */}
                <div className="mb-6">
                  <ResponsiveContainer width="100%" height={300}>
                    <LineChart
                      data={[...historyData.performances]
                        .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
                        .map((perf: Performance) => ({
                          date: new Date(perf.date).getTime(),
                          dateFormatted: formatDate(perf.date),
                          time: perf.time_seconds,
                          isPB: perf.id === historyData.personal_best?.id,
                          meet: perf.meet_name
                        }))}
                      margin={{ top: 5, right: 30, left: 20, bottom: 80 }}
                    >
                      <CartesianGrid strokeDasharray="3 3" stroke="rgba(0,0,0,0.1)" />
                      <XAxis
                        dataKey="date"
                        type="number"
                        domain={['dataMin', 'dataMax']}
                        scale="time"
                        tickFormatter={(timestamp) => new Date(timestamp).toLocaleDateString('en-GB')}
                        angle={-45}
                        textAnchor="end"
                        height={80}
                      />
                      <YAxis
                        domain={['auto', 'auto']}
                        label={{ value: 'TIME (slower ↑)', angle: -90, position: 'insideLeft' }}
                        tickFormatter={(value) => {
                          const mins = Math.floor(value / 60);
                          const secs = (value % 60).toFixed(2);
                          return mins > 0 ? `${mins}:${secs.padStart(5, '0')}` : `${secs}s`;
                        }}
                      />
                      <Tooltip
                        labelFormatter={(timestamp) => new Date(timestamp).toLocaleDateString('en-GB')}
                        formatter={(value: number, _name: string, props: { payload?: { isPB?: boolean } }) => [
                          formatTime(value),
                          props.payload?.isPB ? 'Time (PB!)' : 'Time'
                        ]}
                        contentStyle={{ backgroundColor: 'rgba(0,0,0,0.8)', border: 'none', borderRadius: '8px', color: '#fff' }}
                      />
                      <Legend />
                      <Line
                        type="monotone"
                        dataKey="time"
                        stroke="#3b82f6"
                        strokeWidth={3}
                        dot={(props: { cx?: number; cy?: number; payload?: { isPB?: boolean } }) => {
                          const { cx, cy, payload } = props;
                          if (cx === undefined || cy === undefined) return null;
                          return (
                            <circle
                              cx={cx}
                              cy={cy}
                              r={payload?.isPB ? 8 : 5}
                              fill={payload?.isPB ? '#eab308' : '#3b82f6'}
                              stroke={payload?.isPB ? '#ca8a04' : '#2563eb'}
                              strokeWidth={2}
                            />
                          );
                        }}
                        activeDot={{ r: 8 }}
                        name="Swim Time"
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </div>

                {/* Performance Table */}
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Time
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Date
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Meet
                      </th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {historyData.performances.map((perf: Performance) => (
                      <tr
                        key={perf.id}
                        className={perf.id === historyData.personal_best?.id ? 'bg-blue-50' : ''}
                      >
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                          {formatTime(perf.time_seconds)}
                          {perf.id === historyData.personal_best?.id && (
                            <span className="ml-2 text-xs font-semibold text-blue-600">PB</span>
                          )}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {formatDate(perf.date)}
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-500">
                          {perf.meet_name}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              </>
            ) : (
              <p className="text-gray-500 text-center py-8">No historic performances found</p>
            )}
          </Card>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50">
          <Card className="max-w-md mx-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              Delete Swimmer
            </h3>
            <p className="text-gray-600 mb-6">
              Are you sure you want to delete {swimmer.first_name} {swimmer.last_name}?
              This will permanently delete all their performance data. This action cannot be undone.
            </p>
            <div className="flex gap-4 justify-end">
              <Button
                variant="secondary"
                onClick={() => setShowDeleteConfirm(false)}
              >
                Cancel
              </Button>
              <Button
                variant="danger"
                onClick={handleDelete}
                isLoading={deleteSwimmer.isPending}
              >
                Delete Swimmer
              </Button>
            </div>
          </Card>
        </div>
      )}
    </div>
  );
};
