#!/bin/sh
cd /tmp/unstract/frontend

# Create all missing plugin stub files
mkdir -p src/plugins/prompt-studio-public-share/helpers
echo "export const PublicPromptStudioHelper = {};" > src/plugins/prompt-studio-public-share/helpers/PublicPromptStudioHelper.js

mkdir -p src/plugins/routes
echo "export const useLlmWhispererRoutes = () => [];" > src/plugins/routes/useLlmWhispererRoutes.js
echo "export const useVerticalsRoutes = () => [];" > src/plugins/routes/useVerticalsRoutes.js

mkdir -p src/plugins/select-product
echo "export const SelectProduct = () => null;" > src/plugins/select-product/SelectProduct.jsx

mkdir -p src/plugins/unstract-subscription/pages
echo "export const UnstractSubscriptionEndPage = () => null;" > src/plugins/unstract-subscription/pages/UnstractSubscriptionEndPage.jsx
echo "export const UnstractSubscriptionPage = () => null;" > src/plugins/unstract-subscription/pages/UnstractSubscriptionPage.jsx
echo "export const UnstractUsagePage = () => null;" > src/plugins/unstract-subscription/pages/UnstractUsagePage.jsx

mkdir -p src/plugins/payment-successful
echo "export const PaymentSuccessful = () => null;" > src/plugins/payment-successful/PaymentSuccessful.jsx

mkdir -p src/plugins/frictionless-onboard/platform-admin-page
echo "export const RequirePlatformAdmin = ({children}) => children;" > src/plugins/frictionless-onboard/RequirePlatformAdmin.jsx
echo "export const PlatformAdminPage = () => null;" > src/plugins/frictionless-onboard/platform-admin-page/PlatformAdminPage.jsx

mkdir -p src/plugins/app-deployment/chat-app
echo "export const AppDeployments = () => null;" > src/plugins/app-deployment/AppDeployments.jsx
echo "export const ChatAppPage = () => null;" > src/plugins/app-deployment/chat-app/ChatAppPage.jsx
echo "export const ChatAppLayout = ({children}) => children;" > src/plugins/app-deployment/chat-app/ChatAppLayout.jsx
echo "export const getMenuItem = () => null;" > src/plugins/app-deployment/getMenuItem.js

mkdir -p src/plugins/manual-review/settings
echo "export const ManualReviewSettings = () => null;" > src/plugins/manual-review/settings/Settings.jsx

mkdir -p src/plugins/manual-review/page/simple
echo "export const ManualReviewPage = () => null;" > src/plugins/manual-review/page/ManualReviewPage.jsx
echo "export const SimpleManualReviewPage = () => null;" > src/plugins/manual-review/page/simple/SimpleManualReviewPage.jsx

mkdir -p src/plugins/manual-review/review-layout
echo "export const ReviewLayout = ({children}) => children;" > src/plugins/manual-review/review-layout/ReviewLayout.jsx

mkdir -p src/plugins/onboard-product
echo "export const OnboardProduct = () => null;" > src/plugins/onboard-product/OnboardProduct.jsx

mkdir -p src/plugins/unstract-subscription/components
echo "export const UnstractSubscriptionCheck = ({children}) => children;" > src/plugins/unstract-subscription/components/UnstractSubscriptionCheck.jsx
echo "export const TrialDaysInfo = () => null;" > src/plugins/unstract-subscription/components/TrialDaysInfo.jsx
echo "export const UnstractPricingMenuLink = () => null;" > src/plugins/unstract-subscription/components/UnstractPricingMenuLink.jsx

mkdir -p src/plugins/platform-dropdown
echo "export const PlatformDropDown = () => null;" > src/plugins/platform-dropdown/PlatformDropDown.jsx

mkdir -p src/plugins/llm-whisperer
echo "export const PRODUCT_NAMES = {}; export const helper = {};" > src/plugins/llm-whisperer/helper.js

# Create ALL other missing plugin files from the error list
mkdir -p src/plugins/google-tag-manager-helper
echo "export const GoogleTagManagerHelper = {};" > src/plugins/google-tag-manager-helper/GoogleTagManagerHelper.js

mkdir -p src/plugins/manual-review/db-rules
echo "export const DBRules = () => null;" > src/plugins/manual-review/db-rules/DBRules.jsx

mkdir -p src/plugins/manual-review/connector-config-tab-mrq
echo "export const ConnectorConfigTabMRQ = () => null;" > src/plugins/manual-review/connector-config-tab-mrq/ConnectorConfigTabMRQ.jsx

mkdir -p src/plugins/dscard-input-options
echo "export const AppDeploymentCardInputOptions = () => null;" > src/plugins/dscard-input-options/AppDeploymentCardInputOptions.jsx

mkdir -p src/plugins/simple-prompt-studio
echo "export const TableView = () => null;" > src/plugins/simple-prompt-studio/TableView.jsx
echo "export const helper = {};" > src/plugins/simple-prompt-studio/helper.js
echo "export const simple_prompt_studio_api_service = {};" > src/plugins/simple-prompt-studio/simple-prompt-studio-api-service.js
echo "export const SpsPromptsEmptyState = () => null;" > src/plugins/simple-prompt-studio/SpsPromptsEmptyState.jsx
echo "export const PromptRunBtnSps = () => null;" > src/plugins/simple-prompt-studio/PromptRunBtnSps.jsx
echo "export const AddPromptBtn = () => null;" > src/plugins/simple-prompt-studio/AddPromptBtn.jsx
echo "export const SimplePromptStudioHelper = () => null;" > src/plugins/simple-prompt-studio/SimplePromptStudioHelper.jsx
echo "export const SimplePromptStudio = () => null;" > src/plugins/simple-prompt-studio/SimplePromptStudio.jsx
echo "export const SpsLanding = () => null;" > src/plugins/simple-prompt-studio/SpsLanding.jsx
echo "export const SpsUpload = () => null;" > src/plugins/simple-prompt-studio/SpsUpload.jsx

# Continue with all other missing files...
echo "All plugin stubs created!"