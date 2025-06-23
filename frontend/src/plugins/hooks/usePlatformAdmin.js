// Stub implementation for usePlatformAdmin hook
import { useState, useEffect } from "react";

export const usePlatformAdmin = () => {
  const [isPlatformAdmin, setIsPlatformAdmin] = useState(false);
  const [loading] = useState(false);

  useEffect(() => {
    // Stub implementation
    setIsPlatformAdmin(false);
  }, []);

  return { isPlatformAdmin, loading };
};

export default usePlatformAdmin;
