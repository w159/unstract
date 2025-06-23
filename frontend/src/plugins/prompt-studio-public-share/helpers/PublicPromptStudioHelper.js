// Stub implementation for PublicPromptStudioHelper
export const validatePublicShare = (shareData) => {
  return true;
};

export const generateShareLink = (promptId) => {
  return `share/${promptId}`;
};

export const checkSharePermissions = (userId, promptId) => {
  return true;
};

export default {
  validatePublicShare,
  generateShareLink,
  checkSharePermissions,
};
