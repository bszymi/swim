import { useState } from 'react';
import { Button } from '../common/Button';

interface ReportErrorModalProps {
  meetingId: number;
  meetingName: string;
  onClose: () => void;
  onSubmit: (description: string) => Promise<void>;
}

export const ReportErrorModal: React.FC<ReportErrorModalProps> = ({
  meetingId,
  meetingName,
  onClose,
  onSubmit,
}) => {
  const [description, setDescription] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (description.trim().length < 10) {
      setError('Please provide at least 10 characters describing the error');
      return;
    }

    if (description.trim().length > 1000) {
      setError('Description must be less than 1000 characters');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      await onSubmit(description);
      onClose();
    } catch (err: any) {
      setError(err.response?.data?.errors?.join(', ') || 'Failed to submit error report');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full mx-4">
        <div className="p-6">
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Report Data Error</h2>
          <p className="text-sm text-gray-600 mb-4">
            Meeting: <span className="font-semibold">{meetingName}</span>
          </p>

          {error && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 rounded">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Please describe the error you found in the meeting data:
              </label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                rows={6}
                placeholder="Example: The qualifying time for 100m Freestyle for age 12 appears to be incorrect..."
                required
                minLength={10}
                maxLength={1000}
              />
              <p className="mt-1 text-sm text-gray-500">
                {description.length}/1000 characters (minimum 10)
              </p>
            </div>

            <div className="flex justify-end gap-3">
              <Button
                type="button"
                variant="secondary"
                onClick={onClose}
                disabled={isSubmitting}
              >
                Cancel
              </Button>
              <Button
                type="submit"
                disabled={isSubmitting || description.trim().length < 10}
              >
                {isSubmitting ? 'Submitting...' : 'Submit Report'}
              </Button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};
