"""Refactored version of validate_adapter_permissions to reduce cognitive complexity."""

from typing import Any, Dict, List, Set
from account_v2.models import User
from tool_instance_v2.constants import AdapterPropertyKey
from tool_instance_v2.models import Tool, ToolProcessor


class AdapterPermissionValidator:
    """Helper class to validate adapter permissions with reduced complexity."""
    
    def __init__(self, tool_uid: str, tool_meta: Dict[str, Any]):
        self.tool = ToolProcessor.get_tool_by_uid(tool_uid=tool_uid)
        self.tool_meta = tool_meta
        self.adapter_ids: Set[str] = set()
    
    def get_adapter_id(self, adapter_config: Any, default_key: str) -> str:
        """Get adapter ID from config or use default."""
        if adapter_config.adapter_id:
            return self.tool_meta[adapter_config.adapter_id]
        return self.tool_meta[default_key]
    
    def collect_language_model_adapters(self) -> None:
        """Collect adapter IDs from language models."""
        for llm in self.tool.properties.adapter.language_models:
            if llm.is_enabled:
                adapter_id = self.get_adapter_id(
                    llm, 
                    AdapterPropertyKey.DEFAULT_LLM_ADAPTER_ID
                )
                self.adapter_ids.add(adapter_id)
    
    def collect_vector_store_adapters(self) -> None:
        """Collect adapter IDs from vector stores."""
        for vdb in self.tool.properties.adapter.vector_stores:
            if vdb.is_enabled:
                adapter_id = self.get_adapter_id(
                    vdb,
                    AdapterPropertyKey.DEFAULT_VECTOR_DB_ADAPTER_ID
                )
                self.adapter_ids.add(adapter_id)
    
    def collect_embedding_adapters(self) -> None:
        """Collect adapter IDs from embedding services."""
        for embedding in self.tool.properties.adapter.embedding_services:
            if embedding.is_enabled:
                adapter_id = self.get_adapter_id(
                    embedding,
                    AdapterPropertyKey.DEFAULT_EMBEDDING_ADAPTER_ID
                )
                self.adapter_ids.add(adapter_id)
    
    def collect_text_extractor_adapters(self) -> None:
        """Collect adapter IDs from text extractors."""
        for text_extractor in self.tool.properties.adapter.text_extractors:
            if text_extractor.is_enabled:
                adapter_id = self.get_adapter_id(
                    text_extractor,
                    AdapterPropertyKey.DEFAULT_X2TEXT_ADAPTER_ID
                )
                self.adapter_ids.add(adapter_id)
    
    def collect_all_adapter_ids(self) -> Set[str]:
        """Collect all adapter IDs from all sources."""
        self.collect_language_model_adapters()
        self.collect_vector_store_adapters()
        self.collect_embedding_adapters()
        self.collect_text_extractor_adapters()
        return self.adapter_ids


def validate_adapter_permissions(
    user: User, tool_uid: str, tool_meta: Dict[str, Any]
) -> None:
    """Validate adapter permissions with reduced complexity.
    
    Args:
        user: User to validate permissions for
        tool_uid: Unique identifier for the tool
        tool_meta: Metadata containing adapter IDs
    """
    validator = AdapterPermissionValidator(tool_uid, tool_meta)
    adapter_ids = validator.collect_all_adapter_ids()
    
    # Delegate to existing validation method
    ToolInstanceHelper.validate_adapter_access(user=user, adapter_ids=adapter_ids)