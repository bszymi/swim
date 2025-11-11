import api from './api';
import type { User, LoginCredentials, SignupCredentials, AuthResponse } from '../types/auth.types';

export const authService = {
  async signup(credentials: SignupCredentials): Promise<AuthResponse> {
    const response = await api.post('/signup', { user: credentials });
    if (response.data.token) {
      localStorage.setItem('auth_token', response.data.token);
    }
    return response.data;
  },

  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    const response = await api.post('/login', { user: credentials });
    if (response.data.token) {
      localStorage.setItem('auth_token', response.data.token);
    }
    return response.data;
  },

  async logout(): Promise<void> {
    await api.delete('/logout');
    localStorage.removeItem('auth_token');
  },

  async getCurrentUser(): Promise<User> {
    const response = await api.get('/me');
    return response.data.user;
  },

  getToken(): string | null {
    return localStorage.getItem('auth_token');
  },

  isAuthenticated(): boolean {
    return !!this.getToken();
  },

  async requestPasswordReset(email: string): Promise<{ message: string }> {
    const response = await api.post('/password_resets', { email });
    return response.data;
  },

  async resetPassword(token: string, password: string): Promise<{ message: string }> {
    const response = await api.put(`/password_resets/${token}`, { password });
    return response.data;
  }
};
