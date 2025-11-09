import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Card } from '../components/common/Card';
import { Button } from '../components/common/Button';
import { Loading } from '../components/common/Loading';
import { meetingsService } from '../services/meetings.service';

interface EventStandard {
  stroke: string;
  distance: number;
  course: string;
  times_by_age: Record<string, { qualifying_time?: string }>;
}

interface GenderData {
  ages: string[];
  events: EventStandard[];
}

export const MeetingDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const meetingId = parseInt(id || '0');

  const { data, isLoading, error } = useQuery({
    queryKey: ['meeting', meetingId],
    queryFn: () => meetingsService.getById(meetingId),
  });

  if (isLoading) {
    return <Loading />;
  }

  if (error || !data) {
    return (
      <div className="max-w-7xl mx-auto">
        <Card>
          <p className="text-red-700">Failed to load meeting details.</p>
          <div className="mt-6">
            <Button onClick={() => navigate('/meetings')}>Back to Meetings</Button>
          </div>
        </Card>
      </div>
    );
  }

  const { meeting, standards_matrix } = data;

  return (
    <div className="max-w-7xl mx-auto">
      <div className="mb-6 flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">{meeting.name}</h1>
          <p className="mt-2 text-gray-600">
            {meeting.season} • {meeting.pool_required === 'LC' ? 'Long Course (50m)' : 'Short Course (25m)'}
          </p>
        </div>
        <Button variant="secondary" onClick={() => navigate('/meetings')}>
          Back to Meetings
        </Button>
      </div>

      {meeting.window_start && meeting.window_end && (
        <Card className="mb-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Qualification Window</h2>
          <p className="text-gray-700">
            {new Date(meeting.window_start).toLocaleDateString()} to {new Date(meeting.window_end).toLocaleDateString()}
          </p>
        </Card>
      )}

      <Card>
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Qualification Standards</h2>

        {Object.entries(standards_matrix).map(([gender, genderData]: [string, GenderData]) => (
          <div key={gender} className="mb-8">
            <h3 className="text-md font-semibold text-gray-800 mb-3">
              {gender === 'M' ? 'Male' : 'Female'}
            </h3>

            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Event</th>
                    {genderData.ages.map((age: string) => (
                      <th key={age} className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase">
                        {age}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {genderData.events.map((event: EventStandard, idx: number) => (
                    <tr key={idx}>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        {event.distance}m {event.stroke} ({event.course})
                      </td>
                      {genderData.ages.map((age: string) => {
                        const standard = event.times_by_age[age];
                        return (
                          <td key={age} className="px-6 py-4 whitespace-nowrap text-sm text-gray-700 text-center">
                            {standard?.qualifying_time || '-'}
                          </td>
                        );
                      })}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        ))}
      </Card>
    </div>
  );
};
