# TODO Comments Summary - Backend Directory

This document lists all TODO comments found in the backend directory, organized by category.

## Summary Statistics
- **Total TODO comments found**: 60
- **Python files with TODOs**: 46
- **Configuration files with TODOs**: 1 (pyproject.toml)
- **JavaScript files with TODOs**: 0

## TODOs by Category

### 1. Authentication & Security (6 TODOs)
- **backend/settings/base.py:469** - `# TODO: Update once auth is figured`
  - Default permission classes need to be updated
- **connector_auth_v2/models.py:22** - `# TODO PAN-83: Decrypt here`
- **connector_auth_v2/models.py:55** - `# TODO PAN-83: Encrypt here`
- **platform_settings_v2/platform_auth_service.py:60** - `# TODO : Add encryption to Platform keys`
- **platform_settings_v2/platform_auth_service.py:102** - `# TODO: Add organization details in logs in possible places once v2 enabled`
- **connector_v2/unstract_account.py:11** - `# TODO: UnstractAccount need to be pluggable`

### 2. Database & Model Changes (13 TODOs)
- **adapter_processor_v2/models.py:68** - `# TODO to be removed once the migration for encryption`
- **connector_v2/models.py:30** - `# TODO: handle all cascade deletions`
- **connector_v2/models.py:55** - `# TODO: handle connector_auth cascade deletion`
- **connector_v2/models.py:87** - `# TODO: Remove if unused`
- **pipeline_v2/models.py:78** - `# TODO: Change this to a Forgein key once the bundle is created`
- **prompt_studio/prompt_studio_v2/models.py:88** - `# TODO: Remove below 3 fields related to assertion`
- **prompt/models.py:38** - `# TODO: Replace once Workflow model is added`
- **tool_instance_v2/models.py:45** - `# TODO: Make as an enum supporting fixed values once we have clarity`
- **workflow_manager/workflow_v2/models/execution.py:83** - `# TODO: Make as foreign key to access the instance directly`
- **workflow_manager/workflow_v2/models/workflow.py:34** - `# TODO Make this guid as primaryId instaed of current id bigint`
- **utils/models/organization_mixin.py:1** - `# TODO:V2 class`
- **scheduler/helper.py:42** - `# TODO: Remove unused argument in execute_pipeline_task`
- **scheduler/helper.py:54** - `# TODO: execution_id parameter cannot be removed without a migration`

### 3. Error Handling & Validation (7 TODOs)
- **adapter_processor_v2/views.py:285** - `# TODO: Provide details of adpter usage with exception object`
- **connector_v2/views.py:79** - `# TODO: Handle specific exceptions instead of using a generic Exception`
- **connector_v2/views.py:98** - `# TODO: Handle specific exceptions instead of using a generic Exception`
- **tool_instance_v2/tool_instance_helper.py:359** - `# TODO: Support other JSON validation errors`
- **workflow_manager/endpoint_v2/source.py:188** - `# TODO: Validate while receiving this input configuration as well`
- **workflow_manager/endpoint_v2/source.py:191** - `# TODO: Move to connector class for better error handling`
- **workflow_manager/endpoint_v2/destination.py:483** - `# TODO: SDK handles validation; consider removing here`

### 4. Performance & Optimization (4 TODOs)
- **utils/FileValidator.py:73** - `# TODO: Need to optimise, istead of reading entire file`
- **workflow_manager/execution/serializer/execution.py:7** - `# TODO: Optimize with select_related / prefetch_related to reduce DB queries`
- **workflow_manager/workflow_v2/workflow_helper.py:878** - `# TODO: Access cache through a manager`
- **usage_v2/urls.py:15** - `# TODO: Refactor URL to avoid using action-specific verbs like get`

### 5. Code Refactoring & Architecture (15 TODOs)
- **pipeline_v2/manager.py:38** - `# TODO: Use DRF's request and as_view() instead`
- **pipeline_v2/views.py:57** - `# TODO: Refactor to perform an action with explicit arguments`
- **tool_instance_v2/views.py:158** - `# TODO: Move update logic into serializer`
- **workflow_manager/endpoint_v2/source.py:48** - `# TODO: Inherit from SourceConnector for different sources - File, API .etc`
- **workflow_manager/endpoint_v2/source.py:637** - `# TODO: move this to where file is listed at source`
- **workflow_manager/endpoint_v2/source.py:751** - `# TODO: replace it with method from SDK Utils`
- **workflow_manager/workflow_v2/workflow_helper.py:626** - `# TODO: Make use of WorkflowExecution.get_or_create()`
- **prompt_studio/prompt_studio_core_v2/views.py:331** - `# TODO: Move to prompt_profile_manager app and move validation to serializer`
- **prompt_studio/prompt_studio_output_manager_v2/views.py:66** - `# TODO: Setup Serializer here`
- **prompt_studio/prompt_studio_output_manager_v2/output_manager_helper.py:156** - `# TODO: use enums here`
- **prompt_studio/prompt_studio_output_manager_v2/output_manager_util.py:30** - `# TODO: remove singlepass reference`
- **connector_auth_v2/pipeline/common.py:110** - `# TODO: Remove User's related manager access to ConnectorAuth`
- **scheduler/serializer.py:17** - `# TODO: Add custom URL field to allow URLs for running in docker`
- **prompt_studio/prompt_studio_registry_v2/constants.py:30** - `# TODO: Update prompt studio constants to have a single source of truth`
- **utils/common_utils.py:37** - `# TODO: Use from SDK`

### 6. Feature Implementation (7 TODOs)
- **api_v2/models.py:49** - `# TODO: Implement dynamic generation of API endpoints for API deployments`
- **pipeline_v2/serializers/crud.py:109** - `# TODO: Deduce pipeline type based on WF?`
- **pipeline_v2/serializers/execute.py:10** - `# TODO: Add pipeline as a read_only related field`
- **prompt_studio/prompt_studio_core_v2/views.py:288** - `# TODO: Handle fetch_response and single_pass_`
- **workflow_manager/endpoint_v2/database_utils.py:62** - `# TODO: Handle numeric types with no quotes`
- **file_management/file_management_helper.py:51** - `# TODO: Add below logic by checking each connector?`
- **workflow_manager/workflow_v2/serializers.py:77** - `# TODO: Add other fields to handle WFExecution method, mode .etc`

### 7. Tool/SDK Related (5 TODOs)
- **tool_instance_v2/serializers.py:81** - `# TODO: Handle other fields once tools SDK is out`
- **tool_instance_v2/serializers.py:83** - `# TODO: Use version from tool props`
- **tool_instance_v2/serializers.py:86** - `# TODO: Review and remove tool instance ID`
- **tool_instance_v2/tool_instance_helper.py:186** - `# TODO: Review if adding this metadata is still required`
- **prompt_studio/prompt_studio_registry_v2/prompt_studio_registry_helper.py:103** - `# TODO: Update for new architecture`

### 8. Bug Fixes & Issues (5 TODOs)
- **workflow_manager/workflow_v2/file_history_helper.py:160** - `# TODO: Need to find why duplicate insert is coming`
- **workflow_manager/workflow_v2/execution.py:413** - `# TODO: Review if status should be updated to EXECUTING`
- **workflow_manager/workflow_v2/workflow_helper.py:699** - `# TODO: Remove this if scheduled runs work`
- **workflow_manager/endpoint_v2/source.py:716** - `# TODO: Consider removing this since the input is not extracted text`
- **utils/file_storage/helpers/prompt_studio_file_helper.py:117** - `# TODO : Handle this with proper fix` (Temporary hack for frictionless onboarding)

### 9. Dependencies & Configuration (1 TODO)
- **pyproject.toml:38** - `# TODO: Temporarily removing the extra dependencies of aws and gcs from unstract-sdk`

### 10. Legacy/Deprecated Code (1 TODO)
- **scheduler/tasks.py:56** - `# TODO: Remove unused args with a migration`

## Priority Recommendations

### High Priority (Security & Data Integrity)
1. Implement encryption/decryption in connector_auth_v2/models.py
2. Update authentication permissions in backend/settings/base.py
3. Fix duplicate insert issue in file_history_helper.py
4. Handle cascade deletions properly in connector models

### Medium Priority (Performance & Architecture)
1. Optimize database queries with select_related/prefetch_related
2. Refactor source connector inheritance structure
3. Move business logic from views to serializers
4. Implement proper cache management

### Low Priority (Code Cleanup)
1. Remove unused fields and arguments
2. Update constants to have single source of truth
3. Replace generic exception handling with specific ones
4. Remove temporary hacks once proper solutions are implemented

## Next Steps
1. Create tickets for high-priority security TODOs
2. Plan database migrations for model changes
3. Schedule refactoring sprints for architectural improvements
4. Review and remove obsolete TODOs that may no longer be relevant