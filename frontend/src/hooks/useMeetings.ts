import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { meetingsService } from '../services/meetings.service';

export const useMeetings = () => {
  return useQuery({
    queryKey: ['meetings'],
    queryFn: meetingsService.getAll,
  });
};

export const useMeeting = (id: number) => {
  return useQuery({
    queryKey: ['meeting', id],
    queryFn: () => meetingsService.getById(id),
    enabled: !!id,
  });
};

export const useUploadMeeting = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (file: File) => meetingsService.uploadPDF(file),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['meetings'] });
    },
  });
};

export const useMeetingStatus = (id: number, enabled: boolean = true) => {
  return useQuery({
    queryKey: ['meeting-status', id],
    queryFn: () => meetingsService.getStatus(id),
    enabled: enabled && !!id,
    refetchInterval: (query) => {
      // Poll every 3 seconds if status is pending or processing
      const data = query.state.data as { status?: string } | undefined;
      if (data?.status === 'pending' || data?.status === 'processing') {
        return 3000;
      }
      return false;
    },
  });
};

export const useConfirmMeeting = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) => meetingsService.confirm(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['meetings'] });
    },
  });
};

export const useDeleteMeeting = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: number) => meetingsService.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['meetings'] });
    },
  });
};

export const useMeetingComparison = (id: number, swimmerIds?: number[]) => {
  return useQuery({
    queryKey: ['meeting-comparison', id, swimmerIds],
    queryFn: () => meetingsService.compare(id, swimmerIds),
    enabled: !!id,
  });
};
