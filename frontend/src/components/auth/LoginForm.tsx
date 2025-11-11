import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';
import { Input } from '../common/Input';
import { Button } from '../common/Button';
import { validateEmail } from '../../utils/validation';

export const LoginForm: React.FC = () => {
  const navigate = useNavigate();
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [errors, setErrors] = useState<{ email?: string; password?: string; general?: string }>({});
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrors({});

    // Validation
    const newErrors: { email?: string; password?: string } = {};
    if (!email) {
      newErrors.email = 'Email is required';
    } else if (!validateEmail(email)) {
      newErrors.email = 'Invalid email format';
    }
    if (!password) {
      newErrors.password = 'Password is required';
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    setLoading(true);
    try {
      await login({ email, password });
      navigate('/dashboard');
    } catch (error) {
      const axiosError = error as { response?: { data?: { error?: string } } };
      setErrors({ general: axiosError.response?.data?.error || 'Invalid email or password' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <Input
        type="email"
        label="Email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        error={errors.email}
        required
        autoComplete="email"
      />

      <Input
        type="password"
        label="Password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        error={errors.password}
        required
        autoComplete="current-password"
      />

      {errors.general && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {errors.general}
        </div>
      )}

      <Button type="submit" className="w-full" loading={loading}>
        Login
      </Button>

      <div className="text-center">
        <a
          href="/forgot-password"
          className="text-sm text-blue-600 hover:text-blue-700 font-medium"
        >
          Forgot your password?
        </a>
      </div>

      <p className="text-center text-sm text-gray-600">
        Don't have an account?{' '}
        <a href="/signup" className="text-blue-600 hover:text-blue-700 font-medium">
          Sign up
        </a>
      </p>
    </form>
  );
};
