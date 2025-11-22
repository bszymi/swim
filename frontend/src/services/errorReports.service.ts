import { api } from './api';

export type ErrorReport = {
  id: number;
  meeting_id: number;
  meeting_name: string;
  user_email: string;
  description: string;
  status: 'pending' | 'resolved';
  created_at: string;
  updated_at: string;
};

export const errorReportsService = {
  getAll: async (status?: string) => {
    const params = status ? { status } : {};
    const response = await api.get('/meeting_error_reports', { params });
    return response.data as ErrorReport[];
  },

  create: async (meetingId: number, description: string) => {
    const response = await api.post('/meeting_error_reports', {
      meeting_id: meetingId,
      description,
    });
    return response.data;
  },

  updateStatus: async (id: number, status: 'pending' | 'resolved') => {
    const response = await api.put(`/meeting_error_reports/${id}`, { status });
    return response.data;
  },
};
