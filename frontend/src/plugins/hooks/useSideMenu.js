// Stub implementation for useSideMenu hook
import { useState } from "react";

export const useSideMenu = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [selectedItem, setSelectedItem] = useState(null);

  const toggleMenu = () => setIsOpen(!isOpen);
  const closeMenu = () => setIsOpen(false);
  const openMenu = () => setIsOpen(true);

  return {
    isOpen,
    selectedItem,
    setSelectedItem,
    toggleMenu,
    closeMenu,
    openMenu,
  };
};

export default useSideMenu;
