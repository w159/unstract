// Stub implementation for useLlmWhispererAdapterSchema hook
import { useState, useEffect } from "react";

export const useLlmWhispererAdapterSchema = () => {
  const [schema, setSchema] = useState(null);
  const [loading] = useState(false);
  const [error] = useState(null);

  useEffect(() => {
    // Stub implementation
    setSchema({});
  }, []);

  return { schema, loading, error };
};

export default useLlmWhispererAdapterSchema;
