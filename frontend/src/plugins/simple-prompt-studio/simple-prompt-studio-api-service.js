// Stub implementation for simple-prompt-studio-api-service
export const getPrompts = async () => {
  return [];
};

export const createPrompt = async (promptData) => {
  return { id: "stub-id", ...promptData };
};

export const updatePrompt = async (promptId, promptData) => {
  return { id: promptId, ...promptData };
};

export const deletePrompt = async (promptId) => {
  return { success: true };
};

export const runPrompt = async (promptId, inputs) => {
  return { output: "" };
};

export default {
  getPrompts,
  createPrompt,
  updatePrompt,
  deletePrompt,
  runPrompt,
};
