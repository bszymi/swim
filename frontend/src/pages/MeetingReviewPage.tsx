import { useParams, useNavigate } from 'react-router-dom';
import { Card } from '../components/common/Card';
import { Button } from '../components/common/Button';
import { Loading } from '../components/common/Loading';
import { useMeetingStatus, useConfirmMeeting } from '../hooks/useMeetings';
import { useQuery } from '@tanstack/react-query';
import { meetingsService } from '../services/meetings.service';

interface ParsedStandard {
  stroke: string;
  distance_m: number;
  course_type: string;
  age_group?: string;
  sex: string;
  qualifying_time: string;
}

export const MeetingReviewPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const parsedRecordId = parseInt(id || '0');

  const { data: statusData, isLoading: statusLoading } = useMeetingStatus(parsedRecordId, true);

  // Fetch the full review data when status is complete
  const { data: reviewData, isLoading: reviewLoading } = useQuery({
    queryKey: ['meeting-review', parsedRecordId],
    queryFn: () => meetingsService.review(parsedRecordId),
    enabled: statusData?.status === 'completed',
  });

  const confirmMeeting = useConfirmMeeting();
  const isLoading = statusLoading || reviewLoading;

  const handleConfirm = async () => {
    try {
      const result = await confirmMeeting.mutateAsync(parsedRecordId);
      navigate(`/meetings/${result.meeting.id}`);
    } catch (err) {
      console.error('Failed to confirm meeting:', err);
    }
  };

  const handleCancel = () => {
    navigate('/meetings');
  };

  if (isLoading) {
    return <Loading />;
  }

  if (statusData?.status === 'pending' || statusData?.status === 'processing') {
    return (
      <div className="max-w-4xl mx-auto">
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-gray-900">Processing Meeting</h1>
          <p className="mt-2 text-gray-600">
            Please wait while we extract the meeting details from your PDF...
          </p>
        </div>

        <Card>
          <div className="text-center py-12">
            <Loading />
            <p className="mt-4 text-gray-600">
              Parsing PDF with AI... This may take 30-60 seconds.
            </p>
          </div>
        </Card>
      </div>
    );
  }

  if (statusData?.status === 'failed') {
    return (
      <div className="max-w-4xl mx-auto">
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-gray-900">Processing Failed</h1>
        </div>

        <Card>
          <div className="p-4 bg-red-50 border border-red-200 rounded-md">
            <p className="text-red-700">
              Failed to parse the PDF: {statusData.error_message}
            </p>
          </div>
          <div className="mt-6 flex justify-end">
            <Button onClick={handleCancel}>Back to Meetings</Button>
          </div>
        </Card>
      </div>
    );
  }

  // Status is complete - show parsed data for review
  const parsedData = reviewData?.data;

  if (!parsedData) {
    return (
      <div className="max-w-4xl mx-auto">
        <Card>
          <p className="text-red-700">No parsed data available.</p>
          <div className="mt-6 flex justify-end">
            <Button onClick={handleCancel}>Back to Meetings</Button>
          </div>
        </Card>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900">Review Meeting Details</h1>
        <p className="mt-2 text-gray-600">
          Please review the extracted data and confirm if it looks correct
        </p>
      </div>

      <Card>
        <div className="space-y-6">
          <div>
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Meeting Information</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm font-medium text-gray-500">Name</p>
                <p className="text-gray-900">{parsedData.meet_name || 'N/A'}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-500">Season</p>
                <p className="text-gray-900">{parsedData.season || 'N/A'}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-500">Pool Type</p>
                <p className="text-gray-900">
                  {parsedData.pool_required === 'LC' ? 'Long Course (50m)' : 'Short Course (25m)'}
                </p>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-500">Qualification Window</p>
                <p className="text-gray-900">
                  {parsedData.window_start} to {parsedData.window_end}
                </p>
              </div>
              {parsedData.age_calculation && (
                <div>
                  <p className="text-sm font-medium text-gray-500">Age Rule Date</p>
                  <p className="text-gray-900">{parsedData.age_calculation.date}</p>
                </div>
              )}
            </div>
          </div>

          <div>
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              Qualification Standards ({parsedData.standards?.length || 0} found)
            </h3>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Event</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Age Group</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Gender</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Time</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {parsedData.standards?.slice(0, 10).map((standard: ParsedStandard, idx: number) => (
                    <tr key={idx}>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {standard.stroke} {standard.distance_m}m ({standard.course_type})
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {standard.age_group || 'Open'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {standard.sex}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {standard.qualifying_time}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              {parsedData.standards?.length > 10 && (
                <p className="text-sm text-gray-500 mt-2 text-center">
                  ... and {parsedData.standards.length - 10} more standards
                </p>
              )}
            </div>
          </div>
        </div>

        <div className="mt-6 flex gap-4 justify-end">
          <Button variant="secondary" onClick={handleCancel}>
            Cancel
          </Button>
          <Button onClick={handleConfirm} isLoading={confirmMeeting.isPending}>
            Confirm and Save
          </Button>
        </div>
      </Card>
    </div>
  );
};
