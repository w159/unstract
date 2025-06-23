// Stub implementation for prompt-card-service
export const getPromptCardData = async (cardId) => {
  return {};
};

export const savePromptCard = async (cardData) => {
  return { success: true };
};

export const deletePromptCard = async (cardId) => {
  return { success: true };
};

export default {
  getPromptCardData,
  savePromptCard,
  deletePromptCard,
};
