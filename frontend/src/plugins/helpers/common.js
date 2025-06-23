// Stub implementation for common helpers
export const formatDate = (date) => {
  return date;
};

export const parseJSON = (jsonString) => {
  try {
    return JSON.parse(jsonString);
  } catch {
    return null;
  }
};

export const debounce = (func, wait) => {
  return func;
};

export const generateId = () => {
  return Date.now().toString();
};

export default {
  formatDate,
  parseJSON,
  debounce,
  generateId,
};
