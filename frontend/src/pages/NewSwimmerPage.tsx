import { useNavigate } from 'react-router-dom';
import { Card } from '../components/common/Card';
import { SwimmerForm } from '../components/swimmers/SwimmerForm';
import { useCreateSwimmer } from '../hooks/useSwimmers';
import { useImportPerformances } from '../hooks/usePerformances';
import type { Swimmer } from '../types/swimmer.types';
import { useState } from 'react';

export const NewSwimmerPage: React.FC = () => {
  const navigate = useNavigate();
  const createSwimmer = useCreateSwimmer();
  const importPerformances = useImportPerformances();
  const [importingData, setImportingData] = useState(false);

  const handleSubmit = async (data: Partial<Swimmer>) => {
    try {
      const newSwimmer = await createSwimmer.mutateAsync(data);

      // If swimmer has SE membership ID, automatically import performances
      if (newSwimmer.se_membership_id && newSwimmer.id) {
        setImportingData(true);
        try {
          // First import PBs (quick)
          await importPerformances.mutateAsync({
            swimmerId: newSwimmer.id,
            historic: false
          });

          // Then import historic data (slow, but in background)
          await importPerformances.mutateAsync({
            swimmerId: newSwimmer.id,
            historic: true
          });
        } catch (importError) {
          console.error('Failed to import performances:', importError);
          // Continue anyway and navigate to the swimmer page
        }
      }

      // Navigate to the swimmer's detail page
      navigate(`/swimmers/${newSwimmer.se_membership_id}`);
    } catch (error) {
      console.error('Failed to create swimmer:', error);
    }
  };

  const handleCancel = () => {
    navigate('/swimmers');
  };

  return (
    <div className="max-w-4xl mx-auto">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900">Add New Swimmer</h1>
        <p className="mt-2 text-gray-600">
          Create a new swimmer profile to track their performances and progress.
        </p>
      </div>

      {importingData && (
        <div className="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-md">
          <p className="text-blue-700 font-medium mb-1">
            Importing performance data from Swimming England...
          </p>
          <p className="text-sm text-blue-600">
            This will take a few minutes. You'll be redirected when complete.
          </p>
        </div>
      )}

      <Card>
        <SwimmerForm
          onSubmit={handleSubmit}
          onCancel={handleCancel}
          isLoading={createSwimmer.isPending || importingData}
        />
      </Card>

      {createSwimmer.isError && (
        <div className="mt-4 p-4 bg-red-50 border border-red-200 rounded-md">
          <p className="text-red-700">
            Failed to create swimmer. Please try again.
          </p>
        </div>
      )}
    </div>
  );
};
