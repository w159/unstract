#!/usr/bin/env python
"""
Merges environment variables from a base env file to a target env file.
Preserves target values while allowing new keys from base.
"""

import os
import sys
from typing import Dict, List, Tuple

# Keys whose values should be preserved from the base env file
PREFERRED_BASE_ENV_KEYS = ["ENCRYPTION_KEY"]

# Keys that should have default values if not set
SET_DEFAULT_KEYS = {
    "WORKER_AUTOSCALE": "10,20",
    "WORKER_LOGGING_AUTOSCALE": "1,2",
    "WORKER_FILE_PROCESSING_AUTOSCALE": "5,10",
    "WORKER_FILE_PROCESSING_CALLBACK_AUTOSCALE": "5,10",
}


def extract_kv_from_line(line: str) -> Tuple[str, str]:
    """Extract key-value pair from an environment file line.
    
    Args:
        line: Single line from env file
        
    Returns:
        Tuple of (key, value)
    """
    key_value = line.split("=", 1)
    key = key_value[0].strip()
    value = key_value[1].strip() if len(key_value) > 1 else ""
    
    # Remove quotes if present
    if value and value[0] in ['"', "'"] and value[-1] in ['"', "'"]:
        value = value[1:-1]
        
    return key, value


def extract_from_env_file(env_file_path: str) -> Dict[str, str]:
    """Load environment variables from a file into a dictionary.
    
    Args:
        env_file_path: Path to environment file
        
    Returns:
        Dictionary of environment variables
    """
    if not os.path.exists(env_file_path):
        return {}
        
    env = {}
    with open(env_file_path) as file:
        for line in file:
            line = line.strip()
            if line and not line.startswith("#"):
                key, value = extract_kv_from_line(line)
                env[key] = value
                
    return env


def process_base_env_line(
    line: str, 
    target_env: Dict[str, str], 
    merged_contents: List[str]
) -> None:
    """Process a single line from base env file.
    
    Args:
        line: Line from base env file
        target_env: Target environment dictionary
        merged_contents: List to append processed lines to
    """
    # Preserve empty lines and comments
    if not line.strip() or line.startswith("#"):
        merged_contents.append(line)
        return
        
    key, value = extract_kv_from_line(line)
    
    # Determine which value to use
    if key not in PREFERRED_BASE_ENV_KEYS and key in target_env:
        value = target_env.get(key, value)
        
    # Set default value if needed
    if not value and key in SET_DEFAULT_KEYS:
        value = SET_DEFAULT_KEYS[key]
        
    merged_contents.append(f"{key}={value}\n")


def add_additional_env_vars(
    base_env: Dict[str, str],
    target_env: Dict[str, str],
    merged_contents: List[str]
) -> None:
    """Add environment variables from target that aren't in base.
    
    Args:
        base_env: Base environment dictionary
        target_env: Target environment dictionary
        merged_contents: List to append additional vars to
    """
    additional_keys = [key for key in target_env if key not in base_env]
    
    if additional_keys:
        merged_contents.append("\n\n# Additional envs\n")
        for key in additional_keys:
            merged_contents.append(f"{key}={target_env.get(key)}\n")


def merge_to_env_file(base_env_file_path: str, target_env: Dict[str, str] = None) -> str:
    """Merge environment files preserving target values.
    
    Args:
        base_env_file_path: Path to base env file (e.g., sample.env)
        target_env: Target environment dictionary (optional)
        
    Returns:
        Merged file contents as string
    """
    if target_env is None:
        target_env = {}
        
    merged_contents = []
    
    # Process base env file line by line
    with open(base_env_file_path) as file:
        for line in file:
            process_base_env_line(line, target_env, merged_contents)
            
    # Add any additional vars from target
    base_env = extract_from_env_file(base_env_file_path)
    add_additional_env_vars(base_env, target_env, merged_contents)
    
    return "".join(merged_contents)


def main():
    """Main function to merge environment files."""
    if len(sys.argv) != 3:
        print("Usage: merge_env.py <base_env_file> <target_env_file>")
        sys.exit(1)
        
    base_env_file = sys.argv[1]
    target_env_file = sys.argv[2]
    
    if not os.path.exists(base_env_file):
        print(f"Base env file not found: {base_env_file}")
        sys.exit(1)
        
    print(f"Merging {base_env_file} -> {target_env_file}")
    
    # Load target env if it exists
    target_env = extract_from_env_file(target_env_file)
    
    # Generate merged contents
    merged_content = merge_to_env_file(base_env_file, target_env)
    
    # Write to target file
    with open(target_env_file, "w") as file:
        file.write(merged_content)
        
    print(f"✅ Successfully merged to {target_env_file}")


if __name__ == "__main__":
    main()