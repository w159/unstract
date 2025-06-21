import { useState, useEffect } from "react";

/**
 * Custom hook to manage the complex state logic for ToolIde component
 * Consolidates share modal state management and plugin loading
 */
export const useToolIdeState = (shareId) => {
  const [openSettings, setOpenSettings] = useState(false);
  const [loginModalOpen, setLoginModalOpen] = useState(true);
  const [openShareLink, setOpenShareLink] = useState(false);
  const [openShareConfirmation, setOpenShareConfirmation] = useState(false);
  const [openShareModal, setOpenShareModal] = useState(false);
  const [openCloneModal, setOpenCloneModal] = useState(false);

  // Handle share modal state based on shareId
  useEffect(() => {
    if (openShareModal) {
      if (shareId) {
        setOpenShareConfirmation(false);
        setOpenShareLink(true);
      } else {
        setOpenShareConfirmation(true);
        setOpenShareLink(false);
      }
    }
  }, [shareId, openShareModal]);

  // Reset share states when modal closes
  useEffect(() => {
    if (!openShareModal) {
      setOpenShareConfirmation(false);
      setOpenShareLink(false);
    }
  }, [openShareModal]);

  return {
    // Settings modal
    openSettings,
    setOpenSettings,
    
    // Login modal
    loginModalOpen,
    setLoginModalOpen,
    
    // Share modals
    openShareLink,
    setOpenShareLink,
    openShareConfirmation,
    setOpenShareConfirmation,
    openShareModal,
    setOpenShareModal,
    
    // Clone modal
    openCloneModal,
    setOpenCloneModal,
  };
};

/**
 * Load optional plugins with error handling
 */
export const loadPlugins = () => {
  const plugins = {
    OnboardMessagesModal: null,
    slides: [],
    PromptShareModal: null,
    PromptShareLink: null,
    HeaderPublic: null,
    CloneTitle: null,
  };

  // Load onboarding plugins
  try {
    plugins.OnboardMessagesModal =
      require("../../../plugins/onboarding-messages/OnboardMessagesModal.jsx").OnboardMessagesModal;
    plugins.slides =
      require("../../../plugins/onboarding-messages/prompt-slides.jsx").PromptSlides;
  } catch (err) {
    // Plugins not available, use defaults
  }

  // Load share plugins
  try {
    plugins.PromptShareModal =
      require("../../../plugins/prompt-studio-public-share/public-share-modal/PromptShareModal.jsx").PromptShareModal;
    plugins.PromptShareLink =
      require("../../../plugins/prompt-studio-public-share/public-link-modal/PromptShareLink.jsx").PromptShareLink;
    plugins.HeaderPublic =
      require("../../../plugins/prompt-studio-public-share/header-public/HeaderPublic.jsx").HeaderPublic;
  } catch (err) {
    // Plugins not available, use defaults
  }

  // Load clone plugin
  try {
    plugins.CloneTitle =
      require("../../../plugins/prompt-studio-clone/clone-title-modal/CloneTitle.jsx").CloneTitle;
  } catch (err) {
    // Plugin not available, use default
  }

  return plugins;
};