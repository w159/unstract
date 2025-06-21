/**
 * Centralized error handling utilities
 */

/**
 * Error types enum
 */
export const ErrorTypes = {
  NETWORK: 'NETWORK_ERROR',
  VALIDATION: 'VALIDATION_ERROR',
  AUTHENTICATION: 'AUTHENTICATION_ERROR',
  AUTHORIZATION: 'AUTHORIZATION_ERROR',
  NOT_FOUND: 'NOT_FOUND_ERROR',
  SERVER: 'SERVER_ERROR',
  UNKNOWN: 'UNKNOWN_ERROR',
};

/**
 * Determine error type from error object
 * @param {Error} error - Error object
 * @returns {string} - Error type
 */
export const getErrorType = (error) => {
  if (!error.response) {
    return ErrorTypes.NETWORK;
  }

  const status = error.response?.status;
  switch (status) {
    case 400:
      return ErrorTypes.VALIDATION;
    case 401:
      return ErrorTypes.AUTHENTICATION;
    case 403:
      return ErrorTypes.AUTHORIZATION;
    case 404:
      return ErrorTypes.NOT_FOUND;
    case 500:
    case 502:
    case 503:
      return ErrorTypes.SERVER;
    default:
      return ErrorTypes.UNKNOWN;
  }
};

/**
 * Extract user-friendly error message
 * @param {Error} error - Error object
 * @param {string} defaultMessage - Default message if none found
 * @returns {string} - Error message
 */
export const getErrorMessage = (error, defaultMessage = 'An error occurred') => {
  // Check for network errors
  if (!error.response) {
    if (error.message === 'Network Error') {
      return 'Unable to connect to server. Please check your internet connection.';
    }
    return error.message || defaultMessage;
  }

  // Check for response data errors
  const responseData = error.response?.data;
  
  // Handle different error response formats
  if (typeof responseData === 'string') {
    return responseData;
  }

  if (responseData?.message) {
    return responseData.message;
  }

  if (responseData?.error) {
    return responseData.error;
  }

  if (responseData?.errors) {
    if (Array.isArray(responseData.errors)) {
      return responseData.errors.map(e => e.detail || e.message).join(', ');
    }
    if (typeof responseData.errors === 'object') {
      return Object.values(responseData.errors).flat().join(', ');
    }
  }

  if (responseData?.detail) {
    return responseData.detail;
  }

  // Status-based messages
  const status = error.response?.status;
  switch (status) {
    case 400:
      return 'Invalid request. Please check your input.';
    case 401:
      return 'You need to log in to access this resource.';
    case 403:
      return 'You do not have permission to perform this action.';
    case 404:
      return 'The requested resource was not found.';
    case 500:
      return 'Server error. Please try again later.';
    default:
      return defaultMessage;
  }
};

/**
 * Create standardized error object
 * @param {Error} error - Original error
 * @param {string} customMessage - Custom error message
 * @returns {Object} - Standardized error object
 */
export const createErrorObject = (error, customMessage) => {
  return {
    type: getErrorType(error),
    message: customMessage || getErrorMessage(error),
    originalError: error,
    timestamp: new Date().toISOString(),
    statusCode: error.response?.status,
  };
};

/**
 * Log error with context
 * @param {Error} error - Error to log
 * @param {string} context - Context where error occurred
 * @param {Object} additionalInfo - Additional information
 */
export const logError = (error, context, additionalInfo = {}) => {
  const errorInfo = {
    context,
    message: error.message,
    stack: error.stack,
    ...additionalInfo,
  };

  if (error.response) {
    errorInfo.response = {
      status: error.response.status,
      data: error.response.data,
      headers: error.response.headers,
    };
  }

  console.error(`[${context}] Error:`, errorInfo);
};

/**
 * Handle API error with alert
 * @param {Error} error - Error object
 * @param {Function} setAlertDetails - Alert setter function
 * @param {string} customMessage - Custom error message
 */
export const handleApiError = (error, setAlertDetails, customMessage) => {
  const errorObj = createErrorObject(error, customMessage);
  
  setAlertDetails({
    type: 'error',
    content: errorObj.message,
  });

  logError(error, 'API_ERROR', { customMessage });
  
  return errorObj;
};

/**
 * Retry handler for transient errors
 * @param {Error} error - Error to check
 * @returns {boolean} - Whether error is retryable
 */
export const isRetryableError = (error) => {
  const retryableStatuses = [408, 429, 500, 502, 503, 504];
  return !error.response || retryableStatuses.includes(error.response?.status);
};

/**
 * Create error boundary fallback component props
 * @param {Error} error - Error that occurred
 * @param {Function} resetErrorBoundary - Function to reset error boundary
 * @returns {Object} - Props for error fallback component
 */
export const createErrorFallbackProps = (error, resetErrorBoundary) => {
  return {
    error: createErrorObject(error),
    resetErrorBoundary,
    showDetails: process.env.NODE_ENV === 'development',
  };
};