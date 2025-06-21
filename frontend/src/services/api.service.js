import { useAxiosPrivate } from '../hooks/useAxiosPrivate';
import { useAlertStore } from '../store/alert-store';
import { useSessionStore } from '../store/session-store';
import { useExceptionHandler } from '../hooks/useExceptionHandler';

/**
 * Centralized API service to reduce code duplication
 */
class ApiService {
  constructor() {
    this.axiosPrivate = null;
    this.sessionDetails = null;
    this.setAlertDetails = null;
    this.handleException = null;
  }

  /**
   * Initialize the service with necessary hooks
   * Call this in a React component or custom hook
   */
  initialize(axiosPrivate, sessionDetails, setAlertDetails, handleException) {
    this.axiosPrivate = axiosPrivate;
    this.sessionDetails = sessionDetails;
    this.setAlertDetails = setAlertDetails;
    this.handleException = handleException;
  }

  /**
   * Base request method with common configuration
   */
  async request(config) {
    const defaultHeaders = {
      'X-CSRFToken': this.sessionDetails?.csrfToken,
      'Content-Type': 'application/json',
    };

    const requestConfig = {
      ...config,
      headers: {
        ...defaultHeaders,
        ...config.headers,
      },
    };

    try {
      const response = await this.axiosPrivate(requestConfig);
      return response;
    } catch (error) {
      // Handle error based on configuration
      if (config.customErrorMessage) {
        this.setAlertDetails(this.handleException(error, config.customErrorMessage));
      } else if (config.silentError) {
        console.error('API Error:', error);
      } else {
        this.setAlertDetails(this.handleException(error));
      }
      throw error;
    }
  }

  /**
   * GET request
   */
  async get(url, config = {}) {
    return this.request({
      method: 'GET',
      url,
      ...config,
    });
  }

  /**
   * POST request
   */
  async post(url, data, config = {}) {
    return this.request({
      method: 'POST',
      url,
      data,
      ...config,
    });
  }

  /**
   * PUT request
   */
  async put(url, data, config = {}) {
    return this.request({
      method: 'PUT',
      url,
      data,
      ...config,
    });
  }

  /**
   * DELETE request
   */
  async delete(url, data, config = {}) {
    return this.request({
      method: 'DELETE',
      url,
      data,
      ...config,
    });
  }

  /**
   * Execute request with loading state management
   */
  async withLoading(request, setLoading) {
    try {
      setLoading(true);
      const response = await request();
      return response;
    } finally {
      setLoading(false);
    }
  }
}

/**
 * Custom hook to use the API service
 */
export function useApiService() {
  const axiosPrivate = useAxiosPrivate();
  const { sessionDetails } = useSessionStore();
  const { setAlertDetails } = useAlertStore();
  const handleException = useExceptionHandler();

  const apiService = new ApiService();
  apiService.initialize(axiosPrivate, sessionDetails, setAlertDetails, handleException);

  return apiService;
}

/**
 * Utility functions
 */
export const ApiUtils = {
  /**
   * Check if object is empty
   */
  isObjectEmpty: (obj) => {
    return !obj || Object.keys(obj).length === 0;
  },

  /**
   * Build API URL with organization ID
   */
  buildOrgUrl: (sessionDetails, path) => {
    return `/api/v1/unstract/${sessionDetails?.orgId}${path}`;
  },

  /**
   * Create form data for file uploads
   */
  createFormData: (data) => {
    const formData = new FormData();
    Object.entries(data).forEach(([key, value]) => {
      if (Array.isArray(value)) {
        value.forEach(item => formData.append(key, item));
      } else if (value !== undefined && value !== null) {
        formData.append(key, value);
      }
    });
    return formData;
  },
};