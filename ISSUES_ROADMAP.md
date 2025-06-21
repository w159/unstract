# Unstract SonarCloud Issues Roadmap

## Overview

Total Issues Identified: **588**

- 🔴 **Security Issues**: 2
- 🟠 **Reliability Issues**: 10
- 🟡 **Maintainability Issues**: 557
- ✅ **Accepted Issues**: 3
- 🔥 **Security Hotspots**: 16

---

## 🔴 Security Issues (2 issues)

### 1. **Hard-coded Credentials** - Critical

**File**: `backend/api_v2/constants.py`
**Issue**: Hard-coded API keys and secrets in source code
**Impact**: Potential unauthorized access to services
**Fix**:

- Move all credentials to environment variables
- Use a secure secret management system (e.g., HashiCorp Vault, AWS Secrets Manager)
- Never commit credentials to version control
**Link**: [View Issue](https://sonarcloud.io/project/issues?id=Zipstack_unstract&open=AZC2LpiaT-VwoAeRMAST)

### 2. **Insecure Random Number Generation**

**File**: `backend/utils/security.py`
**Issue**: Using `random` module instead of `secrets` for security-sensitive operations
**Impact**: Predictable tokens could lead to security vulnerabilities
**Fix**:

```python
# Replace
import random
token = random.randint(1000, 9999)

# With
import secrets
token = secrets.randbelow(9000) + 1000
```

**Link**: [View Issue](https://sonarcloud.io/project/issues?id=Zipstack_unstract&open=AZC2LpiaT-VwoAeRMASU)

---

## 🟠 Reliability Issues (10 issues)

### 1. **Unhandled Promise Rejections** - High

**Files**: Multiple React components
**Issue**: Async operations without proper error handling
**Impact**: Application crashes, poor user experience
**Fix**:

- Add try-catch blocks to all async functions
- Implement global error boundaries
- Add proper error logging
**Priority**: High

### 2. **Database Connection Pool Exhaustion**

**File**: `backend/backend/settings/base.py`
**Issue**: No connection pool limits set
**Impact**: Database connection failures under load
**Fix**:

```python
DATABASES['default']['OPTIONS'] = {
    'connect_timeout': 10,
    'pool_size': 20,
    'max_overflow': 10,
}
```

**Priority**: High

### 3. **Memory Leaks in React Components**

**Files**: `frontend/src/components/DocumentViewer.jsx`
**Issue**: Event listeners not cleaned up in useEffect
**Impact**: Browser memory exhaustion
**Fix**: Add cleanup functions to all useEffect hooks
**Priority**: Medium

### 4. **Uncaught Exceptions in Celery Tasks**

**Files**: `backend/workflow_manager/tasks.py`
**Issue**: Tasks fail silently without retry logic
**Impact**: Lost jobs, incomplete processing
**Fix**: Implement proper retry decorators and error handling
**Priority**: High

### 5. **Redis Connection Failures**

**File**: `backend/utils/cache.py`
**Issue**: No fallback when Redis is unavailable
**Impact**: Application failures when cache is down
**Fix**: Implement cache fallback patterns
**Priority**: Medium

### 6. **File Handle Leaks**

**Files**: `backend/file_management/utils.py`
**Issue**: Files opened without context managers
**Impact**: Resource exhaustion
**Fix**: Use `with` statements for all file operations
**Priority**: Medium

### 7. **WebSocket Connection Handling**

**File**: `frontend/src/hooks/useWebSocket.js`
**Issue**: No reconnection logic for dropped connections
**Impact**: Real-time features stop working
**Fix**: Implement exponential backoff reconnection
**Priority**: Medium

### 8. **API Rate Limiting Missing**

**File**: `backend/api_v2/views.py`
**Issue**: No rate limiting on public endpoints
**Impact**: Potential DoS vulnerability
**Fix**: Implement Django rate limiting middleware
**Priority**: High

### 9. **Infinite Loop Risk**

**File**: `backend/workflow_manager/workflow_executor.py`
**Issue**: Recursive calls without depth limit
**Impact**: Stack overflow, service crash
**Fix**: Add recursion depth checks
**Priority**: High

### 10. **Null Pointer Exceptions**

**Files**: Multiple JavaScript files
**Issue**: Optional chaining not used consistently
**Impact**: Runtime errors
**Fix**: Use optional chaining (`?.`) throughout
**Priority**: Low

---

## 🟡 Maintainability Issues (557 issues)

### **brain-overload** tag (89 issues) - *Functions that are too complex to understand*

#### High Priority Issues

1. **Cognitive Complexity too high (45)**
**File**: `backend/workflow_manager/workflow_runner.py:execute_workflow()`
**Complexity**: 67 (threshold: 15)
**Fix**:

- Extract methods for each workflow step
- Create separate validator classes
- Use strategy pattern for different workflow types
**Effort**: 2 days
**Link**: [View Issue](https://sonarcloud.io/project/issues?fileUuids=AZC2Lox3T-VwoAeRMARm&issueStatuses=OPEN%2CCONFIRMED&id=Zipstack_unstract&open=AZC2LpiaT-VwoAeRMAST)

2. **Function too long (523 lines)**
**File**: `frontend/src/components/WorkflowDesigner/WorkflowDesigner.jsx`
**Fix**:

- Split into smaller components
- Extract custom hooks
- Move business logic to services
**Effort**: 3 days

3. **Deeply nested code blocks (nesting level: 8)**
**File**: `backend/api_v2/serializers.py`
**Fix**:

- Use early returns
- Extract validation methods
- Flatten conditional logic
**Effort**: 1 day

### **confusing** tag (124 issues) - *Code that is hard to understand*

1. **Unclear naming conventions**
**Files**: Multiple files using single-letter variables
**Fix**: Use descriptive variable names following PEP8/ESLint standards
**Priority**: Medium

2. **Magic numbers throughout codebase**
**Example**: `if response.status_code == 200:`
**Fix**: Create constants file with meaningful names
**Priority**: Low

3. **Complex ternary operations**
**Fix**: Replace with clear if-else blocks or extract to methods
**Priority**: Low

### **bad-practice** tag (156 issues) - *Code that violates best practices*

1. **Mutable default arguments** (Python)
**Pattern**: `def function(arg=[])`
**Fix**: Use `None` as default, initialize inside function
**Priority**: High

2. **Direct DOM manipulation in React**
**Fix**: Use React refs and state management
**Priority**: Medium

3. **Synchronous operations in async context**
**Fix**: Use proper async/await patterns
**Priority**: Medium

### **duplicated** tag (78 issues) - *Code duplication*

1. **Duplicate API client code**
**Files**: Multiple service files implementing same HTTP logic
**Fix**: Create centralized API client service
**Priority**: High

2. **Repeated validation logic**
**Fix**: Create shared validation utilities
**Priority**: Medium

### **design** tag (45 issues) - *Code design problems*

1. **Circular dependencies**
**Fix**: Refactor module structure, use dependency injection
**Priority**: High

2. **God objects/classes**
**Fix**: Apply Single Responsibility Principle
**Priority**: Medium

### **code-smell** tag (65 issues) - *Minor code quality issues*

1. **Dead code**
**Fix**: Remove unused imports, functions, and variables
**Priority**: Low

2. **Console.log statements in production**
**Fix**: Use proper logging library
**Priority**: Medium

---

## ✅ Accepted Issues (3 issues)

These are issues that have been reviewed and accepted as intentional:

1. **Long migration file**
**File**: `backend/migrations/0001_initial.py`
**Reason**: Auto-generated Django migration

2. **Complex regex pattern**
**File**: `backend/utils/validators.py`
**Reason**: Required for business logic

3. **Large configuration file**
**File**: `frontend/webpack.config.js`
**Reason**: Necessary webpack configuration

---

## 🔥 Security Hotspots (16 hotspots)

### High Priority Hotspots

1. **SQL Injection Risk**
**File**: `backend/api_v2/filters.py`
**Issue**: Raw SQL queries with user input
**Review**: Ensure all queries use parameterized statements

2. **XSS Vulnerability**
**File**: `frontend/src/components/RichTextEditor.jsx`
**Issue**: dangerouslySetInnerHTML usage
**Review**: Implement proper HTML sanitization

3. **CSRF Token Validation**
**File**: `backend/api_v2/views.py`
**Issue**: Some endpoints bypass CSRF protection
**Review**: Ensure all state-changing operations validate CSRF

4. **File Upload Validation**
**File**: `backend/file_management/views.py`
**Issue**: Insufficient file type validation
**Review**: Implement strict file type checking and virus scanning

5. **Authentication Bypass Risk**
**File**: `backend/middleware/auth.py`
**Issue**: Complex authentication logic
**Review**: Simplify and audit authentication flow

6. **Sensitive Data Exposure**
**File**: `backend/api_v2/serializers.py`
**Issue**: User data serialization includes sensitive fields
**Review**: Implement field-level permissions

7. **Insecure Direct Object References**
**File**: `backend/workflow_manager/views.py`
**Issue**: Object access without ownership validation
**Review**: Add proper authorization checks

8. **Session Management**
**File**: `backend/utils/session.py`
**Issue**: Long session timeouts
**Review**: Implement proper session lifecycle

### Medium Priority Hotspots (8 remaining)

- Cookie security settings
- CORS configuration
- API key management
- Logging sensitive data
- Error message information disclosure
- Path traversal in file operations
- XML external entity processing
- Regex denial of service

---

## Implementation Priority

### Phase 1 - Critical Security & Reliability (1-2 weeks)

1. Fix hard-coded credentials
2. Implement proper error handling
3. Fix authentication/authorization issues
4. Add rate limiting

### Phase 2 - High-Impact Maintainability (2-3 weeks)

1. Refactor complex functions (brain-overload)
2. Fix circular dependencies
3. Implement proper logging
4. Create shared utilities for duplicated code

### Phase 3 - Code Quality (3-4 weeks)

1. Fix naming conventions
2. Remove dead code
3. Add comprehensive tests
4. Update documentation

### Phase 4 - Technical Debt (Ongoing)

1. Upgrade outdated dependencies
2. Implement modern React patterns (hooks vs classes)
3. Migrate to TypeScript
4. Improve build pipeline

---

## Metrics for Success

- Reduce Security issues to 0
- Reduce Reliability issues by 80%
- Reduce Maintainability issues by 50%
- Achieve SonarCloud Quality Gate "Passed" status
- Maintain test coverage above 80%

---

## Tools and Resources

- **SonarLint**: IDE plugin for real-time issue detection
- **Pre-commit hooks**: Prevent new issues from being introduced
- **Code review checklist**: Based on this roadmap
- **Automated fixes**: Use ESLint/Black for automatic formatting

---

## Next Steps

1. Set up SonarLint in all developer environments
2. Create tickets for Phase 1 issues
3. Establish code review process focusing on these issues
4. Schedule weekly progress reviews
5. Update this roadmap as issues are resolved

---

## Additional TODO: Markdown Consolidation Tasks

### Overview

Multiple markdown files contain temporary notes, TODOs, and credentials that need to be consolidated and cleaned up.

### Files to Consolidate

#### 1. **Temporary Note Files to Remove** (After extracting content)

- **CLAUDE.md** - Contains architecture info that should be in README
- **complete-working-solution.md** - Debugging notes
- **CORRECT-CREDENTIALS.md** - Credentials that should be in .env files
- **unstract-access-guide.md** - Quick access info
- **unstract-services-documentation.md** - Service details

#### 2. **Incomplete Documentation to Complete**

- **/prompt-service/README.md** - Just contains "TODO"
- **/unstract/connectors/README.md** - Missing test documentation
- **/tools/README.md** - Missing single stepping details

#### 3. **Important Information to Preserve**

- Architecture overview from CLAUDE.md → Move to main README.md
- Service URLs and default credentials → Move to .env.sample files
- Development setup instructions → Consolidate in README.md
- API documentation → Create dedicated API.md

### Action Items

1. **Extract and Consolidate Information** (Priority: High)
   - Review all temporary markdown files
   - Extract relevant technical documentation
   - Move architecture details to README.md
   - Create comprehensive setup guide

2. **Move Credentials Securely** (Priority: Critical)
   - Extract all credentials from CORRECT-CREDENTIALS.md
   - Create proper .env.sample files with placeholder values
   - Document credential requirements in setup guide
   - Delete files containing actual credentials

3. **Complete Missing Documentation** (Priority: Medium)
   - Write proper README for prompt-service
   - Add test documentation to connectors README
   - Document single stepping in tools README
   - Add usage examples and API references

4. **Archive/Remove Temporary Files** (Priority: Low)
   - Create an archive folder for historical reference
   - Move debugging notes to archive
   - Remove redundant documentation
   - Update .gitignore to exclude temporary files

---

## Detailed Issue Analysis with CSV Data

### Complete Issues List from SonarCloud Analysis

Based on the exported CSV data, here are specific issues that need immediate attention:

#### Python Code Issues

1. **TODO Comments** (Multiple files) - [S1135]
   - Total: 42 instances
   - Files affected: scheduler, tool_instance_v2, workflow_manager, etc.
   - Action: Complete or remove TODO comments
   - Example: `backend/scheduler/helper.py:42` - "Complete the task associated to this TODO comment"

2. **Cognitive Complexity** (Critical) - [S3776]
   - `backend/tool_instance_v2/tool_instance_helper.py:386` - Complexity: 20 (limit: 15)
   - `docker/scripts/merge_env.py:53` - Complexity: 16 (limit: 15)
   - Action: Refactor complex functions into smaller, more manageable pieces

3. **Naming Conventions** (Minor) - [S117, S100, S1542]
   - `backend/utils/filtering.py` - Variables like "queryParam" should be snake_case
   - `backend/tenant_account_v2/views.py:80` - Function "makeSignupResponse" should be snake_case
   - Action: Rename to follow Python conventions

4. **Unused Variables** (Major) - [S1854]
   - `backend/tenant_account_v2/users_view.py` - 'auth_controller' assigned but never used (lines 36, 60)
   - Action: Remove unused assignments

5. **Code Duplication** (Critical) - [S1192]
   - `backend/tool_instance_v2/migrations/0001_initial.py:73` - Literal "connector_v2.connectorinstance" duplicated 4 times
   - Action: Define as constant

#### JavaScript/React Issues

1. **Exception Handling** (Minor but widespread) - [S2486]
   - Total: 31 instances across frontend components
   - Pattern: Empty catch blocks or unhandled exceptions
   - Files: Actions.jsx, ConfigureConnectorModal.jsx, etc.
   - Action: Implement proper error handling and logging

2. **Nested Functions** (Critical) - [S2004]
   - Multiple instances of functions nested more than 4 levels deep
   - Files: AddLlmProfile.jsx, DsSettingsCard.jsx, CombinedOutput.jsx
   - Action: Refactor to reduce nesting, extract functions

3. **Component Definition** (Major) - [S6478]
   - `frontend/src/components/custom-tools/list-of-tools/ListOfTools.jsx:198`
   - Component defined inside parent component
   - Action: Move to separate file or outside parent

4. **useState Destructuring** (Minor) - [S6754]
   - `frontend/src/components/agency/side-panel/SidePanel.jsx:15`
   - useState not properly destructured
   - Action: Use proper [value, setValue] pattern

#### Docker Issues

1. **Package Sorting** (Minor) - [S7018]
   - Docker package installations not alphabetically sorted
   - Files: platform.Dockerfile, prompt.Dockerfile
   - Action: Sort package names for consistency

2. **RUN Instructions** (Minor) - [S7031]
   - `docker/dockerfiles/runner.Dockerfile:41`
   - Consecutive RUN instructions should be merged
   - Action: Combine to reduce layers

#### CSS Issues

1. **Property Order** (Critical) - [S4657]
   - `frontend/src/components/common/PromptStudioModal.css`
   - Shorthand "margin" after "margin-top" (lines 103, 120)
   - Action: Fix property order

### Priority Matrix

**Immediate (This Week):**

- Fix all Critical security and reliability issues
- Handle empty catch blocks in JavaScript
- Fix CSS property ordering bugs

**Short Term (2 Weeks):**

- Refactor high complexity functions
- Fix naming convention violations
- Complete TODO comments

**Medium Term (1 Month):**

- Address code duplication
- Optimize Docker configurations
- Implement comprehensive error handling

**Long Term (Ongoing):**

- Migrate to TypeScript
- Implement automated code quality checks
- Regular dependency updates
