import { useState, useCallback } from "react";

/**
 * Custom hook for managing async operations with loading, error, and data states
 * Reduces code duplication for API calls
 */
export function useAsyncState(initialData = null) {
  const [data, setData] = useState(initialData);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  /**
   * Execute an async function with automatic state management
   */
  const execute = useCallback(async (asyncFunction) => {
    setLoading(true);
    setError(null);

    try {
      const result = await asyncFunction();
      setData(result);
      return result;
    } catch (err) {
      setError(err);
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  /**
   * Reset all states
   */
  const reset = useCallback(() => {
    setData(initialData);
    setLoading(false);
    setError(null);
  }, [initialData]);

  /**
   * Update data manually
   */
  const updateData = useCallback((newData) => {
    setData(newData);
  }, []);

  return {
    data,
    loading,
    error,
    execute,
    reset,
    updateData,
    setData,
    setLoading,
    setError,
  };
}

/**
 * Custom hook for managing multiple async states
 * Useful for components that make multiple API calls
 */
export function useMultipleAsyncStates(stateNames = []) {
  const states = {};

  stateNames.forEach((name) => {
    // eslint-disable-next-line react-hooks/rules-of-hooks
    const asyncState = useAsyncState();
    states[name] = asyncState;
  });

  return states;
}
