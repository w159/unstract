// Stub implementation for PublicShareAPIs
export const sharePrompt = async (promptId, shareOptions) => {
  return { success: true, shareUrl: "" };
};

export const getSharedPrompt = async (shareId) => {
  return { prompt: {} };
};

export const revokeShare = async (shareId) => {
  return { success: true };
};

export default {
  sharePrompt,
  getSharedPrompt,
  revokeShare,
};
