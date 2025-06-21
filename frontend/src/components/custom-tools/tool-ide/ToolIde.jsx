import { Col, Row } from "antd";
import { useEffect } from "react";

import { useAxiosPrivate } from "../../../hooks/useAxiosPrivate";
import { useExceptionHandler } from "../../../hooks/useExceptionHandler";
import { useAlertStore } from "../../../store/alert-store";
import { useCustomToolStore } from "../../../store/custom-tool-store";
import { useSessionStore } from "../../../store/session-store";
import { DocumentManager } from "../document-manager/DocumentManager";
import { Header } from "../header/Header";
import { SettingsModal } from "../settings-modal/SettingsModal";
import { ToolsMain } from "../tools-main/ToolsMain";
import "./ToolIde.css";
import usePostHogEvents from "../../../hooks/usePostHogEvents.js";
import { PageTitle } from "../../widgets/page-title/PageTitle.jsx";
import { useToolIdeState, loadPlugins } from "../../../hooks/useToolIdeState";

// Load plugins once at module level
const {
  OnboardMessagesModal,
  slides,
  PromptShareModal,
  PromptShareLink,
  HeaderPublic,
  CloneTitle,
} = loadPlugins();
function ToolIde() {
  const {
    details,
    updateCustomTool,
    isMultiPassExtractLoading,
    selectedDoc,
    indexDocs,
    pushIndexDoc,
    deleteIndexDoc,
    shareId,
    isPublicSource,
  } = useCustomToolStore();
  const { sessionDetails } = useSessionStore();
  const { promptOnboardingMessage } = sessionDetails;
  const { setAlertDetails } = useAlertStore();
  const axiosPrivate = useAxiosPrivate();
  const handleException = useExceptionHandler();
  const { setPostHogCustomEvent } = usePostHogEvents();
  
  // Use custom hook for state management
  const {
    openSettings,
    setOpenSettings,
    loginModalOpen,
    setLoginModalOpen,
    openShareLink,
    setOpenShareLink,
    openShareConfirmation,
    setOpenShareConfirmation,
    openShareModal,
    setOpenShareModal,
    openCloneModal,
    setOpenCloneModal,
  } = useToolIdeState(shareId);

  const generateIndex = async (doc) => {
    const docId = doc?.document_id;

    if (indexDocs.includes(docId)) {
      setAlertDetails({
        type: "error",
        content: "This document is already getting indexed",
      });
      return;
    }

    const body = {
      document_id: docId,
    };

    const requestOptions = {
      method: "POST",
      url: `/api/v1/unstract/${sessionDetails?.orgId}/prompt-studio/index-document/${details?.tool_id}`,
      headers: {
        "X-CSRFToken": sessionDetails?.csrfToken,
        "Content-Type": "application/json",
      },
      data: body,
    };

    pushIndexDoc(docId);
    return axiosPrivate(requestOptions)
      .then(() => {
        setAlertDetails({
          type: "success",
          content: `${doc?.document_name} - Indexed successfully`,
        });

        try {
          setPostHogCustomEvent("intent_success_ps_indexed_file", {
            info: "Indexing completed",
          });
        } catch (err) {
          // If an error occurs while setting custom posthog event, ignore it and continue
        }
      })
      .catch((err) => {
        setAlertDetails(
          handleException(err, `${doc?.document_name} - Failed to index`)
        );
      })
      .finally(() => {
        deleteIndexDoc(docId);
      });
  };

  const handleUpdateTool = async (body) => {
    const requestOptions = {
      method: "PATCH",
      url: `/api/v1/unstract/${sessionDetails?.orgId}/prompt-studio/${details?.tool_id}/`,
      headers: {
        "X-CSRFToken": sessionDetails?.csrfToken,
        "Content-Type": "application/json",
      },
      data: body,
    };

    return axiosPrivate(requestOptions);
  };

  const validateDocChange = () => {
    if (isMultiPassExtractLoading) {
      setAlertDetails({
        type: "error",
        content: "Please wait for the run to complete",
      });
      return false;
    }
    return true;
  };

  const updateDocumentSelection = async (doc, prevSelectedDoc) => {
    const body = { output: doc?.document_id };
    
    try {
      const res = await handleUpdateTool(body);
      const updatedToolData = res?.data;
      updateCustomTool({ details: updatedToolData });
    } catch (err) {
      // Revert on error
      updateCustomTool({ selectedDoc: prevSelectedDoc });
      setAlertDetails(handleException(err, "Failed to select the document"));
    }
  };

  const handleDocChange = (doc) => {
    if (!validateDocChange()) return;

    const prevSelectedDoc = selectedDoc;
    updateCustomTool({ selectedDoc: doc });
    
    if (!isPublicSource) {
      updateDocumentSelection(doc, prevSelectedDoc);
    }
  };

  return (
    <div className="tool-ide-layout">
      <PageTitle title={details?.tool_name} />
      {isPublicSource && HeaderPublic && <HeaderPublic />}
      <div>
        <Header
          handleUpdateTool={handleUpdateTool}
          setOpenSettings={setOpenSettings}
          setOpenShareModal={setOpenShareModal}
          setOpenCloneModal={setOpenCloneModal}
        />
      </div>
      <div
        className={isPublicSource ? "public-tool-ide-body" : "tool-ide-body"}
      >
        <div className="tool-ide-body-2">
          <Row className="tool-ide-main">
            <Col span={12} className="tool-ide-col">
              <div className="tool-ide-prompts">
                <ToolsMain />
              </div>
            </Col>
            <Col span={12} className="tool-ide-col">
              <div className="tool-ide-pdf">
                <DocumentManager
                  generateIndex={generateIndex}
                  handleUpdateTool={handleUpdateTool}
                  handleDocChange={handleDocChange}
                />
              </div>
            </Col>
          </Row>
        </div>
      </div>
      <div className="height-50" />
      <SettingsModal
        open={openSettings}
        setOpen={setOpenSettings}
        handleUpdateTool={handleUpdateTool}
      />
      {PromptShareModal && (
        <PromptShareModal
          open={openShareConfirmation}
          setOpenShareModal={setOpenShareModal}
          setOpenShareConfirmation={setOpenShareConfirmation}
        />
      )}
      {PromptShareLink && (
        <PromptShareLink
          open={openShareLink}
          setOpenShareModal={setOpenShareModal}
          setOpenShareLink={setOpenShareLink}
        />
      )}
      {CloneTitle && (
        <CloneTitle
          open={openCloneModal}
          setOpenCloneModal={setOpenCloneModal}
        />
      )}
      {!promptOnboardingMessage && OnboardMessagesModal && !isPublicSource && (
        <OnboardMessagesModal
          open={loginModalOpen}
          setOpen={setLoginModalOpen}
          slides={slides}
        />
      )}
    </div>
  );
}

export { ToolIde };
