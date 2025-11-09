import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { performancesService } from '../services/performances.service';

export const useImportPerformances = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ swimmerId, historic }: { swimmerId: number; historic: boolean }) =>
      performancesService.import(swimmerId, historic),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['swimmer', variables.swimmerId] });
      queryClient.invalidateQueries({ queryKey: ['swimmers'] });
    },
  });
};

export const usePerformanceHistory = (
  seId: string,
  stroke: string,
  distanceM: number,
  courseType: string,
  enabled: boolean = true
) => {
  return useQuery({
    queryKey: ['performance-history', seId, stroke, distanceM, courseType],
    queryFn: () => performancesService.getHistory(seId, stroke, distanceM, courseType),
    enabled: enabled && !!seId && !!stroke && !!distanceM && !!courseType,
  });
};
