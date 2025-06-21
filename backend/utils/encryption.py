"""
Encryption utilities for sensitive data.
"""
import base64
import logging
import os
from typing import Any, Dict, Optional

from cryptography.fernet import Fernet
from django.conf import settings

logger = logging.getLogger(__name__)


class EncryptionService:
    """Service for encrypting and decrypting sensitive data."""
    
    _instance = None
    _cipher_suite = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(EncryptionService, cls).__new__(cls)
        return cls._instance
    
    def __init__(self):
        if self._cipher_suite is None:
            self._initialize_cipher()
    
    def _initialize_cipher(self):
        """Initialize the cipher suite with encryption key."""
        # Get encryption key from settings or environment
        encryption_key = getattr(settings, 'ENCRYPTION_KEY', None)
        if not encryption_key:
            encryption_key = os.environ.get('ENCRYPTION_KEY')
        
        if not encryption_key:
            # Generate a new key if none exists (for development)
            logger.warning("No ENCRYPTION_KEY found. Generating a new one. "
                         "This should not happen in production!")
            encryption_key = Fernet.generate_key().decode()
            # Store it in settings for this session
            settings.ENCRYPTION_KEY = encryption_key
        
        # Ensure the key is bytes
        if isinstance(encryption_key, str):
            encryption_key = encryption_key.encode()
        
        self._cipher_suite = Fernet(encryption_key)
    
    def encrypt(self, data: Any) -> str:
        """
        Encrypt data and return base64 encoded string.
        
        Args:
            data: Data to encrypt (will be converted to string)
            
        Returns:
            Base64 encoded encrypted string
        """
        if data is None:
            return None
        
        try:
            # Convert data to string if needed
            if isinstance(data, dict):
                import json
                data_str = json.dumps(data)
            else:
                data_str = str(data)
            
            # Encrypt the data
            encrypted_bytes = self._cipher_suite.encrypt(data_str.encode())
            
            # Return base64 encoded string
            return base64.b64encode(encrypted_bytes).decode()
        except Exception as e:
            logger.error(f"Encryption failed: {e}")
            raise
    
    def decrypt(self, encrypted_data: str) -> Any:
        """
        Decrypt base64 encoded encrypted data.
        
        Args:
            encrypted_data: Base64 encoded encrypted string
            
        Returns:
            Decrypted data (attempts to parse as JSON if possible)
        """
        if encrypted_data is None:
            return None
        
        try:
            # Decode from base64
            encrypted_bytes = base64.b64decode(encrypted_data.encode())
            
            # Decrypt the data
            decrypted_bytes = self._cipher_suite.decrypt(encrypted_bytes)
            decrypted_str = decrypted_bytes.decode()
            
            # Try to parse as JSON
            try:
                import json
                return json.loads(decrypted_str)
            except json.JSONDecodeError:
                # If not JSON, return as string
                return decrypted_str
        except Exception as e:
            logger.error(f"Decryption failed: {e}")
            raise
    
    def encrypt_dict(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Encrypt sensitive fields in a dictionary.
        
        Args:
            data: Dictionary with potentially sensitive data
            
        Returns:
            Dictionary with encrypted values
        """
        if not data:
            return data
        
        encrypted_data = {}
        sensitive_fields = {'access_token', 'refresh_token', 'token_secret', 
                          'password', 'api_key', 'secret_key', 'client_secret'}
        
        for key, value in data.items():
            if key.lower() in sensitive_fields and value:
                encrypted_data[key] = self.encrypt(value)
            else:
                encrypted_data[key] = value
        
        return encrypted_data
    
    def decrypt_dict(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Decrypt sensitive fields in a dictionary.
        
        Args:
            data: Dictionary with encrypted values
            
        Returns:
            Dictionary with decrypted values
        """
        if not data:
            return data
        
        decrypted_data = {}
        sensitive_fields = {'access_token', 'refresh_token', 'token_secret',
                          'password', 'api_key', 'secret_key', 'client_secret'}
        
        for key, value in data.items():
            if key.lower() in sensitive_fields and value:
                try:
                    decrypted_data[key] = self.decrypt(value)
                except Exception:
                    # If decryption fails, keep original value
                    logger.warning(f"Failed to decrypt field: {key}")
                    decrypted_data[key] = value
            else:
                decrypted_data[key] = value
        
        return decrypted_data


# Singleton instance
encryption_service = EncryptionService()