import api from './api';
import type { Swimmer, Performance } from '../types/swimmer.types';

export const swimmersService = {
  async getAll(): Promise<Swimmer[]> {
    const response = await api.get('/swimmers');
    return response.data;
  },

  async getById(seId: string): Promise<{ swimmer: Swimmer; lc_performances: Performance[]; sc_performances: Performance[] }> {
    const response = await api.get(`/swimmers/${seId}`);
    return response.data;
  },

  async create(swimmer: Partial<Swimmer>): Promise<Swimmer> {
    const response = await api.post('/swimmers', { swimmer });
    return response.data;
  },

  async update(seId: string, swimmer: Partial<Swimmer>): Promise<Swimmer> {
    const response = await api.patch(`/swimmers/${seId}`, { swimmer });
    return response.data;
  },

  async delete(seId: string): Promise<{ message: string }> {
    const response = await api.delete(`/swimmers/${seId}`);
    return response.data;
  }
};
