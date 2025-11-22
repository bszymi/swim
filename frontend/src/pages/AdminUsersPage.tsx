import { useEffect, useState } from "react";
import { api } from "../services/api";
import { useNavigate } from "react-router-dom";

interface User {
  id: number;
  email: string;
  role: string;
  created_at: string;
  swimmers_count: number;
}

export default function AdminUsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    try {
      setLoading(true);
      const response = await api.get("/admin/users");
      setUsers(response.data);
      setError(null);
    } catch (err: any) {
      if (err.response?.status === 403) {
        setError("Unauthorized. Admin access required.");
        setTimeout(() => navigate("/dashboard"), 2000);
      } else {
        setError("Failed to load users");
      }
      console.error("Error loading users:", err);
    } finally {
      setLoading(false);
    }
  };

  const promoteUser = async (userId: number) => {
    if (!confirm("Are you sure you want to promote this user to admin?")) {
      return;
    }

    try {
      await api.post(`/admin/users/${userId}/promote`);
      await loadUsers();
    } catch (err) {
      console.error("Error promoting user:", err);
      alert("Failed to promote user");
    }
  };

  const demoteUser = async (userId: number) => {
    if (!confirm("Are you sure you want to demote this user to regular user?")) {
      return;
    }

    try {
      await api.post(`/admin/users/${userId}/demote`);
      await loadUsers();
    } catch (err: any) {
      if (err.response?.data?.error) {
        alert(err.response.data.error);
      } else {
        alert("Failed to demote user");
      }
      console.error("Error demoting user:", err);
    }
  };

  const deleteUser = async (userId: number, email: string) => {
    if (!confirm(`Are you sure you want to delete user ${email}? This action cannot be undone.`)) {
      return;
    }

    try {
      await api.delete(`/admin/users/${userId}`);
      await loadUsers();
    } catch (err: any) {
      if (err.response?.data?.error) {
        alert(err.response.data.error);
      } else {
        alert("Failed to delete user");
      }
      console.error("Error deleting user:", err);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString("en-GB", {
      day: "2-digit",
      month: "short",
      year: "numeric",
    });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-xl">Loading users...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-xl text-red-500">{error}</div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">User Management</h1>
        <button
          onClick={() => navigate("/dashboard")}
          className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
        >
          Back to Dashboard
        </button>
      </div>

      <div className="bg-white shadow-md rounded-lg overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Email
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Role
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Swimmers
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Joined
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {users.map((user) => (
              <tr key={user.id}>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm font-medium text-gray-900">{user.email}</div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span
                    className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                      user.role === "admin"
                        ? "bg-purple-100 text-purple-800"
                        : "bg-gray-100 text-gray-800"
                    }`}
                  >
                    {user.role}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {user.swimmers_count}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {formatDate(user.created_at)}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                  {user.role === "admin" ? (
                    <button
                      onClick={() => demoteUser(user.id)}
                      className="text-orange-600 hover:text-orange-900"
                    >
                      Demote
                    </button>
                  ) : (
                    <button
                      onClick={() => promoteUser(user.id)}
                      className="text-green-600 hover:text-green-900"
                    >
                      Promote
                    </button>
                  )}
                  <button
                    onClick={() => deleteUser(user.id, user.email)}
                    className="text-red-600 hover:text-red-900"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="mt-6 text-sm text-gray-600">
        Total users: {users.length} (Admins: {users.filter((u) => u.role === "admin").length})
      </div>
    </div>
  );
}
