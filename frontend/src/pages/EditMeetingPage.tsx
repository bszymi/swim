import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";
import { api } from "../services/api";

interface Meeting {
  id: number;
  name: string;
  season: string;
  pool_required: string;
  window_start: string;
  window_end: string;
  age_rule_type: string;
  age_rule_date: string;
  promoter: string;
  region: string;
  notes: string;
  source_pdf_url: string;
  license_number: string;
}

export default function EditMeetingPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [meeting, setMeeting] = useState<Meeting | null>(null);

  useEffect(() => {
    if (!user?.is_admin) {
      navigate("/meetings");
      return;
    }

    loadMeeting();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id, user, navigate]);

  const loadMeeting = async () => {
    try {
      setLoading(true);
      const response = await api.get(`/meetings/${id}`);
      setMeeting(response.data.meeting);
      setError(null);
    } catch (err) {
      setError("Failed to load meeting");
      console.error("Error loading meeting:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!meeting) return;

    try {
      setSaving(true);
      await api.put(`/meetings/${id}`, { meeting });
      navigate(`/meetings/${id}`);
    } catch (err) {
      const error = err as { response?: { data?: { errors?: string[] } } };
      setError(error.response?.data?.errors?.join(", ") || "Failed to update meeting");
      console.error("Error updating meeting:", err);
    } finally {
      setSaving(false);
    }
  };

  const handleChange = (field: keyof Meeting, value: string) => {
    if (!meeting) return;
    setMeeting({ ...meeting, [field]: value });
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-xl">Loading meeting...</div>
      </div>
    );
  }

  if (error && !meeting) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-xl text-red-500">{error}</div>
      </div>
    );
  }

  if (!meeting) return null;

  return (
    <div className="container mx-auto px-4 py-8 max-w-4xl">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">Edit Meeting</h1>
        <button
          onClick={() => navigate(`/meetings/${id}`)}
          className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
        >
          Cancel
        </button>
      </div>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 text-red-700 rounded">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="bg-white shadow-md rounded-lg p-6 space-y-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Meeting Name *
          </label>
          <input
            type="text"
            value={meeting.name || ""}
            onChange={(e) => handleChange("name", e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            required
          />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Season
            </label>
            <input
              type="text"
              value={meeting.season || ""}
              onChange={(e) => handleChange("season", e.target.value)}
              placeholder="e.g., 2024-2025"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Pool Required
            </label>
            <select
              value={meeting.pool_required || ""}
              onChange={(e) => handleChange("pool_required", e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Select pool type</option>
              <option value="LC">Long Course (50m)</option>
              <option value="SC">Short Course (25m)</option>
            </select>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Window Start
            </label>
            <input
              type="date"
              value={meeting.window_start || ""}
              onChange={(e) => handleChange("window_start", e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Window End
            </label>
            <input
              type="date"
              value={meeting.window_end || ""}
              onChange={(e) => handleChange("window_end", e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Age Rule Type
            </label>
            <input
              type="text"
              value={meeting.age_rule_type || ""}
              onChange={(e) => handleChange("age_rule_type", e.target.value)}
              placeholder="e.g., calendar_year"
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Age Rule Date
            </label>
            <input
              type="date"
              value={meeting.age_rule_date || ""}
              onChange={(e) => handleChange("age_rule_date", e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Promoter
            </label>
            <input
              type="text"
              value={meeting.promoter || ""}
              onChange={(e) => handleChange("promoter", e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Region
            </label>
            <input
              type="text"
              value={meeting.region || ""}
              onChange={(e) => handleChange("region", e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            License Number
          </label>
          <input
            type="text"
            value={meeting.license_number || ""}
            onChange={(e) => handleChange("license_number", e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Source PDF URL
          </label>
          <input
            type="url"
            value={meeting.source_pdf_url || ""}
            onChange={(e) => handleChange("source_pdf_url", e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Notes
          </label>
          <textarea
            value={meeting.notes || ""}
            onChange={(e) => handleChange("notes", e.target.value)}
            rows={4}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        <div className="flex justify-end space-x-4">
          <button
            type="button"
            onClick={() => navigate(`/meetings/${id}`)}
            className="px-6 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={saving}
            className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-blue-300"
          >
            {saving ? "Saving..." : "Save Changes"}
          </button>
        </div>
      </form>
    </div>
  );
}
